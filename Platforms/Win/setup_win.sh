#!/bin/bash

# setup_win.sh
# On Mac, use brew install mingw-w64. Then run this from a Fresh app's ./Platforms/Win directory.

mkdir Release
cd Release
cmake ../../.. -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-c++ -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_VERSION=7

make -j4 install