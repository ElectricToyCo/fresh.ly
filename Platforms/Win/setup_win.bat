@echo off

REM Add MinGW path.
path=C:\MinGW\bin;%path%

if not exist Release (
    mkdir Release
    cd Release
    cmake ../../.. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
    cd ..
)
if not exist Debug (
    mkdir Debug
    cd Debug
    cmake ../../.. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Debug
    cd ..
)

REM if not exist build-VS10 mkdir build-VS10
REM cd ..\build-VS10
REM cmake ..\..\.. -G "Visual Studio 10"

cd Release
mingw32-make -j2 install
