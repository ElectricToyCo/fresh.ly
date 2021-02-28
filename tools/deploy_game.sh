#!/bin/bash

usage()
{
    echo "usage: deploy_game <game> [-f|-e|-c|-s]"
}

# Make sure we have an argument.
if [ $# -lt 1 ]; then 
    echo "First argument should be the name of the Freshly game, as found in the Documents directory."
    exit 1
fi

gamename=$1
shift

freshly=1
emscripten=1
clean=0
site=1

while [ "$1" != "" ]; do
    case $1 in
        -f | --no-freshly )     freshly=0
                                ;;
        -e | --no-emscripten )  emscripten=0
                                ;;
        -c | --clean )          clean=1
                                ;;
        -s | --no-site )        site=0
                                ;;
        -h | --help )           usage
                                exit
    esac
    shift
done


if [ "$freshly" = "1" ]; then
    freshlygames="$HOME/Documents/The Electric Toy Co/freshly/games"
    src="$freshlygames/$gamename"

    # Make sure we see the game files
    if [ ! -d "$src" ]; then
        echo "No path '$src'."
        exit 2
    fi

    # Copy the files to freshly's autorun location.
    autorun="../assets/games/autorun"
    if [ ! -d "$autorun" ]; then
        echo "Can't find Freshly's autorun game asset path '$autorun'."
        exit 3
    fi

    mkdir -p "$autorun/audio" && cp -R "$src/audio/" "$autorun/audio/"
    cp "$src/main.lua" "$autorun"
    cp "$src/sprites.png" "$autorun"
    cp "$src/map.tmx" "$autorun"
    echo "Game copied to Freshly's autorun assets." 
    echo "You can now embed the game directly into Mac and iOS versions in Xcode."
fi

if [ "$emscripten" = "1" ]; then
    echo "Building Emscripten version for the web."
    
    # Rebuild the Emscripten build.
    pushd ../Platforms/Emscripten

    # Clean?
    if [ "$clean" = "1" ]; then
        rm -rf build/
    fi

    /bin/bash ./setup_emscripten.sh
    echo "Built Emscripten version."

    popd
fi

if [ "$site" = "1" ]; then
    pushd ../Platforms/Emscripten

    echo "Copying web version to the electrictoy.co site (local)."

    sitegames="$HOME/Sites/www.jeffwofford.com/electrictoy.co/games/"

    cd build
    cp "$gamename.js" "$sitegames"
    cp "$gamename.wasm" "$sitegames"
    cp "$gamename.data" "$sitegames"

    echo "Copied. Commit to git and use ./megapush.sh to upload."
    cd "$sitegames"

    # git commit -am "Updated Freshly."
    # /bin/bash ./megapush.sh
fi
