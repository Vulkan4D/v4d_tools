#!/bin/sh
cd `dirname $0`

MODE="$1"
SYSTEM_NAME=${PWD##*/}
PROJECT_DIR='../../../..'
OUTPUT_NAME="$SYSTEM_NAME"

# Build Modes
if [ $MODE == "RELEASE" ] ; then
	OUTPUT_DIR="$PROJECT_DIR/build/release/systems/$SYSTEM_NAME"
	OPTIONS="-O3 -D_RELEASE"
else
	MODE='DEBUG'
	OUTPUT_DIR="$PROJECT_DIR/build/debug/systems/$SYSTEM_NAME"
	OPTIONS="-ggdb -g -O0 -D_DEBUG"
fi
mkdir -p "$OUTPUT_DIR"

GLOBAL_COMPILER_FLAGS="
	-D_V4D_SYSTEM \
	$OPTIONS \
	-fPIC \
	-std=c++17 \
	-m64 \
	-I. \
	-I$PROJECT_DIR/src/v4d/core \
	*.cpp \
"

# https://gcc.gnu.org/onlinedocs/gcc/Preprocessor-Options.html

COMMAND_LINUX="g++ \
	-Wall \
	-shared -Wl,-soname,$OUTPUT_NAME.so \
	-o $OUTPUT_DIR/$OUTPUT_NAME.so \
	-D_LINUX \
	$GLOBAL_COMPILER_FLAGS \
"

COMMAND_WINDOWS="x86_64-w64-mingw32-g++ \
	-Wall \
	-shared -Wl,-soname,$OUTPUT_NAME.dll \
	-o $OUTPUT_DIR/$OUTPUT_NAME.dll \
	-D_WINDOWS \
	-lwinpthread \
	-lstdc++ \
	-lgcc \
	-static -static-libgcc -static-libstdc++ \
	$GLOBAL_COMPILER_FLAGS \
"
#-Wl,-rpath,../.. \
#$OUTPUT_DIR/../../v4d.dll \

# Start Build Process for Linux
OUTPUT=`$COMMAND_LINUX && echo "
SYSTEM $SYSTEM_NAME $MODE BUILD SUCCESSFUL FOR LINUX"`
echo $OUTPUT

# Start Build Process for Windows
OUTPUT=`$COMMAND_WINDOWS && echo "
SYSTEM $SYSTEM_NAME $MODE BUILD SUCCESSFUL FOR WINDOWS"`
echo $OUTPUT

echo ""
