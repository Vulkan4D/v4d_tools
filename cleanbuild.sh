#!/bin/sh
PROJECT_DIR="`dirname $0`/.."
cd $PROJECT_DIR

# Delete generated files for linux build
rm -rf src/v4d/core/common_linux.hh.gch
rm -rf src/v4d/core/common_windows.hh.gch
rm -rf build/release/*
rm -rf build/debug/*

# Delete build on remote windows pc
ssh WINDOWS_PC "rmdir /q /s \v4d_build\debug > NUL"
ssh WINDOWS_PC "rmdir /q /s \v4d_build\release > NUL"
ssh WINDOWS_PC "mkdir \v4d_build\debug"
ssh WINDOWS_PC "mkdir \v4d_build\release"

# rebuild all for all platforms
clear
tools/build.sh ALL RELEASE
tools/build.sh ALL DEBUG

# build all systems
find src/v4d/systems/ -type f -name 'build.sh' -exec sh '{}' DEBUG \;
find src/v4d/systems/ -type f -name 'build.sh' -exec sh '{}' RELEASE \;

# send all files to remote windows pc
scp -rq build/debug/* WINDOWS_PC:/v4d_build/debug/
scp -rq build/release/* WINDOWS_PC:/v4d_build/release/

echo "
CLEAN BUILD FINISHED
"
