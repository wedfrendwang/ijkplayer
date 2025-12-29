# --- BEGIN: NDK toolchain compatibility block ---
# FF_TOOLCHAIN_PATH is expected later; if old standalone maker exists use it,
# otherwise use NDK r19+ llvm prebuilt toolchain directly.

NDK_BUILD_TOOL="$ANDROID_NDK/build/tools/make-standalone-toolchain.sh"
if [ -f "$NDK_BUILD_TOOL" ]; then
    # old NDK: create standalone toolchain (existing behavior)
    if [ ! -f "$FF_TOOLCHAIN_TOUCH" ]; then
        $NDK_BUILD_TOOL \
            $FF_MAKE_TOOLCHAIN_FLAGS \
            --platform=$FF_ANDROID_PLATFORM \
            --toolchain=$FF_TOOLCHAIN_NAME
        touch $FF_TOOLCHAIN_TOUCH
    fi
else
    # new NDK (r19+): use LLVM/Clang toolchain located in toolchains/llvm/prebuilt/<host>
    # Determine host prebuilt directory name:
    case "$(uname -s)" in
        Darwin) HOST_TAG=darwin-x86_64 ;;
        Linux) HOST_TAG=linux-x86_64 ;;
        CYGWIN*|MINGW*|MSYS*) HOST_TAG=windows-x86_64 ;;
        *) HOST_TAG=linux-x86_64 ;;
    esac

    FF_TOOLCHAIN_PATH="$ANDROID_NDK/toolchains/llvm/prebuilt/$HOST_TAG"
    if [ ! -d "$FF_TOOLCHAIN_PATH" ]; then
        echo "ERROR: expected NDK toolchain at $FF_TOOLCHAIN_PATH (NDK r19+ required?)"
        echo "Please set ANDROID_NDK to an NDK with llvm prebuilt toolchains."
        exit 1
    fi

    # Set sysroot and ensure PATH includes toolchain bin
    FF_SYSROOT="$FF_TOOLCHAIN_PATH/sysroot"
    export PATH="$FF_TOOLCHAIN_PATH/bin:$PATH"

    # Map arch -> clang wrapper name and API level. Use FF_ANDROID_PLATFORM if set.
    API_LEVEL=${FF_ANDROID_PLATFORM#android-}
    case "$FF_ARCH" in
        armv7a)
            # Use the clang wrapper which encodes API level in its name:
            export CC="armv7a-linux-androideabi${API_LEVEL}-clang"
            export CXX="armv7a-linux-androideabi${API_LEVEL}-clang++"
            export AR="llvm-ar"
            export LD="ld"        # linker from NDK/LLVM; configure may override
            export STRIP="llvm-strip"
            FF_CROSS_PREFIX="arm-linux-androideabi"
            ;;
        armv5)
            export CC="armv7a-linux-androideabi${API_LEVEL}-clang -march=armv5te -msoft-float"
            export CXX="armv7a-linux-androideabi${API_LEVEL}-clang++"
            export AR="llvm-ar"
            export STRIP="llvm-strip"
            FF_CROSS_PREFIX="arm-linux-androideabi"
            ;;
        arm64)
            export CC="aarch64-linux-android${API_LEVEL}-clang"
            export CXX="aarch64-linux-android${API_LEVEL}-clang++"
            export AR="llvm-ar"
            export STRIP="llvm-strip"
            FF_CROSS_PREFIX="aarch64-linux-android"
            ;;
        x86)
            export CC="i686-linux-android${API_LEVEL}-clang"
            export CXX="i686-linux-android${API_LEVEL}-clang++"
            export AR="llvm-ar"
            export STRIP="llvm-strip"
            FF_CROSS_PREFIX="i686-linux-android"
            ;;
        x86_64)
            export CC="x86_64-linux-android${API_LEVEL}-clang"
            export CXX="x86_64-linux-android${API_LEVEL}-clang++"
            export AR="llvm-ar"
            export STRIP="llvm-strip"
            FF_CROSS_PREFIX="x86_64-linux-android"
            ;;
        *)
            echo "Unsupported arch for new NDK flow: $FF_ARCH"
            exit 1
            ;;
    esac

    # Ensure CC/CXX point to full path (NDK prebuilt bin)
    # If clang wrappers exist with API suffix in bin, use them directly, else use 'clang' + --target
    if command -v "$CC" >/dev/null 2>&1; then
        : # wrapper available in PATH (since we added FF_TOOLCHAIN_PATH/bin)
    else
        # Fallback: use clang with --target and sysroot (works in many cases)
        TARGET=""
        case "$FF_ARCH" in
            armv7a) TARGET="armv7a-linux-androideabi" ;;
            armv5) TARGET="armv7a-linux-androideabi" ;;
            arm64) TARGET="aarch64-linux-android" ;;
            x86) TARGET="i686-linux-android" ;;
            x86_64) TARGET="x86_64-linux-android" ;;
        esac
        export CC="$FF_TOOLCHAIN_PATH/bin/clang --target=${TARGET}${API_LEVEL} --sysroot=$FF_SYSROOT"
        export CXX="$FF_TOOLCHAIN_PATH/bin/clang++ --target=${TARGET}${API_LEVEL} --sysroot=$FF_SYSROOT"
    fi

    # leave FF_TOOLCHAIN_PATH and FF_SYSROOT set for later use
fi
# --- END: NDK toolchain compatibility block ---