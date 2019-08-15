#!/bin/sh
PROJECT_DIR="`dirname $0`/.."
cd $PROJECT_DIR
set -e

# args
PLATFORM="$1"
MODE="$2"
# Additional Arguments
ARGS="$3"

# Paths (Libraries, includes, ...)
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig/"
export VULKAN_SDK="$PROJECT_DIR/src/vulkan_x86_64"
INCLUDES="\
	-I$PROJECT_DIR/src/v4d/core \
"
LIBS="\
	-lpthread \
"

#vars
ENTRY_FILE='main.cpp'
OUTPUT_NAME='demo'

# Platform options
if [ $PLATFORM == "WINDOWS" ] ; then
	PLATFORM_OPTIONS="
		-D_WINDOWS \
	"
	COMPILER='x86_64-w64-mingw32-g++'
	OUTPUT_EXT='exe'
	V4D_LIB='v4d.dll'
	LIBS="$LIBS\
		-lwinpthread \
		-lstdc++ \
		-lgcc \
		-static -static-libgcc -static-libstdc++ \
		-Ldll \
	"
else
	PLATFORM='LINUX'
	PLATFORM_OPTIONS="
		-D_LINUX \
		-rdynamic \
	"
	COMPILER='g++'
	OUTPUT_EXT='linux'
	V4D_LIB='v4d.so'
	LIBS="$LIBS\
		-ldl \
	"
fi

# Build Modes
if [ $MODE == "RELEASE" ] ; then
	OUTPUT_DIR='build/release'
	OPTIONS="-O3 -D_RELEASE"
else
	OUTPUT_DIR='build/debug'
	OPTIONS="-ggdb -g -O0 -D_DEBUG"
	# -fsanitize=address -fsanitize-address-use-after-scope -fno-omit-frame-pointer
fi
if [ $MODE == "TESTS" ] ; then
	OUTPUT_NAME='tests'
	ENTRY_FILE='tests.cxx'
fi

# Prepare Output Directory
mkdir -p "$OUTPUT_DIR"
if [ -d "res" ] && [ ! -d "$OUTPUT_DIR/res" ] ; then
	ln -s ../../res "$OUTPUT_DIR/res"
fi

# Build V4D lib if does not exist
if [ ! -f "$OUTPUT_DIR/$V4D_LIB" ] ; then
	tools/build_v4d.sh $1 $2 $3
fi

# https://gcc.gnu.org/onlinedocs/gcc/Preprocessor-Options.html
COMMAND="$COMPILER \
	-Wall \
	-o $OUTPUT_DIR/$OUTPUT_NAME.$OUTPUT_EXT \
	$OPTIONS \
	$PLATFORM_OPTIONS \
	$ARGS \
	-std=c++17 \
	-m64 \
	-I. \
	$INCLUDES \
	src/$ENTRY_FILE \
	-Wl,-rpath,. \
	$OUTPUT_DIR/$V4D_LIB \
	$LIBS \
"

# Start Build Process
echo "Started build process $MODE for $PLATFORM"
echo $COMMAND
echo "    .....
"
OUTPUT=`$COMMAND && echo "
$MODE BUILD SUCCESSFUL FOR $PLATFORM"`
echo $OUTPUT
echo ""

# Also compile for Windows if target is ALL platforms
if [ $? == 0 -a $1 == "ALL" ] ; then
	echo "--------------------------------
	"
	tools/build.sh WINDOWS $2 $3
fi

# Exit with code from last command
exit $?
