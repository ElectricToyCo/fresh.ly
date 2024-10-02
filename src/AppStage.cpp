//
//  AppStage.cpp
//  freshly
//
//  Created by Jeff Wofford on 12/2/14.
//  Copyright (c) 2014 Jeff Wofford. All rights reserved.
//

#include "AppStage.h"
#include "FantasyConsole.h"
#include "Application.h"
#include "ScreenEffects.h"
#include "lodepng.h"
#include "gif.h"
using namespace fr;

// TODO: Move to central header.
namespace
{
    template< class T >
    void use()
    {
        typename T::ptr t = fr::createObject< T >();
    }

	template< typename IterT >
	void saveGIF( const path& path, IterT begin, IterT end, const vec2ui& dims, TimeType delaySeconds = 0, size_t framePeriod = 0, int nColors = 16 )
	{
		const auto secondsToCentiseconds = []( TimeType seconds )
		{
			return static_cast< int >( std::round( seconds * 100 ));
		};

		const auto delayCSecs = secondsToCentiseconds( delaySeconds );

		jo_gif_t gif = jo_gif_start( path.c_str(), dims.x, dims.y, true, nColors );

		const auto writeFrame = [&]( const std::vector< unsigned char >& frameData )
		{
			jo_gif_frame( &gif, frameData.data(), delayCSecs, false );
		};

		for( size_t i = 0; begin != end; ++begin, ++i )
		{
			if( framePeriod == 0 || ( i % framePeriod ) == 0 )
			{
				writeFrame( *begin );
			}
		}

		jo_gif_end(&gif);
	}
}

namespace fin
{
    void forceInclusion()
    {
        ASSERT( false );    // Don't actually call this.

        // Reference Fresh static library functions and classes that might otherwise be stripped due to apparent non-use.
        use< ScreenEffects >();
        use< FantasyConsole >();
    }

    FRESH_DEFINE_CLASS( AppStage )
	DEFINE_VAR( AppStage, FantasyConsole::ptr, m_game );
	DEFINE_VAR( AppStage, FantasyConsole::ptr, m_editor );
	DEFINE_VAR( AppStage, fr::ScreenEffects::ptr, m_screenEffects );
    DEFINE_VAR( AppStage, DisplayObjectContainer::ptr, m_consoleHost );
	DEFINE_VAR( AppStage, fr::ValueControls::ptr, m_valueControls );
	DEFINE_VAR( AppStage, fr::Sprite::ptr, m_tvOverlay );
	DEFINE_VAR( AppStage, fr::UIPopup::ptr, m_virtualControlsGuide );
	FRESH_IMPLEMENT_STANDARD_CONSTRUCTORS( AppStage )

	void AppStage::onAllLoaded()
	{
		trace( "Fresh.ly AppStage::onAllLoaded()" );

		Super::onAllLoaded();

		if( m_tvOverlay )
		{
			m_tvOverlay->isTouchEnabled( false );
		}

        if( !m_consoleHost )
        {
            m_consoleHost = this;
        }

		// Load the editor "game".
		//
		if( !m_editor )
		{
			try
			{
				const auto editorGamePath = fr::getResourcePath( "assets/games/editor" );

				m_editor = createObject< FantasyConsole >();
				m_editor->loadGame( editorGamePath );
			}
			catch( const std::exception& e )
			{
				release_trace( "Couldn't load editor game." );
			}
		}

		if( m_editor && m_editor->compiled() )
		{
			activate( m_editor );
		}
		else
		{
			m_editor = nullptr;
		}

		if( fr::Application::instance().didStartupWithAlternativeKeyDown() )
		{
			// Don't load the game. Editor startup.
			//
			return;
		}

		// Load the saved game path if it exists.
		//
		std::string gamePath;
		if( loadPreference( "gamePath", gamePath ))
		{
			try
			{
				loadGame( gamePath );
			}
			catch( const std::exception& e )
			{
				release_trace( "Couldn't load game from '" << gamePath << ". Error: " << e.what() );
			}
		}

		// Else, load the autorun game if it exists.
		//
		if( !m_game )
		{
			try
			{
				// Load the auto-run game if available.
				//
				const auto autoRunGamePath = fr::getResourcePath( "assets/games/autorun" );
				loadGame( autoRunGamePath );
			}
			catch( const std::exception& e )
			{
				release_trace( "Couldn't load autorun game: '" << e.what() << "'" );
			}
		}

		if( m_game && m_game->compiled() )
		{
			trace( "Activating game." );

			activate( m_game );
			loadControls();
		}
		else
		{
			m_game = nullptr;
		}
	}

	void AppStage::maybeShowVirtualControlsGuide( bool withHand )
	{
		if( !Application::instance().isMultitouch() ) return;

		if( m_virtualControlsGuide && m_game->supportsVirtualControls() )
		{
			m_virtualControlsGuide->show();

			if( withHand )
			{
				getExpectedDescendant< UIPopup >( *m_virtualControlsGuide, "_handPopup" ).show();
			}

//			scheduleCallback( FRESH_CALLBACK( onReadyToHideVirtualControlsGuide ), 8.0 );
		}
	}

	std::string AppStage::gameSaveKey( const fr::path& gamePath ) const
	{
		return createString( "save_" << gamePath.stem() );
	}

	void AppStage::onAppMayTerminate()
	{
		// Save the path to the existing game.
		//
		if( m_game )
		{
			savePreference( "gamePath", m_game->gamePath().string() );

			const auto memento = m_game->saveMemento();
			savePreference( gameSaveKey( m_game->gamePath() ), memento );
		}
	}

	bool AppStage::onKeyChange( const fr::EventKeyboard& event, bool down )
	{
		const auto handleCommandKey = [&]( std::function<void()>&& fn )
		{
			if( event.isCtrlCommandDown() )
			{
				if( down )
				{
					fn();
				}
				return false;
			}
			else
			{
				return true;
			}
		};

		switch( event.key() )
		{
			case Keyboard::Key::R:
				return handleCommandKey( [&]() { m_pendingReload = true; } );

			case Keyboard::Key::T:
				if( m_activeConsole == m_game )
				{
					return handleCommandKey( [&]() { m_pendingTakeScreenshot = true; } );
				}
				else
				{
					return true;
				}

			case Keyboard::Key::G:
				if( m_activeConsole == m_game )
				{
					return handleCommandKey( [&]() { m_pendingSaveGIF = true; } );
				}
				else
				{
					return true;
				}

			case Keyboard::Key::Escape:
				if( down )
				{
					// Toggle editor.
					//
					m_pendingActivate = m_activeConsole == m_game ? m_editor : m_game;
				}
				return false;

			default:
				return true;
		}
	}

	void AppStage::onKeyDown( const fr::EventKeyboard& event )
	{
		if( onKeyChange( event, true ))
		{
			Super::onKeyDown( event );
		}
	}

	void AppStage::onKeyUp( const fr::EventKeyboard& event )
	{
		if( onKeyChange( event, false ))
		{
			Super::onKeyUp( event );
		}
	}

	void AppStage::update()
	{
#if !GL_ES_VERSION_2_0
		// Accumulate a record of screen pixels.
		if( m_activeConsole == m_game && m_game->texture() )
		{
			auto texels = m_game->texture()->readTexels();
			const auto dims = m_game->texture()->dimensions();

			if( texels.empty() == false && dims.x > 0 && dims.y > 0 )
			{
				if( m_screenshotsDims != dims )
				{
					// Change of screenshot size. Throw away all past ones.
					m_screenshotsDims = dims;
					m_pastScreenshots.clear();
				}
				m_pastScreenshots.emplace_back( std::move( texels ));
				const size_t excessFrames = m_pastScreenshots.size() - m_maxGIFFrames;

				if( excessFrames < m_maxGIFFrames )
				{
					m_pastScreenshots.erase( m_pastScreenshots.begin(), m_pastScreenshots.begin() + excessFrames );
				}
			}
		}
#endif // !GL_ES_VERSION_2_0

		if( m_pendingTakeScreenshot	 )
		{
			m_pendingTakeScreenshot = false;
			if( m_pastScreenshots.empty() == false && m_screenshotsDims.x > 0 && m_screenshotsDims.y > 0 )
			{
				const auto fileName = createString( "Freshly Shot " << getStandardTimeDisplay( std::time( NULL )) << ".png" );
				const auto directory = getDocumentPath( "shots" );
				create_directories( directory );

				const auto path = directory / fileName;
				lodepng::encode( path.string(), m_pastScreenshots.back(), m_screenshotsDims.x, m_screenshotsDims.y );

				m_editor->console( createString( "Screen shot taken: " << path ));
			}
		}

		if( m_pendingSaveGIF )
		{
			m_pendingSaveGIF = false;
			if( m_pastScreenshots.empty() == false && m_screenshotsDims.x > 0 && m_screenshotsDims.y > 0 )
			{
				const auto fileName = createString( "Freshly GIF " << getStandardTimeDisplay( std::time( NULL )) << ".gif" );
				const auto directory = getDocumentPath( "shots" );
				create_directories( directory );

				const auto path = directory / fileName;
				const size_t framePeriod = 4;
				saveGIF( path, m_pastScreenshots.begin(), m_pastScreenshots.end(), m_screenshotsDims, framePeriod / 60.0, framePeriod );

				m_editor->console( createString( "GIF saved: " << path ));
			}
		}

        if( m_pendingReload )
        {
            m_pendingReload = false;
            reloadGame();
        }

        if( m_pendingActivate )
		{
			activate( m_pendingActivate );
			m_pendingActivate = nullptr;
		}

		if( m_valueControls )
		{
			m_valueControls->console( m_game );
		}

		if( m_activeConsole && m_tvOverlay && m_tvOverlay->texture() )
		{
			// For some reason I have to flip this in Y.
			m_tvOverlay->scale( vec2( 1.0f, -1.0f ) * vector_cast< real >( m_activeConsole->screenDims() ) / vector_cast< real >( m_tvOverlay->texture()->getOriginalDimensions() ));
		}

		if( auto fpsDisplay = getDescendantByName<TextField>( "fpsDisplay" ))
		{
			const TimeType deltaTimeSeconds = stage().lastFrameDurationReal();
			if( deltaTimeSeconds > 0.0 )
			{
				const TimeType fps = 1.0 / deltaTimeSeconds;

				m_smoothedFPS = lerp( m_smoothedFPS, fps, 0.25 );

				fpsDisplay->text( createString( std::fixed << std::setfill( ' ' ) << std::setprecision( 0 ) << std::setw( 6 ) << m_smoothedFPS ));
			}
			else
			{
				fpsDisplay->text( "" );
			}
		}

		if( m_virtualControlsGuide )
		{
			if( !Application::instance().isMultitouch() )
			{
				m_virtualControlsGuide->visible( false );
			}
			else
			{
				m_virtualControlsGuide->isTouchEnabled( false );

				const auto guideSize = getExpectedDescendant<fr::Sprite>( *m_virtualControlsGuide, "_frame" ).texture()->dimensions();
				if( guideSize.x > 0 && guideSize.y > 0 )
				{
					m_virtualControlsGuide->scale( stageDimensions() / vector_cast< real >( guideSize ));
				}
			}
		}

		Super::update();
	}

	void AppStage::render( TimeType relativeFrameTime, RenderInjector* injector )
	{
		Super::render( relativeFrameTime, injector );
	}

	void AppStage::loadGame( const fr::path& gamePath )
	{
		const auto game = createObject< FantasyConsole >();
		game->addEventListener( fr::FantasyConsole::MESSAGE, FRESH_CALLBACK( onGameConsoleMessage ));

		game->loadGame( gamePath );

		if( game->compiled() )
		{
			restoreSavedGame( *game );

			loadControls();

			m_game = game;
			m_pendingActivate = m_game;
		}
		else
		{
			m_editor->console( createString( "Unable to compile game at '" << gamePath << "'." ));
		}
	}

	void AppStage::reloadGame( bool reset )
	{
		if( m_game )
		{
			m_game->reload();

			if( m_game->compiled() )
			{
				if( !reset )
				{
					restoreSavedGame( *m_game );
				}

				activate( m_game );
			}
		}
		else
		{
			m_editor->console( "No game loaded. Use `load <game path>`." );
		}
	}

	void AppStage::restoreSavedGame( fr::FantasyConsole& console )
	{
		ASSERT( console.compiled() );

		std::string memento;
		if( loadPreference( gameSaveKey( console.gamePath() ), memento ))
		{
			console.loadMemento( memento );
		}
	}

	void AppStage::activate( fr::FantasyConsole::ptr console )
	{
		m_pendingTakeScreenshot = false;
		m_pendingSaveGIF = false;

		// Deactivate the prior active console.
		//
		if( m_activeConsole )
		{
			if( console == m_activeConsole )
			{
				return;
			}

			if( console == m_editor )
			{
				m_editor->removeEventListener( fr::FantasyConsole::COMMAND, FRESH_CALLBACK( onEditorCommand ));
			}
			else
			{
				console->removeEventListener( fr::FantasyConsole::VIRTUAL_CONTROLS_SHOW, FRESH_CALLBACK( onVirtualControlsShow ));
				console->removeEventListener( fr::FantasyConsole::VIRTUAL_CONTROLS_HIDE, FRESH_CALLBACK( onVirtualControlsHide ));
				console->removeEventListener( fr::FantasyConsole::VIRTUAL_TRACKBALL_USED, FRESH_CALLBACK( onVirtualTrackballUsed ));
			}

			if( m_virtualControlsGuide )
			{
				m_virtualControlsGuide->visible( console == m_game );
			}

			if( m_consoleHost->hasChild( m_activeConsole ))
			{
				m_consoleHost->removeChild( m_activeConsole );
			}

			m_activeConsole->activated( false );

			m_activeConsole = nullptr;
		}

		if( console )
		{
			release_trace("Adding console to host.");
			m_consoleHost->addChild( console );

			if( console == m_editor )
			{
				m_editor->addEventListener( fr::FantasyConsole::COMMAND, FRESH_CALLBACK( onEditorCommand ));
			}
			else
			{
				console->addEventListener( fr::FantasyConsole::VIRTUAL_CONTROLS_SHOW, FRESH_CALLBACK( onVirtualControlsShow ));
				console->addEventListener( fr::FantasyConsole::VIRTUAL_CONTROLS_HIDE, FRESH_CALLBACK( onVirtualControlsHide ));
				console->addEventListener( fr::FantasyConsole::VIRTUAL_TRACKBALL_USED, FRESH_CALLBACK( onVirtualTrackballUsed ));

				maybeShowVirtualControlsGuide( true );
			}

			console->activated( true );
		}

		m_activeConsole = console;

		if( m_valueControls )
		{
			m_valueControls->active( m_activeConsole == m_game );
		}
	}

	fr::path AppStage::gameControlSavePath() const
	{
		return getDocumentPath( change_extension( m_game->gamePath(), "txt" ));
	}

	void AppStage::loadControls()
	{
		if( m_game && m_valueControls )
		{
			m_valueControls->clear();

			const auto controlsPath = gameControlSavePath();

			if( exists( controlsPath ))
			{
				const std::string state = getFileText( controlsPath );

				m_valueControls->restoreState( state );
			}
		}
	}

	void AppStage::saveControls() const
	{
		if( m_game && m_valueControls)
		{
			const auto state = m_valueControls->saveState();

			std::ofstream out( gameControlSavePath().c_str() );
			out << state;
		}
	}

	FRESH_DEFINE_CALLBACK( AppStage, onEditorCommand, fr::FantasyConsole::ConsoleEvent )
	{
		const auto parseInt = []( const std::string& s, int defaultValue = 0 ) {
			int n = defaultValue;
			std::istringstream str( s );
			str >> n;
			return n;
		};

		const std::unordered_map< std::string, std::function< void( const std::vector< std::string >& arguments ) >> commands =
		{
			{ "reset", [&]( const std::vector< std::string >& arguments )
				{
					reloadGame( true );
				}
			},
			{ "reload", [&]( const std::vector< std::string >& arguments )
				{
					reloadGame();
				}
			},
			{ "savestate", [&]( const std::vector< std::string >& arguments )
				{
					const auto memento = m_game->saveMemento();
					savePreference( gameSaveKey( m_game->gamePath() ), memento );
				}
			},
			{ "loadstate", [&]( const std::vector< std::string >& arguments )
				{
					if( m_game )
					{
						restoreSavedGame( *m_game );
					}
				}
			},
			{ "fps", [&]( const std::vector< std::string >& arguments )
				{
					if( auto fpsDisplay = getDescendantByName<TextField>( "fpsDisplay" ))
					{
						fpsDisplay->visible( !fpsDisplay->visible() );
					}
				}
			},
            { "ls", [&]( const std::vector< std::string >& arguments )
                {
                    if( arguments.size() > 2 )
                    {
                        m_editor->console( "Usage: `ls [pattern]`" );
                        return;
                    }

                    const auto& currentPath = m_editor->gamesBasePath();
                    each_child_file( currentPath, [&]( const std::string& filename, bool regularFile )
                                    {
                                        if( filename.size() > 0 && filename[ 0 ] != '.' )
                                        {
                                            m_editor->console( createString( " " << filename << ( regularFile ? "" : "/" ) ));
                                        }
                                    });
                }
            },
			{ "load", [&]( const std::vector< std::string >& arguments )
				{
					if( arguments.size() != 2 )
					{
						m_editor->console( "Usage: `load <game path>`" );
						return;
					}

					const auto& gamePath = arguments[ 1 ];

					try
					{
						loadGame( gamePath );
					}
					catch( const std::exception& e )
					{
						m_editor->console( createString( "Loading " << gamePath << "failed:" ));
						m_editor->console( e.what() );
					}
				}
			},
			{ "run", [&]( const std::vector< std::string >& arguments )
				{
					if( m_game )
					{
						m_pendingActivate = m_game;
					}
					else
					{
						m_editor->console( "No game loaded. Use `load <game path>`." );
						return;
					}
				}
			},
			{ "folder", [&]( const std::vector< std::string >& arguments )
				{
					m_editor->exploreFolder();
				}
			},
			{ "quit", [&]( const std::vector< std::string >& arguments )
				{
					Application::instance().quit( 0 );
				}
			},
            { "inspect", [&]( const std::vector< std::string >& arguments )
                {
					if( m_valueControls )
					{
						const auto parseReal = []( const std::string& s, real defaultValue = 0 ) {
							real n = defaultValue;
							std::istringstream str( s );
							str >> n;
							return n;
						};

						const auto parseType = []( const std::string& s ) {
							if( s == "bool" )
							{
								return ValueControlOptions::Type::Bool;
							}
							else if( s == "real" )
							{
								return ValueControlOptions::Type::Real;
							}
							else
							{
								return ValueControlOptions::Type::Detect;
							}
						};

						if( arguments.size() < 2 )
						{
							m_editor->console( "Usage: `inspect <variable-path> [min] [max] [<type='bool'|'real'>]`" );
							return;
						}

						ValueControlOptions options;

						size_t arg = 1;
						options.variablePath = arguments[ arg++ ];
						options.min = arguments.size() > arg ? parseReal( arguments[ arg++ ], 0 ) : 0;

						const auto defaultMax = options.min != 0 ? options.min + 1.0f : 0.0f;
						options.max = arguments.size() > arg ? parseReal( arguments[ arg++ ], defaultMax ) : defaultMax;

						options.type = arguments.size() > arg ? parseType( arguments[ arg++ ] ) : ValueControlOptions::Type::Detect;

						m_valueControls->add( options, m_game );

						saveControls();
					}
                }
            },
			{ "nab", [&]( const std::vector< std::string >& arguments )
				{
					if( m_valueControls )
					{
						if( arguments.size() < 1 )
						{
							m_editor->console( "Usage: `nab`" );
							return;
						}

						copyToPasteboard( m_valueControls->valuesString() );

						m_editor->console( "Copied to clipboard." );
					}
				}
			},
            { "resetvar", [&]( const std::vector< std::string >& arguments )
				{
					if( m_valueControls )
					{
						if( arguments.size() < 2 )
						{
							m_editor->console( "Usage: `inspect <variable-path>|#<index>`" );
							return;
						}

						// Number?
						if( arguments[ 1 ].empty() == false && arguments[ 1 ][ 0 ] == '#' )
						{
							const std::string numericPart( arguments[ 1 ].begin() + 1, arguments[ 1 ].end() );
							const int index = parseInt( numericPart, -1 );
							m_valueControls->reset( index - 1 );
						}
						else
						{
							m_valueControls->reset( arguments[ 1 ] );
						}

						saveControls();
					}
				}
			},
			{ "forget", [&]( const std::vector< std::string >& arguments )
				 {
					if( m_valueControls )
					{
						if( arguments.size() < 1 )
						{
							m_editor->console( "Usage: `forget <variable-path>|#<index=last>`" );
							return;
						}

						// Number?
						if( arguments.size() == 1 )
						{
							m_valueControls->removeLast();
						}
						else if( arguments[ 1 ].empty() == false && arguments[ 1 ][ 0 ] == '#' )
						{
							const std::string numericPart( arguments[ 1 ].begin() + 1, arguments[ 1 ].end() );
							const int index = parseInt( numericPart, -1 );
							m_valueControls->remove( index - 1 );
						}
						else
						{
							m_valueControls->remove( arguments[ 1 ] );
						}

						saveControls();
					}
				 }
			},
			{ "forgetall", [&]( const std::vector< std::string >& arguments )
				 {
					if( m_valueControls )
					{
						if( arguments.size() < 1 )
						{
							m_editor->console( "Usage: `forgetall`" );
							return;
						}

						m_valueControls->clear();

						saveControls();
					}
				 }
			},
            { "call", [&]( const std::vector< std::string >& arguments )
                {
                    if( arguments.size() < 1 )
                    {
                        m_editor->console( "Usage: `call <method>`" );
                        return;
                    }

                    const auto& methodName = arguments.front();
                    m_editor->callScriptFunction( methodName );
                }
            },
		};

		const auto arguments = fr::split( event.message(), " \t" );
		if( arguments.empty() )
		{
			m_editor->console( "Could not parse command." );
			return;
		}

		if( arguments.front() == "help" )
		{
			m_editor->console( "Available commands:" );
			for( const auto& commandInfo : commands )
			{
				m_editor->console( createString( "  " << commandInfo.first ));
			}
		}
		else
		{
			const auto iter = commands.find( arguments.front() );
			if( iter != commands.end() )
			{
				iter->second( arguments );
			}
			else
			{
				m_editor->console( createString( "Unrecognized command `" << arguments.front() << "`. Try `help`." ));
				return;
			}
		}
	}

	FRESH_DEFINE_CALLBACK( AppStage, onGameConsoleMessage, fr::FantasyConsole::ConsoleEvent )
	{
		if( m_editor )
		{
			m_editor->console( event.message() );
		}
	}

	FRESH_DEFINE_CALLBACK( AppStage, onVirtualControlsShow, fr::Event )
	{
		maybeShowVirtualControlsGuide( false );
	}

	FRESH_DEFINE_CALLBACK( AppStage, onVirtualControlsHide, fr::Event )
	{
		onReadyToHideVirtualControlsGuide( event );
	}

	FRESH_DEFINE_CALLBACK( AppStage, onVirtualTrackballUsed, fr::Event )
	{
		if( m_virtualControlsGuide )
		{
			getExpectedDescendant< UIPopup >( *m_virtualControlsGuide, "_handPopup" ).hide();
		}
	}


	FRESH_DEFINE_CALLBACK( AppStage, onReadyToHideVirtualControlsGuide, Event )
	{
		if( m_virtualControlsGuide )
		{
			m_virtualControlsGuide->hide();
		}
	}
}

