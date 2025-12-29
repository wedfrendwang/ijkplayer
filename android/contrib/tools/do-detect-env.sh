#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script is based on projects below
# https://github.com/yixia/FFmpeg-Android
# http://git.videolan.org/?p=vlc-ports/android.git;a=summary

#--------------------
set -e
# 作用：运行 uname -s 获取操作系统名称（例如 Linux、Darwin、CYGWIN_NT-10.0），并把结果存入变量 UNAME_S。
UNAME_S=$(uname -s) 
#作用：运行 uname -sm 获取操作系统名称与硬件架构（例如 Linux x86_64 或 Darwin x86_64），并把结果存入 UNAME_SM。
UNAME_SM=$(uname -sm)

echo "------------------- do-detect-env.sh -------------------" 
echo "build on $UNAME_SM" # Linux x86_64


echo "ANDROID_NDK=$ANDROID_NDK" 
if [ -z "$ANDROID_NDK" ]; then
    echo "You must define ANDROID_NDK before starting."
    echo "They must point to your NDK directories."
    echo ""
    exit 1
fi



# try to detect NDK version
export IJK_GCC_VER=4.9
export IJK_GCC_64_VER=4.9
export IJK_MAKE_TOOLCHAIN_FLAGS=
export IJK_MAKE_FLAG=
# get ndk release version
export IJK_NDK_REL=$(grep -o '^r[0-9]*.*' $ANDROID_NDK/RELEASE.TXT 2>/dev/null | sed 's/[[:space:]]*//g' | cut -b2-)
case "$IJK_NDK_REL" in
    10e*)
        # we don't use 4.4.3 because it doesn't handle threads correctly.
        if test -d ${ANDROID_NDK}/toolchains/arm-linux-androideabi-4.8
        # if gcc 4.8 is present, it's there for all the archs (x86, mips, arm)
        then
            echo "NDKr$IJK_NDK_REL detected"

            case "$UNAME_S" in
                Darwin)
                    export IJK_MAKE_TOOLCHAIN_FLAGS="$IJK_MAKE_TOOLCHAIN_FLAGS --system=darwin-x86_64"
                ;;
                CYGWIN_NT-*)
                    export IJK_MAKE_TOOLCHAIN_FLAGS="$IJK_MAKE_TOOLCHAIN_FLAGS --system=windows-x86_64"
                ;;
            esac
        else
            echo "You need the NDKr10e or later"
            exit 1
        fi
    ;;
    *)
        IJK_NDK_REL=$(grep -o '^Pkg\.Revision.*=[0-9]*.*' $ANDROID_NDK/source.properties 2>/dev/null | sed 's/[[:space:]]*//g' | cut -d "=" -f 2)
        echo "IJK_NDK_REL=$IJK_NDK_REL"
        case "$IJK_NDK_REL" in
            11*|12*|13*|14*)
                if test -d ${ANDROID_NDK}/toolchains/arm-linux-androideabi-4.9
                then
                    echo "NDKr$IJK_NDK_REL detected"
                else
                    echo "You need the NDKr10e or later"
                    exit 1
                fi
            ;;
            *)
                #如果是最新的 NDK r21（或 r19+）：请放弃这条旧命令。您应该直接使用 $NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/ 下的 Clang 编译器。
                echo "You need the NDKr10e or later"
                exit 1
            ;;
        esac
    ;;
esac


case "$UNAME_S" in
    Darwin)
        export IJK_MAKE_FLAG=-j`sysctl -n machdep.cpu.thread_count`
    ;;
    CYGWIN_NT-*)
        IJK_WIN_TEMP="$(cygpath -am /tmp)"
        export TEMPDIR=$IJK_WIN_TEMP/

        echo "Cygwin temp prefix=$IJK_WIN_TEMP/"
    ;;
esac

echo "do-detect-env.sh done. NDK r$IJK_NDK_REL, GCC $IJK_GCC_VER  , GCC64 $IJK_GCC_64_VER ,IJK_MAKE_TOOLCHAIN_FLAGS $IJK_MAKE_TOOLCHAIN_FLAGS ,IJK_MAKE_FLAG $IJK_MAKE_FLAG"
echo "--------------------"