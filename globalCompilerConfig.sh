# source this file in build scripts, must first define TYPE,MODE,PLATFORM and optionally INCLUDES,LIBS,GCC_COMMON_OPTIONS,GCC_FLAGS

# Used only for Generating Precompiled Headers
GCHMODE="$MODE"
if [ "$GCHMODE" = "TESTS" ] ; then 
	GCHMODE="DEBUG"
fi
if [ "$GCHMODE" = "INCUBATOR" ] ; then 
	GCHMODE="DEBUG"
fi
if [ "$GCHMODE" = "TESTS_RELEASE" ] ; then 
	GCHMODE="RELEASE"
fi
GCH_DIR="build/gch/$TYPE.$GCHMODE.$PLATFORM"
COMMON_HEADER="src/v4d/core/common/pch.hh"
PRECOMPILED_COMMON_HEADER_DIR="$GCH_DIR/common"
PRECOMPILED_COMMON_HEADER="$PRECOMPILED_COMMON_HEADER_DIR/pch.hh.gch"


# Include GCH
INCLUDES="$INCLUDES -I$PROJECT_DIR/$GCH_DIR"

INCLUDES="$INCLUDES \
	-I$PROJECT_DIR/src/v4d/core \
"
VULKAN_INCLUDES="\
	-I$PROJECT_DIR/src/Vulkan-Hpp \
	-I$PROJECT_DIR/src/Vulkan-Hpp/glm \
	-I$PROJECT_DIR/src/Vulkan-Hpp/glslang \
	-I$PROJECT_DIR/src/Vulkan-Hpp/glfw/include \
	-I$PROJECT_DIR/src/Vulkan-Hpp/Vulkan-Headers/include \
"
LIBS="$LIBS \
	-lpthread \
"
if [ "$PLATFORM" = "WINDOWS" ] ; then
	VULKAN_LIBS="\
		-lglfw3 -lgdi32 \
		-lvulkan-1 \
		-lopengl32 \
	"
else
	VULKAN_LIBS="\
		`pkg-config --static --libs glfw3 vulkan gl glu` \
	"
fi
GCC_COMMON_OPTIONS="$GCC_COMMON_OPTIONS \
	-std=c++17 \
	-m64 \
"

if [ "$PLATFORM" = "WINDOWS" ] ; then
	COMPILER="x86_64-w64-mingw32-g++ -D_WIN32_WINNT=0x06030000"
	# COMPILER="x86_64-w64-mingw32-clang++ -D_WIN32_WINNT=0x06030000"
	LIBS="$LIBS\
		-lwinpthread \
		-Ldll \
	"
else
	COMPILER="g++"
	# COMPILER="clang++"
	LIBS="$LIBS\
		-ldl \
	"
fi

# Paths (Libraries, includes, ...)
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig/"
export VULKAN_SDK="$PROJECT_DIR/src/vulkan_x86_64"
export LSAN_OPTIONS="verbosity=1:log_threads=1"

# GCC Flags
GCC_FLAGS="$GCC_FLAGS -pipe"

# Errors
# GCC_FLAGS="$GCC_FLAGS -fmax-errors=1"
GCC_FLAGS="$GCC_FLAGS -Wfatal-errors"
# GCC_FLAGS="$GCC_FLAGS -Werror"


# Warnings

# GCC_FLAGS="$GCC_FLAGS -Wall"
# GCC_FLAGS="$GCC_FLAGS -Wextra"
GCC_FLAGS="$GCC_FLAGS -Wnon-virtual-dtor"
GCC_FLAGS="$GCC_FLAGS -Wcast-align"
GCC_FLAGS="$GCC_FLAGS -Woverloaded-virtual"
# GCC_FLAGS="$GCC_FLAGS -Wconversion"
# GCC_FLAGS="$GCC_FLAGS -Wsign-conversion"
GCC_FLAGS="$GCC_FLAGS -Wnull-dereference"
# GCC_FLAGS="$GCC_FLAGS -Wdouble-promotion"
GCC_FLAGS="$GCC_FLAGS -Wformat=2"
GCC_FLAGS="$GCC_FLAGS -Wunused"
GCC_FLAGS="$GCC_FLAGS -Wpessimizing-move"
GCC_FLAGS="$GCC_FLAGS -Wredundant-move"

GCC_FLAGS="$GCC_FLAGS -Wduplicated-cond"
# GCC_FLAGS="$GCC_FLAGS -Wduplicated-branches"
GCC_FLAGS="$GCC_FLAGS -Wlogical-op"

# GCC_FLAGS="$GCC_FLAGS -Wshadow"
