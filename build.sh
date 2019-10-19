#!/bin/sh
PROJECT_DIR="`dirname $0`/.."
cd $PROJECT_DIR
set -e

# args
PLATFORM="$1"
MODE="$2"
# Additional Arguments
ARGS="$3"

TYPE='PROJECT'

if [ "$PLATFORM" = "ALL" ] ; then
	PLATFORM='LINUX'
fi

#vars
ENTRY_FILE='main.cpp'
OUTPUT_NAME='demo'
source "$PROJECT_DIR/tools/globalCompilerConfig.sh"

# Platform options
if [ "$PLATFORM" = "WINDOWS" ] ; then
	PLATFORM_OPTIONS="
		-D_WINDOWS \
	"
	OUTPUT_EXT='exe'
	V4D_LIB='v4d.dll'
	LIBS="$LIBS\
		-lwinpthread \
		-lstdc++ \
		-lgcc \
		-lws2_32 \
		-Ldll \
	"
else
if [ "$PLATFORM" = "LINUX" ] ; then
	PLATFORM_OPTIONS="
		-D_LINUX \
		-rdynamic \
	"
	OUTPUT_EXT='linux'
	V4D_LIB='v4d.so'
	LIBS="$LIBS\
		-ldl \
	"
else
	echo "Invalid Platform $PLATFORM";
	exit;
fi
fi

# Build Modes
if [ "$MODE" = "RELEASE" ] ; then
	OUTPUT_DIR='build/release'
	OPTIONS="-O3 -D_RELEASE"
fi
if [ "$MODE" = "DEBUG" ] ; then
	OUTPUT_DIR='build/debug'
	OPTIONS="-ggdb -g -O0 -D_DEBUG"
fi
if [ "$MODE" = "TESTS" ] ; then
	OUTPUT_DIR='build/debug'
	if [ "$PLATFORM" = "WINDOWS" ] ; then
		OPTIONS="-ggdb -g -O0 -D_DEBUG"
	else
		OPTIONS="-ggdb -g -O0 -D_DEBUG -fsanitize=undefined -fsanitize-address-use-after-scope -fno-omit-frame-pointer"
		# OPTIONS="-ggdb -g -O0 -D_DEBUG -fsanitize=address"
		# OPTIONS="-ggdb -g -O0 -D_DEBUG -fsanitize=undefined"
		# OPTIONS="-ggdb -g -O0 -D_DEBUG -fsanitize=thread"
	fi
	OUTPUT_NAME='tests'
	ENTRY_FILE='tests.cxx'
fi
if [ "$MODE" = "TESTS_RELEASE" ] ; then
	OUTPUT_DIR='build/release'
	OPTIONS="-O3 -D_RELEASE"
	OUTPUT_NAME='tests'
	ENTRY_FILE='tests.cxx'
fi
if [ "$MODE" = "INCUBATOR" ] ; then
	OUTPUT_DIR='build/debug'
	OPTIONS="-ggdb -g -O0 -D_DEBUG"
	OUTPUT_NAME='incubator'
	ENTRY_FILE='incubator.cpp'
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

# Build PreCompiled Common Header if not exists
if [ ! -f "$PRECOMPILED_COMMON_HEADER" ] ; then
	mkdir -p "$PRECOMPILED_COMMON_HEADER_DIR"
	COMMAND="$COMPILER \
		-o "$PRECOMPILED_COMMON_HEADER" \
		$GCC_FLAGS \
		$OPTIONS \
		-D_V4D_PROJECT \
		$PLATFORM_OPTIONS \
		$ARGS \
		$GCC_COMMON_OPTIONS \
		$INCLUDES \
		$COMMON_HEADER \
	"
	echo "Rebuilding PreCompiled Common Header $MODE for $PLATFORM..."
	#echo $COMMAND
	echo "    ..... "
	OUTPUT=`$COMMAND && echo "
	SUCCESS
	"`
	echo $OUTPUT
	echo ""
fi

# https://gcc.gnu.org/onlinedocs/gcc/Preprocessor-Options.html
COMMAND="$COMPILER \
	$GCC_FLAGS \
	-o $OUTPUT_DIR/$OUTPUT_NAME.$OUTPUT_EXT \
	$OPTIONS \
	-D_V4D_PROJECT \
	$PLATFORM_OPTIONS \
	$ARGS \
	$GCC_COMMON_OPTIONS \
	$INCLUDES \
	src/$ENTRY_FILE \
	-Wl,-rpath,. \
	$OUTPUT_DIR/$V4D_LIB \
	$LIBS \
"

# Start Build Process
echo "Started build process $MODE for $PLATFORM"
#echo $COMMAND
echo "    ..... "
OUTPUT=`$COMMAND && echo "
SUCCESS
"`
echo $OUTPUT
echo ""

# Also compile for Windows if target is ALL platforms
if [ $? == 0 -a "$1" == "ALL" ] ; then
	tools/build.sh WINDOWS $2 $3
fi

# Exit with code from last command
exit $?
