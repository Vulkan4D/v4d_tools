# Vars

# Used only for Generating Precompiled Headers
GCH_DIR="build/gch/$TYPE.$MODE.$PLATFORM"
COMMON_HEADER="src/v4d/core/common/pch.hh"
PRECOMPILED_COMMON_HEADER_DIR="$GCH_DIR/common"
PRECOMPILED_COMMON_HEADER="$PRECOMPILED_COMMON_HEADER_DIR/pch.hh.gch"

INCLUDES="\
	-I$PROJECT_DIR/$GCH_DIR \
	-I$PROJECT_DIR/src/v4d/core \
"
LIBS="\
	-lpthread \
"
GCC_COMMON_OPTIONS="
	-std=c++17 \
	-m64 \
"

# Paths (Libraries, includes, ...)
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig/"
export VULKAN_SDK="$PROJECT_DIR/src/vulkan_x86_64"
export LSAN_OPTIONS="verbosity=1:log_threads=1"

# GCC Flags
GCC_FLAGS="$GCC_FLAGS -pipe"

# Errors
GCC_FLAGS="$GCC_FLAGS -fmax-errors=1"
GCC_FLAGS="$GCC_FLAGS -Wfatal-errors"
# GCC_FLAGS="$GCC_FLAGS -Werror"

# Warnings
GCC_FLAGS="$GCC_FLAGS -Wall"
GCC_FLAGS="$GCC_FLAGS -Wextra"
GCC_FLAGS="$GCC_FLAGS -Wnon-virtual-dtor"
GCC_FLAGS="$GCC_FLAGS -Wcast-align"
GCC_FLAGS="$GCC_FLAGS -Woverloaded-virtual"
GCC_FLAGS="$GCC_FLAGS -Wconversion"
GCC_FLAGS="$GCC_FLAGS -Wsign-conversion"
GCC_FLAGS="$GCC_FLAGS -Wnull-dereference"
GCC_FLAGS="$GCC_FLAGS -Wdouble-promotion"
GCC_FLAGS="$GCC_FLAGS -Wformat=2"
GCC_FLAGS="$GCC_FLAGS -Wduplicated-cond"
GCC_FLAGS="$GCC_FLAGS -Wduplicated-branches"
GCC_FLAGS="$GCC_FLAGS -Wlogical-op"
GCC_FLAGS="$GCC_FLAGS -Wunused"
GCC_FLAGS="$GCC_FLAGS -Wpessimizing-move"
GCC_FLAGS="$GCC_FLAGS -Wredundant-move"
# GCC_FLAGS="$GCC_FLAGS -Wshadow"

