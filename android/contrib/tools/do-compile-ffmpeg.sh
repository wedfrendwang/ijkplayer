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
echo "===================="
echo "[*] check env $1"
echo "===================="
set -e


#--------------------
# common defines
FF_ARCH=$1
FF_BUILD_OPT=$2
echo "FF_ARCH=$FF_ARCH"
echo "FF_BUILD_OPT=$FF_BUILD_OPT"
# 判断FF_ARCH是否为空
if [ -z "$FF_ARCH" ]; then
    echo "You must specific an architecture 'arm, armv7a, x86, ...'."
    echo ""
    exit 1
fi


FF_BUILD_ROOT=`pwd`
echo "FF_BUILD_ROOT=$FF_BUILD_ROOT"
FF_ANDROID_PLATFORM=android-9 # default platform is android-9


FF_BUILD_NAME=
FF_SOURCE=
FF_CROSS_PREFIX=
FF_DEP_OPENSSL_INC=
FF_DEP_OPENSSL_LIB=

FF_DEP_LIBSOXR_INC=
FF_DEP_LIBSOXR_LIB=

FF_CFG_FLAGS=

FF_EXTRA_CFLAGS=
FF_EXTRA_LDFLAGS=
FF_DEP_LIBS=

FF_MODULE_DIRS="compat libavcodec libavfilter libavformat libavutil libswresample libswscale"
FF_ASSEMBLER_SUB_DIRS=


#--------------------
echo ""
echo "--------------------"
echo "[*] make NDK standalone toolchain"
echo "--------------------" 
# 引入并执行 do-detect-env.sh（会检测 ANDROID_NDK、NDK 版本并设置 IJK_MAKE_TOOLCHAIN_FLAGS、IJK_MAKE_FLAG、IJK_GCC_VER 等环境变量）。
. ./tools/do-detect-env.sh
FF_MAKE_TOOLCHAIN_FLAGS=$IJK_MAKE_TOOLCHAIN_FLAGS # 根据Linux平台，此值为空
FF_MAKE_FLAGS=$IJK_MAKE_FLAG
FF_GCC_VER=$IJK_GCC_VER # 4.9
FF_GCC_64_VER=$IJK_GCC_64_VER # 4.9


#----- armv7a begin -----
if [ "$FF_ARCH" = "armv7a" ]; then
    FF_BUILD_NAME=ffmpeg-armv7a
    FF_BUILD_NAME_OPENSSL=openssl-armv7a
    FF_BUILD_NAME_LIBSOXR=libsoxr-armv7a
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=arm-linux-androideabi
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm --cpu=cortex-a8"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-neon"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-thumb"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv7-a -mcpu=cortex-a8 -mfpu=vfpv3-d16 -mfloat-abi=softfp -mthumb"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"

    FF_ASSEMBLER_SUB_DIRS="arm"

elif [ "$FF_ARCH" = "armv5" ]; then
    FF_BUILD_NAME=ffmpeg-armv5
    FF_BUILD_NAME_OPENSSL=openssl-armv5
    FF_BUILD_NAME_LIBSOXR=libsoxr-armv5
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME #android/contrib/ffmpeg-armv5

    FF_CROSS_PREFIX=arm-linux-androideabi
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER} #arm-linux-androideabi-4.9

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv5te -mtune=arm9tdmi -msoft-float"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASSEMBLER_SUB_DIRS="arm"

elif [ "$FF_ARCH" = "x86" ]; then
    FF_BUILD_NAME=ffmpeg-x86
    FF_BUILD_NAME_OPENSSL=openssl-x86
    FF_BUILD_NAME_LIBSOXR=libsoxr-x86
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=i686-linux-android
    FF_TOOLCHAIN_NAME=x86-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86 --cpu=i686 --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=atom -msse3 -ffast-math -mfpmath=sse"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASSEMBLER_SUB_DIRS="x86"

elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_ANDROID_PLATFORM=android-21

    FF_BUILD_NAME=ffmpeg-x86_64
    FF_BUILD_NAME_OPENSSL=openssl-x86_64
    FF_BUILD_NAME_LIBSOXR=libsoxr-x86_64
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=x86_64-linux-android
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86_64 --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASSEMBLER_SUB_DIRS="x86"

elif [ "$FF_ARCH" = "arm64" ]; then
    FF_ANDROID_PLATFORM=android-21

    FF_BUILD_NAME=ffmpeg-arm64
    FF_BUILD_NAME_OPENSSL=openssl-arm64
    FF_BUILD_NAME_LIBSOXR=libsoxr-arm64
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=aarch64-linux-android
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=aarch64 --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASSEMBLER_SUB_DIRS="aarch64 neon"

else
    echo "unknown architecture $FF_ARCH";
    exit 1
fi

if [ ! -d $FF_SOURCE ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find FFmpeg directory for $FF_BUILD_NAME"
    echo "!! Run 'sh init-android.sh' first"
    echo ""
    exit 1
fi


# 工具链路径与安装目录
# FF_BUILD_ROOT=/home/xiaobowang/Downloads/ijk/ijkplayer/android/contrib
FF_TOOLCHAIN_PATH=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/toolchain
FF_MAKE_TOOLCHAIN_FLAGS="$FF_MAKE_TOOLCHAIN_FLAGS --install-dir=$FF_TOOLCHAIN_PATH"

FF_SYSROOT=$FF_TOOLCHAIN_PATH/sysroot
FF_PREFIX=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output
FF_DEP_OPENSSL_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/include
FF_DEP_OPENSSL_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/lib
FF_DEP_LIBSOXR_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/include
FF_DEP_LIBSOXR_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/lib

case "$UNAME_S" in
    CYGWIN_NT-*)
        FF_SYSROOT="$(cygpath -am $FF_SYSROOT)"
        FF_PREFIX="$(cygpath -am $FF_PREFIX)"
    ;;
esac


mkdir -p $FF_PREFIX
# mkdir -p $FF_SYSROOT

#
#Copying prebuilt binaries...
# Copying sysroot headers and libraries...
# Copying c++ runtime headers and libraries...
# Copying files to: /home/xiaobowang/Downloads/ijk/ijkplayer/android/contrib/build/ffmpeg-armv5/toolchain
# Cleaning up...
# Done.
# 

FF_TOOLCHAIN_TOUCH="$FF_TOOLCHAIN_PATH/touch" #定义标志文件路径，作为工具链已创建的标识。
if [ ! -f "$FF_TOOLCHAIN_TOUCH" ]; then
    # 创建独立工具链,NDK r10e - r21 , r21+ 已废弃该脚本,Clang 编译器
    $ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
        $FF_MAKE_TOOLCHAIN_FLAGS \
        --platform=$FF_ANDROID_PLATFORM \
        --toolchain=$FF_TOOLCHAIN_NAME
    #创建标志文件以避免重复创建工具链。
    touch $FF_TOOLCHAIN_TOUCH;
fi


#--------------------
echo ""
echo "--------------------"
echo "[*] check ffmpeg env"
echo "--------------------"
export PATH=$FF_TOOLCHAIN_PATH/bin/:$PATH
# export CC="${FF_CROSS_PREFIX}-gcc"、export LD=${FF_CROSS_PREFIX}-ld、export AR=${FF_CROSS_PREFIX}-ar、export STRIP=${FF_CROSS_PREFIX}-strip
# 设置交叉编译器/链接器/归档工具等名字，供 configure 与 make 使用。
# GCC GCC是一个编译器，用于将C、C++等源代码编译成机器代码。在FFmpeg的编译中，它负责编译源文件（.c文件）生成目标文件（.o文件）。
# LD 作用：LD是链接器，用于将多个目标文件（.o文件）和库文件（.a或.so文件）链接在一起，生成可执行文件或共享库。
# AR 作用：AR用于创建、修改和提取静态库（归档文件）。静态库是一组目标文件的集合，通常以.a为后缀。在FFmpeg中，AR用于将多个目标文件打包成静态库。
# STRIP 作用：STRIP用于去除可执行文件或库文件中的符号表和调试信息，从而减小文件大小。在FFmpeg的发布版本中，通常会使用STRIP来减小最终生成的二进制文件的体积。
export CC="${FF_CROSS_PREFIX}-gcc"
export LD=${FF_CROSS_PREFIX}-ld
export AR=${FF_CROSS_PREFIX}-ar
export STRIP=${FF_CROSS_PREFIX}-strip

FF_CFLAGS="-O3 -Wall -pipe \
    -std=c99 \
    -ffast-math \
    -fstrict-aliasing -Werror=strict-aliasing \
    -Wno-psabi -Wa,--noexecstack \
    -DANDROID -DNDEBUG"

# cause av_strlcpy crash with gcc4.7, gcc4.8
# -fmodulo-sched -fmodulo-sched-allow-regmoves

# --enable-thumb is OK
#FF_CFLAGS="$FF_CFLAGS -mthumb"

# not necessary
#FF_CFLAGS="$FF_CFLAGS -finline-limit=300"

export COMMON_FF_CFG_FLAGS=
. $FF_BUILD_ROOT/../../config/module.sh


#--------------------
# 检测并集成 OpenSSL / libsoxr
# 集成OpenSSL的作用
# OpenSSL是一个强大的安全套接字层密码库，包括主要的密码算法、常用的密钥和证书封装管理功能及SSL协议。在FFmpeg中集成OpenSSL主要提供以下功能：

# 作用：
# 支持加密流媒体协议：如HTTPS、FTPS、RTMPS等。

# 支持SRTP（安全实时传输协议）：用于加密RTP流，常用于WebRTC。

# 支持数字版权管理（DRM）：一些受保护的流媒体内容需要SSL/TLS进行解密。

# 支持安全连接：在访问需要安全认证的服务器时，必须使用SSL/TLS。

# 未集成的影响：
# 无法编译和使用https、tls等协议。

# 无法访问需要SSL/TLS加密的流媒体服务器（如一些付费视频网站）。

# 无法处理加密的SRTP流。

# 在某些需要安全传输的场景下，FFmpeg的功能会受到限制。

# bash
# ./configure --enable-openssl
# 如果需要指定OpenSSL的安装路径，可以使用：

# bash
# ./configure --enable-openssl --extra-ldflags=-L/usr/local/ssl/lib --extra-cflags=-I/usr/local/ssl/include



# with openssl
if [ -f "${FF_DEP_OPENSSL_LIB}/libssl.a" ]; then
    echo "OpenSSL detected"
# FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-nonfree"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-openssl"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_OPENSSL_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_OPENSSL_LIB} -lssl -lcrypto"
fi

# 2. 集成libsoxr的作用
# libsoxr（SoX Resampler）是SoX项目中的高质量音频重采样库。它使用DSP算法进行音频重采样，能够提供高质量的音质。

# 作用：
# 音频重采样：将音频从一个采样率转换到另一个采样率。

# 高质量音频处理：提供高质量的重采样算法，包括低延迟、高质量等不同设置。

# 支持多种重采样算法：可以根据需要选择不同的重采样算法，平衡速度和质量。

# 未集成的影响：
# FFmpeg将使用内置的重采样器（如swresample），但可能无法达到libsoxr的高质量。

# 在某些对音频质量要求极高的场景下，可能无法满足需求。

# 集成方法：
# bash
# ./configure --enable-libsoxr
# 如果libsoxr安装在自定义路径，需要指定：

# bash
# ./configure --enable-libsoxr --extra-ldflags=-L/usr/local/lib --extra-cflags=-I/usr/local/include

if [ -f "${FF_DEP_LIBSOXR_LIB}/libsoxr.a" ]; then
    echo "libsoxr detected"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libsoxr"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_LIBSOXR_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_LIBSOXR_LIB} -lsoxr"
fi

FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"

#--------------------
# Standard options:
FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$FF_PREFIX"
# 在 configure 参数里启用 shared、禁用 static
# FF_CFG_FLAGS="$FF_CFG_FLAGS  --enable-shared --disable-static"
# Advanced options (experts only):
FF_CFG_FLAGS="$FF_CFG_FLAGS --cross-prefix=${FF_CROSS_PREFIX}-"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-cross-compile"
FF_CFG_FLAGS="$FF_CFG_FLAGS --target-os=linux"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-pic"
# FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-symver"

if [ "$FF_ARCH" = "x86" ]; then
    FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-asm"
else
    # Optimization options (experts only):
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-asm"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-inline-asm"
fi

case "$FF_BUILD_OPT" in
    debug)
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-optimizations"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-small"
    ;;
    *)
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-optimizations"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-small"
    ;;
esac

#--------------------
echo ""
echo "--------------------"
echo "[*] configurate ffmpeg"
echo "--------------------"
cd $FF_SOURCE
if [ -f "./config.h" ]; then
    echo 'reuse configure'
else
    which $CC
    ./configure $FF_CFG_FLAGS \
        --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
        --extra-ldflags="$FF_DEP_LIBS $FF_EXTRA_LDFLAGS"
    make clean
fi

#--------------------
echo ""
echo "--------------------"
echo "[*] compile ffmpeg"
echo "--------------------"
cp config.* $FF_PREFIX
# make $FF_MAKE_FLAGS > /dev/null 的含义是执行 make 命令，并将标准输出（stdout）重定向到 /dev/null
#（即丢弃标准输出）。
#make $FF_MAKE_FLAGS > "$FF_PREFIX/build.log" 2>&1 || { echo "Build failed, see $FF_PREFIX/build.log"; exit 1; }

make $FF_MAKE_FLAGS > /dev/null
make install
mkdir -p $FF_PREFIX/include/libffmpeg
cp -f config.h $FF_PREFIX/include/libffmpeg/config.h

#--------------------
echo ""
echo "--------------------"
echo "[*] link ffmpeg"
echo "--------------------"
echo $FF_EXTRA_LDFLAGS

FF_C_OBJ_FILES=
FF_ASM_OBJ_FILES=
for MODULE_DIR in $FF_MODULE_DIRS
do
    #.o 文件是中间编译产物，通常链接到最终的库文件（如 libavutil.so 或 libavutil.a）
    C_OBJ_FILES="$MODULE_DIR/*.o"
    # ls 命令用于列出文件和目录的内容。在这里，ls $C_OBJ_FILES 1> /dev/null 2>&1 的作用是检查是否存在匹配 $C_OBJ_FILES 模式的文件。
    # 如果存在匹配的文件，ls 命令会成功执行，并且不会输出任何内容（因为标准输出被重定向到 /dev/null）。
    # 如果没有匹配的文件，ls 命令会失败，并且错误信息也不会显示出来（因为标准错误也被重定向到 /dev/null）。
    if ls $C_OBJ_FILES 1> /dev/null 2>&1; then
        echo "link $MODULE_DIR/*.o"
        FF_C_OBJ_FILES="$FF_C_OBJ_FILES $C_OBJ_FILES"
    fi

    for ASM_SUB_DIR in $FF_ASSEMBLER_SUB_DIRS
    do
        ASM_OBJ_FILES="$MODULE_DIR/$ASM_SUB_DIR/*.o"
        if ls $ASM_OBJ_FILES 1> /dev/null 2>&1; then
            echo "link $MODULE_DIR/$ASM_SUB_DIR/*.o"
            FF_ASM_OBJ_FILES="$FF_ASM_OBJ_FILES $ASM_OBJ_FILES"
        fi
    done
done


# $CC: 编译器，通常是gcc或clang。

# -lm: 链接数学库（libm）。

# -lz: 链接zlib压缩库。

# -shared: 告诉编译器生成一个共享库（动态库）。

# --sysroot=$FF_SYSROOT: 设置目标系统的根目录，用于寻找库和头文件，常用于交叉编译。

# -Wl,--no-undefined: 告诉链接器，如果有未定义的符号，就报告错误。这是一个链接器选项，通过-Wl传递给链接器。

# -Wl,-z,noexecstack: 告诉链接器生成的可执行文件（或共享库）的栈不可执行，这是一种安全特性。

# $FF_EXTRA_LDFLAGS: 额外的链接选项，由构建系统定义。

# -Wl,-soname,libijkffmpeg.so: 设置共享库的soname（共享库的简短名称），用于运行时动态链接。

# $FF_C_OBJ_FILES: C语言源文件编译出的目标文件列表。

# $FF_ASM_OBJ_FILES: 汇编源文件编译出的目标文件列表。

# $FF_DEP_LIBS: 依赖的其他库（比如FFmpeg的各个库，如avcodec、avformat等）。

# -o $FF_PREFIX/libijkffmpeg.so: 指定输出文件路径和名称。

echo "生成共享库 libijkffmpeg.so"

$CC -lm -lz -shared --sysroot=$FF_SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack $FF_EXTRA_LDFLAGS \
    -Wl,-soname,libijkffmpeg.so \
    $FF_C_OBJ_FILES \
    $FF_ASM_OBJ_FILES \
    $FF_DEP_LIBS \
    -o $FF_PREFIX/libijkffmpeg.so

mysedi() {
    f=$1
    exp=$2
    n=`basename $f`
    cp $f /tmp/$n
    sed $exp /tmp/$n > $f
    rm /tmp/$n
}

echo ""
echo "--------------------"
echo "[*] create files for shared ffmpeg"
echo "--------------------"
rm -rf $FF_PREFIX/shared
mkdir -p $FF_PREFIX/shared/lib/pkgconfig
ln -s $FF_PREFIX/include $FF_PREFIX/shared/include
ln -s $FF_PREFIX/libijkffmpeg.so $FF_PREFIX/shared/lib/libijkffmpeg.so
cp $FF_PREFIX/lib/pkgconfig/*.pc $FF_PREFIX/shared/lib/pkgconfig
for f in $FF_PREFIX/lib/pkgconfig/*.pc; do
    # in case empty dir
    if [ ! -f $f ]; then
        continue
    fi
    cp $f $FF_PREFIX/shared/lib/pkgconfig
    f=$FF_PREFIX/shared/lib/pkgconfig/`basename $f`
    # OSX sed doesn't have in-place(-i)
    # exp='s/old/new/g'
    # 示例：将所有 "foo" 替换为 "bar"
    mysedi $f 's/\/output/\/output\/shared/g'
    mysedi $f 's/-lavcodec/-lijkffmpeg/g'
    mysedi $f 's/-lavfilter/-lijkffmpeg/g'
    mysedi $f 's/-lavformat/-lijkffmpeg/g'
    mysedi $f 's/-lavutil/-lijkffmpeg/g'
    mysedi $f 's/-lswresample/-lijkffmpeg/g'
    mysedi $f 's/-lswscale/-lijkffmpeg/g'
done
