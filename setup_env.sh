#!/bin/bash
# sh script can't use CRLF, you can use dos2unix to tranform it

echo "show cmake version:"
cmake --version
ERR_CODE=$?
echo 
if [ $ERR_CODE -ne 0 ];then
  echo "  Error on call cmake, ERR=$ERR_CODE, you should install it first!"
  exit $ERR_CODE
fi 

if [ $# -lt 2 ] ; then
  echo "Error: need more param to continue. your param count=$#"
  echo "  sample: $0 linux m64 Release"
  echo "      or: $0 rk3308 \"\" Release"
  echo "      or: $0 linux m64 Release \"-DFRONTEND_DIR_NAME=aec_es -DBACKEND_DIR_NAME=miniesr_1ch -DENABLE_WAKE_WORD_EVALUATOR=0\" "
  echo "      or: $0 rk3308 \"\" Release \"-DFRONTEND_DIR_NAME=aec_es -DBACKEND_DIR_NAME=ivw80 -DENABLE_WAKE_WORD_EVALUATOR=0\" "
  echo
  echo "     param1: PLATFORM:      linux, rk3308, r328 ..."
  echo "     param2: BUILD_ABI:     m32/m64, or just empty string(\"\") for cross platform"
  echo "     param3: BUILD_TYPE:    Debug/Release/MinSizeRel/RelWithDebInfo"
  echo "     param4: EXTEND_PARAMS: example: -DFRONTEND_DIR_NAME=aec_es -DBACKEND_DIR_NAME=miniesr_1ch -DENABLE_WAKE_WORD_EVALUATOR=0 "
  exit 1
else
  echo "param count=$#"
fi

is_valid_build_type() {  
    local str="$1"  # 获取传入的字符串  
    local list=("Debug" "Release" "MinSizeRel" "RelWithDebInfo") 
  
    for item in "${list[@]}"; do  
        if [[ "$str" == "$item" ]]; then  
            return 0  # 如果找到匹配的字符串，返回状态码0（表示True）  
        fi  
    done  
  
    return 1  # 如果没有找到匹配的字符串，返回状态码1（表示False）  
}  

# 编译的目标平台名称, 如: rk3308
PLATFORM=linux
# 编译的abi, 如: m32/m64
BUILD_ABI=
# 编译模式: Debug/Release/MinSizeRel/RelWithDebInfo
BUILD_TYPE=
# 传递给 cmake 的额外编译参数. 如: -DFOO=BAR -DTEST=1
EXTEND_ARGS=

PARAM1=$1
PARAM2=$2
# 2个参数
if [ $# -lt 3 ] ; then 
  BUILD_ABI=$PARAM1
  BUILD_TYPE=$PARAM2
  # 检查 PARAM1 参数值是不是真的是ABI，若不是则说明是交叉编译：2参数形式，第一个参数传平台类型，第二个参数传编译模式
  if [ "$PARAM1" == "m32" -o "$PARAM1" == "m64" ]; then
    echo "BUILD_ABI($BUILD_ABI) is valid"
  else
    PLATFORM=$PARAM1
	  BUILD_ABI=
	  echo "detect cross PLATFORM=${PLATFORM}"
  fi
else
  PARAM3=$3
  PLATFORM=$PARAM1
  BUILD_ABI=$PARAM2
  BUILD_TYPE=$PARAM3
  # 3个参数（可能是 PLATFORM BUILD_TYPE EXTEND_ARGS）
  if [ $# -lt 4 ] ; then
    # 若 PARAM2 是 debug/release...则说明没有传 BUILD_ABI, 
    # 则 PARAM2 是 BUILD_TYPE, 顺应着 PARAM3 是 EXTEND_ARGS
    if is_valid_build_type "$PARAM2"; then
      BUILD_ABI=
      BUILD_TYPE=$PARAM2
      EXTEND_ARGS=$PARAM3
    fi
  else
    EXTEND_ARGS=$4 
  fi
fi 

if is_valid_build_type "$BUILD_TYPE"; then
    echo "your BUILD_TYPE=$BUILD_TYPE"
else
    echo "unknown BUILD_TYPE=$BUILD_TYPE, only support Debug/Release/MinSizeRel/RelWithDebInfo"
    exit 3
fi

# 使用数组添加CMake扩展参数  
CMAKE_EXTEND_ARGS=()
# 非默认 linux 平台添加交叉编译文件
if [[ "$PLATFORM" != "linux" ]]; then
  CMAKE_EXTEND_ARGS+=(-DCMAKE_TOOLCHAIN_FILE="./cmake/toolchains/$PLATFORM.toolchain.cmake")  
fi

if [[ "${EXTEND_ARGS}" == "" ]]; then
  echo "warning: you did not provide EXTEND_ARGS, we will compile with default params!"
elif [[ $EXTEND_ARGS == -D* ]]; then  # 检查 EXTEND_ARGS 是否以 -D 开头
  # 如果以 -D 开头，则根据空格分割 EXTEND_ARGS 并追加到 CMAKE_EXTEND_ARGS
  CMAKE_EXTEND_ARGS+=($EXTEND_ARGS)
else
  echo "error: unrecognized EXTEND_ARGS=$EXTEND_ARGS"
  exit 4
fi


COMPILER_FLAGS=""
# 暂未处理交叉编译平台编译时参数，建议放到交叉编译的 toolchain 里面
if [ "${PLATFORM}" == "linux" ]; then
  echo "your BUILD_ABI=${BUILD_ABI}"
  if [ "${BUILD_ABI}" == "m32" ]; then
    COMPILER_FLAGS+=" -m32"
  elif [ "${BUILD_ABI}" == "m64" ]; then
    COMPILER_FLAGS+=" -m64"	
  else
    echo "unknown BUILD_ABI=${BUILD_ABI} on linux, only support m32/m64"
    exit 2
  fi
fi

if [[ "${COMPILER_FLAGS}" != "" ]]; then
  CMAKE_EXTEND_ARGS+=(-DCMAKE_C_FLAGS="${COMPILER_FLAGS}")  
  CMAKE_EXTEND_ARGS+=(-DCMAKE_CXX_FLAGS="${COMPILER_FLAGS}")  
  CMAKE_EXTEND_ARGS+=(-DCMAKE_SHARED_LINKER_FLAGS="${COMPILER_FLAGS}")  
  CMAKE_EXTEND_ARGS+=(-DCMAKE_EXE_LINKER_FLAGS="${COMPILER_FLAGS}")  
fi

echo 
echo =================== Your Environment ===================
echo
echo PLATFORM=$PLATFORM
echo BUILD_ABI=$BUILD_ABI
echo BUILD_TYPE=$BUILD_TYPE
echo CMAKE_EXTEND_ARGS="${CMAKE_EXTEND_ARGS[@]}" 
echo
echo ========================================================
echo 
