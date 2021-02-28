//
//  AppStage.h
//  freshly
//
//  Created by Jeff Wofford on 12/2/14.
//  Copyright (c) 2014 Jeff Wofford. All rights reserved.
//

#ifndef freshly_AppStage_h
#define freshly_AppStage_h

#include "Essentials.h"
#include "Stage.h"
#include "EventKeyboard.h"
#include "FantasyConsole.h"
#include "ValueControls.h"
#include "UIPopup.h"
#include <deque>

namespace fin
{
	class AppStage : public fr::Stage
	{
		FRESH_DECLARE_CLASS( AppStage, Stage );
	public:
		
		virtual void onAllLoaded() override;
		virtual void onKeyDown( const fr::EventKeyboard& event ) override;
		virtual void onKeyUp( const fr::EventKeyboard& event ) override;

		virtual void update() override;
		virtual void render( TimeType relativeFrameTime, RenderInjector* injector ) override;

		virtual void onAppMayTerminate() override;

	protected:

		virtual bool onKeyChange( const fr::EventKeyboard& event, bool down );	// TODO return true if to be handled normally.

		void loadGame( const fr::path& gamePath );
		void reloadGame( bool reset = false );
		void restoreSavedGame( fr::FantasyConsole& console );

		void activate( fr::FantasyConsole::ptr console );
		
		void saveControls() const;
		void loadControls();
		
		void maybeShowVirtualControlsGuide( bool withHand = false );
		
		std::string gameSaveKey( const fr::path& gamePath ) const;

	private:
		
		VAR( fr::FantasyConsole::ptr, m_game );
		VAR( fr::FantasyConsole::ptr, m_editor );
		VAR( fr::ScreenEffects::ptr, m_screenEffects );
        VAR( fr::DisplayObjectContainer::ptr, m_consoleHost );
		VAR( fr::ValueControls::ptr, m_valueControls );
		VAR( fr::Sprite::ptr, m_tvOverlay );
		VAR( fr::UIPopup::ptr, m_virtualControlsGuide );

		fr::FantasyConsole::ptr m_pendingActivate;
        bool m_pendingReload = false;
		
		fr::FantasyConsole::ptr m_activeConsole;
		
		fr::path gameControlSavePath() const;
		
		TimeType m_smoothedFPS = 0;
		
		bool m_pendingTakeScreenshot = false;
		bool m_pendingSaveGIF = false;
		
		size_t m_maxGIFFrames = 60 * 12;
		vec2ui m_screenshotsDims;
		std::deque< std::vector< unsigned char >> m_pastScreenshots;

		FRESH_DECLARE_CALLBACK( AppStage, onEditorCommand, fr::FantasyConsole::ConsoleEvent );
		FRESH_DECLARE_CALLBACK( AppStage, onGameConsoleMessage, fr::FantasyConsole::ConsoleEvent );
		FRESH_DECLARE_CALLBACK( AppStage, onVirtualControlsShow, fr::Event );
		FRESH_DECLARE_CALLBACK( AppStage, onVirtualControlsHide, fr::Event );
		FRESH_DECLARE_CALLBACK( AppStage, onVirtualTrackballUsed, fr::Event );
		FRESH_DECLARE_CALLBACK( AppStage, onReadyToHideVirtualControlsGuide, fr::Event );
	};
}

#endif
