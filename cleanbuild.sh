#!/bin/sh
PROJECT_DIR="`dirname $0`/.."
cd $PROJECT_DIR

#clear
echo "
Erasing old stuff...
"

# Delete generated files
rm -rf build/*

# Kill potentially running process on remote windows pc
ssh WINDOWS_PC "START /wait taskkill /f /im tests.exe"
ssh WINDOWS_PC "START /wait taskkill /f /im demo.exe"

# Delete build on remote windows pc
ssh WINDOWS_PC "rmdir /q /s \v4d_build\debug > NUL"
ssh WINDOWS_PC "rmdir /q /s \v4d_build\release > NUL"
ssh WINDOWS_PC "mkdir \v4d_build\debug"
ssh WINDOWS_PC "mkdir \v4d_build\release"

# Copy global DLLs to Remote Windows PC
scp -rq dll/* WINDOWS_PC:/v4d_build/debug/
scp -rq dll/* WINDOWS_PC:/v4d_build/release/

# rebuild all for all platforms and copy files to remote windows pc
echo "
Rebuilding Everything...
"
cd build
x86_64-w64-mingw32-cmake -DCMAKE_BUILD_TYPE=Debug .. && cmake --build . --parallel 8 &&\
x86_64-w64-mingw32-cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --parallel 8 &&\
# cmake -DCMAKE_TOOLCHAIN_FILE=tools/crosscompile_windows_toolchain.cmake -DCMAKE_BUILD_TYPE=Debug .. && cmake --build . --parallel 8 &&\
# cmake -DCMAKE_TOOLCHAIN_FILE=tools/crosscompile_windows_toolchain.cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --parallel 8 &&\
rm CMakeCache.txt &&\
cmake .. -DCMAKE_BUILD_TYPE=Release && cmake --build . --parallel 8 &&\
cmake .. -DCMAKE_BUILD_TYPE=Debug && cmake --build . --parallel 8 &&\
scp -rq debug/* WINDOWS_PC:/v4d_build/debug/ &&\
scp -rq release/* WINDOWS_PC:/v4d_build/release/ &&\
echo "
CLEAN BUILD FINISHED
" &&\
echo "Running unit tests DEBUG for Linux..." &&\
cd debug && ./tests &&\
echo "Running unit tests RELEASE for Linux..." &&\
cd ../release && ./tests &&\
echo "Running unit tests DEBUG for Windows..." &&\
ssh WINDOWS_PC "cd /v4d_build/debug/ && tests.exe" &&\
echo "Running unit tests RELEASE for Windows..." &&\
ssh WINDOWS_PC "cd /v4d_build/release/ && tests.exe" &&\
../../tools/successText.sh
