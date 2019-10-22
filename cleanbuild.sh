#!/bin/sh

# This script will clean and build everything from scratch.
# Use Arguments to crossbuild on additional platforms, located in <project_dir>/crosscompile/*
# Call this script with "windows" argument to cross-compile for the windows platform using the scripts in <project_dir>/crosscompile/windows/

# Prepare bash
cd "`dirname $0`/.."
PROJECT_DIR=`pwd`
set -e

#clear
echo "
Cleaning up previous build...
"
# Delete generated files
rm -rf build/*
for crossplatform in "$@"
do
	"$PROJECT_DIR/crosscompile/$crossplatform/clean.sh"
done

# Go to build directory
cd "$PROJECT_DIR/build"

# rebuild all for all platforms and copy files to remote windows pc
echo "
Rebuilding Everything...
"

# Cross-compile to all other platforms
for crossplatform in "$@"
do
	cmake -DCMAKE_TOOLCHAIN_FILE=crosscompile/$crossplatform/toolchain.cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --parallel 8
	cmake -DCMAKE_TOOLCHAIN_FILE=crosscompile/$crossplatform/toolchain.cmake -DCMAKE_BUILD_TYPE=Debug .. && cmake --build . --parallel 8
	rm CMakeCache.txt
done

# Compile for current platform
cmake .. -DCMAKE_BUILD_TYPE=Release && cmake --build . --parallel 8
cmake .. -DCMAKE_BUILD_TYPE=Debug && cmake --build . --parallel 8

for crossplatform in "$@"
do
	"$PROJECT_DIR/crosscompile/$crossplatform/copy.sh"
done

# Compile successful
echo "
CLEAN BUILD FINISHED
"

# Run tests(Debug) on current platform
echo "Running unit tests DEBUG for Linux..."
cd "$PROJECT_DIR/build/debug" && ./tests

# Run tests(Release) on current platform
echo "Running unit tests RELEASE for Linux..."
cd "$PROJECT_DIR/build/release" && ./tests

# Run tests on all other cross-compiled platforms
for crossplatform in "$@"
do
	"$PROJECT_DIR/crosscompile/$crossplatform/tests.sh"
done

# Build+tests Success !
echo -e "
\033[1;36m
                                                         
                                                         
 _   _       _ _                 _________               
| | | |     | | |               /   |  _  \              
| | | |_   _| | | ____ _ _ __  / /| | | | |              
| | | | | | | | |/ / _, | ,_ \/ /_| | | | |              
\ \_/ / |_| | |   < (_| | | | \___  | |/ /               
 \___/ \__,_|_|_|\_\__,_|_| |_|   |_/___/                
                                                         
                                                         
 _           _ _     _                                   
| |         (_) |   | |                                  
| |__  _   _ _| | __| |  ___ _   _  ___ ___ ___  ___ ___ 
| ,_ \| | | | | |/ _, | / __| | | |/ __/ __/ _ \/ __/ __|
| |_) | |_| | | | (_| | \__ \ |_| | (_| (_|  __/\__ \__ \ 
|_.__/ \__,_|_|_|\__,_| |___/\__,_|\___\___\___||___/___/
                                                         
                                                         
\033[0m
"
