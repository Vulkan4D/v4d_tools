#!/bin/sh
PROJECT_DIR="`dirname $0`/.."
cd $PROJECT_DIR
set -e

# args
PLATFORM="$1"
MODE="$2"
# Additional Arguments
ARGS="$3"

TYPE='CORE'

if [ "$PLATFORM" = "ALL" ] ; then
	PLATFORM='LINUX'
fi

#vars
OUTPUT_NAME='v4d'
source "tools/globalCompilerConfig.sh"
INCLUDES="$INCLUDES \
	-Isrc/Vulkan-Hpp \
	-Isrc/Vulkan-Hpp/glm \
	-Isrc/Vulkan-Hpp/glfw/include \
	-Isrc/Vulkan-Hpp/Vulkan-Headers/include \
	-Isrc/openssl/include \
"

# Platform options
if [ "$PLATFORM" = "WINDOWS" ] ; then
	PLATFORM_OPTIONS="
		-D_WINDOWS \
	"
	OUTPUT_EXT='dll'
	LIBS="$LIBS\
		-lwinpthread \
		-lgcc \
		-lws2_32 \
		-Ldll \
		-lglfw3 -lgdi32 \
		-lvulkan-1 \
		-lopengl32 \
		-llibssl-1_1-x64 \
		-llibcrypto-1_1-x64 \
		-static-libstdc++ \
	"
else 
if [ "$PLATFORM" = "LINUX" ] ; then
	PLATFORM_OPTIONS="
		-D_LINUX \
		-fPIC \
	"
	OUTPUT_EXT='so'
	LIBS="$LIBS\
		-lssl \
		-ldl \
		`pkg-config --static --libs glfw3 vulkan` \
		-lGLU -lGL \
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
else 
if [ "$MODE" = "DEBUG" ] ; then
	OUTPUT_DIR='build/debug'
	OPTIONS="-ggdb -g -O0 -D_DEBUG"
else
	echo "Invalid Mode $MODE";
	exit;
fi
fi

# Additional Arguments
ARGS="$3"

# Prepare Output Directory
mkdir -p "$OUTPUT_DIR"
if [ -d "res" ] && [ ! -d "$OUTPUT_DIR/res" ] ; then
	ln -s ../../res "$OUTPUT_DIR/res"
fi

# Build PreCompiled Common Header if not exists
if [ ! -f "$PRECOMPILED_COMMON_HEADER" ] ; then
	mkdir -p "$PRECOMPILED_COMMON_HEADER_DIR"
	COMMAND="$COMPILER \
		$GCC_FLAGS \
		-o "$PRECOMPILED_COMMON_HEADER" \
		$OPTIONS \
		-D_V4D_CORE \
		$PLATFORM_OPTIONS \
		$ARGS \
		$GCC_COMMON_OPTIONS \
		$INCLUDES \
		$COMMON_HEADER \
	"
	echo "Rebuilding PreCompiled Common Core Header $MODE for $PLATFORM..."
	#echo $COMMAND
	echo "    ..... "
	OUTPUT=`$COMMAND && echo "
	SUCCESS
	"`
	echo $OUTPUT
	echo ""
fi

# Check for Shaders to compile
#if [ -d "src/v4d/core/utilities/graphics/shaders" ] ; then
#  # Compile Modified Shaders
#  mkdir -p "$OUTPUT_DIR/shaders"
#  tools/shadercompiler/shadercompiler.linux "$OUTPUT_DIR/shaders" `find src/v4d/core/shaders -maxdepth 1 -type f`
#fi

# If shader compilation was successful, Start Build
if [ $? == 0 ] ; then

	# https://gcc.gnu.org/onlinedocs/gcc/Preprocessor-Options.html
	COMMAND="$COMPILER \
		$GCC_FLAGS \
		-shared -Wl,-soname,$OUTPUT_NAME.$OUTPUT_EXT \
		-o $OUTPUT_DIR/$OUTPUT_NAME.$OUTPUT_EXT \
		$OPTIONS \
		-D_V4D_CORE
		$PLATFORM_OPTIONS \
		$ARGS \
		-fPIC \
		$GCC_COMMON_OPTIONS \
		$INCLUDES \
		`find src/v4d/core -type f -name *.cpp` \
		$LIBS \
	"

	# Start Build Process
	echo "Started V4D Core build process $MODE for $PLATFORM"
	#echo $COMMAND
	echo "    ..... "
	OUTPUT=`$COMMAND && echo "
	SUCCESS
	"`
	echo $OUTPUT
	echo ""

	# Also compile for Windows if target is ALL platforms
	if [ $? == 0 -a "$1" == "ALL" ] ; then
		tools/build_v4d.sh WINDOWS $2 $3
	fi

	# Exit with code from last command
	exit $?
fi
exit $?
