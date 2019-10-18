#!/bin/sh
PROJECT_DIR="`dirname $0`/.."
cd $PROJECT_DIR

clear
echo "
Erasing old stuff...
"

# Delete generated files for linux build
rm -rf build/gch/*
rm -rf build/release/*
rm -rf build/debug/*

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
tools/build.sh LINUX RELEASE &&\
tools/build.sh LINUX DEBUG &&\
tools/build.sh LINUX TESTS &&\
tools/build.sh LINUX TESTS_RELEASE &&\
tools/build.sh WINDOWS RELEASE &&\
tools/build.sh WINDOWS DEBUG &&\
tools/build.sh WINDOWS TESTS &&\
tools/build.sh WINDOWS TESTS_RELEASE &&\
tools/build_modules.sh RELEASE &&\
tools/build_modules.sh DEBUG &&\
scp -rq build/debug/* WINDOWS_PC:/v4d_build/debug/ &&\
scp -rq build/release/* WINDOWS_PC:/v4d_build/release/ &&\
echo "
CLEAN BUILD FINISHED
" &&\
echo "Running unit tests DEBUG for Linux..." &&\
cd build/debug && ./tests.linux &&\
echo "Running unit tests RELEASE for Linux..." &&\
cd ../release && ./tests.linux &&\
echo "Running unit tests DEBUG for Windows..." &&\
ssh WINDOWS_PC "cd /v4d_build/debug/ && tests.exe" &&\
echo "Running unit tests RELEASE for Windows..." &&\
ssh WINDOWS_PC "cd /v4d_build/release/ && tests.exe" &&\
cd ../../ &&\
tools/successText.sh

