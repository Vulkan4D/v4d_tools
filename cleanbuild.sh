#!/bin/sh

# This script will clean and build everything from scratch.
# Use Arguments to crossbuild on additional platforms, located in <project_dir>/crosscompile/*
# Call this script with "windows" argument to cross-compile for the windows platform using the scripts in <project_dir>/crosscompile/windows/

# Prepare bash
cd "`dirname $0`/.."
PROJECT_DIR=`pwd`
set -e

# Detect Current Platform
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)
		PLATFORM=Linux
		EXECUTABLE_SUFFIX=""
	;;
    Darwin*)
		PLATFORM=Mac;
		EXECUTABLE_SUFFIX=""
	;;
    CYGWIN*)
		PLATFORM=Windows;
		EXECUTABLE_SUFFIX=".exe"
	;;
    MINGW*)
		PLATFORM=Windows;
		EXECUTABLE_SUFFIX=".exe"
	;;
    *)
		PLATFORM=Unknown
		EXECUTABLE_SUFFIX=""
esac
echo "Detected current platform $PLATFORM"

# Prepare OpenSSL
if [ ! -f "src/openssl/include/openssl/opensslconf.h" ] ; then
	if [ "$PLATFORM" = "Windows" ] ; then
		cp dll/opensslconf.h src/openssl/include/openssl/
	else
		cd src/openssl && ./config
	fi
fi

# make sure the build directory exists
cd "$PROJECT_DIR"
mkdir -p build || exit 1

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
	rm -f CMakeCache.txt ; "../crosscompile/$crossplatform/build.sh" Release || exit 1
	rm -f CMakeCache.txt ; "../crosscompile/$crossplatform/build.sh" Debug || exit 1
done

# Compile for current platform
rm -f CMakeCache.txt
cmake .. -DCMAKE_BUILD_TYPE=Release && cmake --build . --parallel 8 || exit 1
cmake .. -DCMAKE_BUILD_TYPE=Debug && cmake --build . --parallel 8 || exit 1

for crossplatform in "$@"
do
	"$PROJECT_DIR/crosscompile/$crossplatform/copy.sh" release || exit 1
	"$PROJECT_DIR/crosscompile/$crossplatform/copy.sh" debug || exit 1
done

# Compile successful
echo "
CLEAN BUILD FINISHED
"

# Run tests(Debug) on current platform
echo "Running unit tests DEBUG for $PLATFORM..."
cd "$PROJECT_DIR/build/debug" && ./tests$EXECUTABLE_SUFFIX || exit 1

# Run tests(Release) on current platform
echo "Running unit tests RELEASE for $PLATFORM..."
cd "$PROJECT_DIR/build/release" && ./tests$EXECUTABLE_SUFFIX || exit 1

# Run tests on all other cross-compiled platforms
for crossplatform in "$@"
do
	"$PROJECT_DIR/crosscompile/$crossplatform/tests.sh" || exit 1
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
