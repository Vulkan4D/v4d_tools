#!/bin/sh
PROJECT_DIR="`dirname $0`/.."
cd $PROJECT_DIR

# Delete generated files for linux build
rm -rf src/v4d/core/common/*.gch
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
clear
tools/build.sh ALL RELEASE &&\
tools/build.sh ALL DEBUG &&\
tools/build.sh ALL TESTS &&\
tools/build.sh ALL TESTS_RELEASE &&\
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
echo -e "
\033[1;36m
	***** SUCCESS *****
\033[0m
"
