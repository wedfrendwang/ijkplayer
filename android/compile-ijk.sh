#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Bilibili
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

# # 这里脚本有点问题，应用是NDK 和 SDK的路径
if [ -z "$ANDROID_NDK" -o -z "$ANDROID_NDK" ]; then
    echo "You must define ANDROID_NDK, ANDROID_SDK before starting."
    echo "They must point to your NDK and SDK directories.\n"
    exit 1
fi

REQUEST_TARGET=$1
REQUEST_SUB_CMD=$2
ACT_ABI_32="armv5 armv7a x86"
ACT_ABI_64="armv5 armv7a arm64 x86 x86_64"
ACT_ABI_ALL=$ACT_ABI_64
UNAME_S=$(uname -s)

FF_MAKEFLAGS=
if which nproc >/dev/null
then
    FF_MAKEFLAGS=-j`nproc` # nproc命令来获取CPU核心数
elif [ "$UNAME_S" = "Darwin" ] && which sysctl >/dev/null
then
    FF_MAKEFLAGS=-j`sysctl -n machdep.cpu.thread_count`
fi



    # 当在模块目录运行 ndk-build（脚本 compile-ijk.sh 在每个模块的 src/main/jni 里调用 $ANDROID_NDK/ndk-build），ndk-build 会生成两个常见位置：

    # 中间目标（object）存放：

    # obj/local/<ABI>/ 下会包含中间目标和链接产生的临时文件（例如 obj/local/armeabi-v7a/objs/ijkplayer/...）。
    # 这些是编译过程的中间产物。
    # 最终库（供 APK 使用）：

    # libs/<ABI>/libijkplayer.so（或在 Gradle 项目中是 src/main/libs/<ABI>/libijkplayer.so 或 later src/main/jniLibs/<ABI>/libijkplayer.so）
    # 以你的项目路径为基准，假设你在 ijkplayer 模块中运行 ndk-build（脚本是 cd .../src/main/jni 然后运行 ndk-build），最终 libijkplayer.so 通常会出现在模块目录的上一级 libs 目录，完整示例：
    # d:\TCL_AS_APP\ijkplayer\ijkmedia\ijkplayer\libs\armeabi-v7a\libijkplayer.so
    # 同时中间文件 obj/local/armeabi-v7a/libijkplayer.so（或者类似路径 obj/local/armeabi-v7a/objs/...）也会存在。
    # 具体到你的仓库布局（常见）：

    # 如果你运行脚本 compile-ijk.sh，脚本会 cd 到每个模块的 src/main/jni 并执行 $ANDROID_NDK/ndk-build，因此输出一般位于模块目录的父目录 libs/<ABI>/，例如：
    # d:\TCL_AS_APP\ijkplayer\android\ijkplayer\ijkplayer-armv7a\libs\armeabi-v7a\libijkplayer.so
    # 如果 Gradle/Android Studio 被用来构建，则最终的 .so 将被复制或打包到 APK 的 lib/<ABI>/libijkplayer.so 中。


    # ndk-build 的行为（简化）：
    # ndk-build 会解析所有包含到构建中的 Android.mk，建立模块依赖图（LOCAL_SHARED_LIBRARIES / LOCAL_STATIC_LIBRARIES / import-module 等形成依赖关系）。
    # 当构建 ijkplayer（其 Android.mk 声明 LOCAL_SHARED_LIBRARIES := ijkffmpeg ijksdl）时，ndk-build 会确保依赖模块可用：如果 ijksdl 是源码模块（如你的仓库），ndk-build 会先编译 ijksdl（生成 libijksdl.so 的中间对象并安装到 libs/<ABI>/ 或 obj/local/<ABI>/），然后把 libijksdl.so 用于链接 libijkplayer.so。
    # 因此生成时机：在同一次 ndk-build 的执行中，libijksdl.so 会在链接 libijkplayer.so 之前由 ndk-build 自动构建——不是一个独立的、必须先手动建立的产物。

do_sub_cmd () {
    SUB_CMD=$1
    if [ -L "./android-ndk-prof" ]; then
        rm android-ndk-prof
    fi

    if [ "$PARAM_SUB_CMD" = 'prof' ]; then
        echo 'profiler build: YES';
        ln -s ../../../../../../ijkprof/android-ndk-profiler/jni android-ndk-prof
    else
        echo 'profiler build: NO';
        ln -s ../../../../../../ijkprof/android-ndk-profiler-dummy/jni android-ndk-prof
    fi

    case $SUB_CMD in
        prof)
            $ANDROID_NDK/ndk-build $FF_MAKEFLAGS
        ;;
        clean)
            $ANDROID_NDK/ndk-build clean
        ;;
        rebuild)
            $ANDROID_NDK/ndk-build clean
            $ANDROID_NDK/ndk-build $FF_MAKEFLAGS
        ;;
        *)
            $ANDROID_NDK/ndk-build $FF_MAKEFLAGS
        ;;
    esac
}

do_ndk_build () {
    PARAM_TARGET=$1
    PARAM_SUB_CMD=$2
    case "$PARAM_TARGET" in
        armv5|armv7a)
            cd "ijkplayer/ijkplayer-$PARAM_TARGET/src/main/jni"
            do_sub_cmd $PARAM_SUB_CMD
            cd -
        ;;
        arm64|x86|x86_64)
            cd "ijkplayer/ijkplayer-$PARAM_TARGET/src/main/jni"
            if [ "$PARAM_SUB_CMD" = 'prof' ]; then PARAM_SUB_CMD=''; fi
            do_sub_cmd $PARAM_SUB_CMD
            cd -
        ;;
    esac
}


case "$REQUEST_TARGET" in
    "")
        do_ndk_build armv7a;
    ;;
    armv5|armv7a|arm64|x86|x86_64)
        do_ndk_build $REQUEST_TARGET $REQUEST_SUB_CMD;
    ;;
    all32)
        for ABI in $ACT_ABI_32
        do
            do_ndk_build "$ABI" $REQUEST_SUB_CMD;
        done
    ;;
    all|all64)
        for ABI in $ACT_ABI_64
        do
            do_ndk_build "$ABI" $REQUEST_SUB_CMD;
        done
    ;;
    clean)
        for ABI in $ACT_ABI_ALL
        do
            do_ndk_build "$ABI" clean;
        done
    ;;
    *)
        echo "Usage:"
        echo "  compile-ijk.sh armv5|armv7a|arm64|x86|x86_64"
        echo "  compile-ijk.sh all|all32"
        echo "  compile-ijk.sh all64"
        echo "  compile-ijk.sh clean"
    ;;
esac

