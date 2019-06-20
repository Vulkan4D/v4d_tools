#!/bin/sh
PROJECT_DIR="`dirname $0`/.."
cd $PROJECT_DIR
set -e

OUTPUT_NAME='v4d'

# Paths (Libraries, includes, ...)
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig/"
export VULKAN_SDK="$PROJECT_DIR/src/vulkan_x86_64"
INCLUDES="\
  -I$PROJECT_DIR/src/glm \
  -I$PROJECT_DIR/src/glfw/include \
  -I$PROJECT_DIR/src/vulkan_x86_64/include \
  -I$PROJECT_DIR/src/v4d/core \
"
LIBS="\
  -lpthread \
"

# Platform options
if [ $1 == "WINDOWS" ] ; then
  PLATFORM='WINDOWS'
  PLATFORM_OPTIONS='-D_WINDOWS'
  COMPILER='x86_64-w64-mingw32-g++'
  OUTPUT_EXT='dll'
  LIBS="$LIBS\
    -lwinpthread \
    -lstdc++ \
    -lgcc \
    -static -static-libgcc -static-libstdc++ \
    -Ldll \
    -lglfw3 -lgdi32 \
    -lvulkan-1 \
    -lopengl32 \
  "
else
  PLATFORM='LINUX'
  PLATFORM_OPTIONS='-D_LINUX'
  COMPILER='g++'
  OUTPUT_EXT='so'
  LIBS="$LIBS\
    `pkg-config --static --libs glfw3 vulkan` \
    -lGLU -lGL \
  "
fi

# Build Modes
if [ $2 == "RELEASE" ] ; then
  MODE='RELEASE'
  OUTPUT_DIR='build/release'
  OPTIONS="-O3 -D_RELEASE"
else
  MODE='DEBUG'
  OUTPUT_DIR='build/debug'
  OPTIONS="-ggdb -g -O0 -D_DEBUG"
  # -fsanitize=address -fsanitize-address-use-after-scope -fno-omit-frame-pointer
fi

# Additional Arguments
ARGS="$3"

# Prepare Output Directory
mkdir -p "$OUTPUT_DIR"
if [ -d "res" ] && [ ! -d "$OUTPUT_DIR/res" ] ; then
  ln -s ../../res "$OUTPUT_DIR/res"
fi

# Check for Shaders to compile
#if [ -d "src/v4d/core/modules/graphics/shaders" ] ; then
#  # Compile Modified Shaders
#  mkdir -p "$OUTPUT_DIR/shaders"
#  tools/shadercompiler/shadercompiler.linux "$OUTPUT_DIR/shaders" `find src/v4d/core/shaders -maxdepth 1 -type f`
#fi

# If shader compilation was successful, Start Build
if [ $? == 0 ] ; then

  # https://gcc.gnu.org/onlinedocs/gcc/Preprocessor-Options.html
  COMMAND="$COMPILER \
    -Wall \
    -shared -Wl,-soname,$OUTPUT_NAME.$OUTPUT_EXT \
    -o $OUTPUT_DIR/$OUTPUT_NAME.$OUTPUT_EXT \
    $OPTIONS \
    -D_V4D_CORE
    $PLATFORM_OPTIONS \
    $ARGS \
    -fPIC \
    -std=c++17 \
    -m64 \
    -I. \
    $INCLUDES \
    `find src/v4d/core -type f -name *.cpp` \
    $LIBS \
  "

  # Start Build Process
  echo "Started V4D build process $MODE for $PLATFORM"
  echo $COMMAND
  echo "    .....
  "
  OUTPUT=`$COMMAND && echo "
  $PLATFORM V4D BUILD SUCCESS"`
  echo $OUTPUT
  echo ""

  # Also compile for Windows if target is ALL platforms
  if [ $? == 0 -a $1 == "ALL" ] ; then
    echo "--------------------------------
    "
    sh/build.sh WINDOWS $2 $3
  fi

  # Exit with code from last command
  exit $?
fi
exit $?
