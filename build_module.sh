#!/bin/sh
cd `dirname $0`

MODE="$1"
MODULE_NAME=${PWD##*/}
PROJECT_DIR='../../../..'
OUTPUT_NAME="$MODULE_NAME"

# Build Modes
if [ $MODE == "RELEASE" ] ; then
	OUTPUT_DIR="$PROJECT_DIR/build/release/modules/$MODULE_NAME"
	OPTIONS="-O3 -D_RELEASE"
else
	MODE='DEBUG'
	OUTPUT_DIR="$PROJECT_DIR/build/debug/modules/$MODULE_NAME"
	OPTIONS="-ggdb -g -O0 -D_DEBUG"
fi
mkdir -p "$OUTPUT_DIR"

source "$PROJECT_DIR/tools/globalCompilerConfig.sh"

GLOBAL_COMPILER_FLAGS="
	$OPTIONS \
	-fPIC \
	$GCC_COMMON_OPTIONS \
	-I. \
	$INCLUDES \
	*.cpp \
"

# https://gcc.gnu.org/onlinedocs/gcc/Preprocessor-Options.html

COMMAND_LINUX="g++ \
	$GCC_FLAGS \
	-shared -Wl,-soname,$OUTPUT_NAME.so \
	-o $OUTPUT_DIR/$OUTPUT_NAME.so \
	-D_LINUX \
	$GLOBAL_COMPILER_FLAGS \
	-Wl,-rpath,../.. \
	$OUTPUT_DIR/../../v4d.so \
"

COMMAND_WINDOWS="x86_64-w64-mingw32-g++ -D_WIN32_WINNT=0x06030000 \
	$GCC_FLAGS \
	-shared -Wl,-soname,$OUTPUT_NAME.dll \
	-o $OUTPUT_DIR/$OUTPUT_NAME.dll \
	-D_WINDOWS \
	-lwinpthread \
	-lstdc++ \
	-lgcc \
	$GLOBAL_COMPILER_FLAGS \
	-Wl,-rpath,../.. \
	$OUTPUT_DIR/../../v4d.dll \
"
#-static -static-libgcc -static-libstdc++ \

# Start Build Process for Linux
OUTPUT=`$COMMAND_LINUX && echo "
MODULE $MODULE_NAME $MODE BUILD SUCCESSFUL FOR LINUX"`
echo $OUTPUT

# Start Build Process for Windows
OUTPUT=`$COMMAND_WINDOWS && echo "
MODULE $MODULE_NAME $MODE BUILD SUCCESSFUL FOR WINDOWS"`
echo $OUTPUT

echo ""
