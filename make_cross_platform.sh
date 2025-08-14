#!/bin/bash
# Attention: Unix sh file shouldn't use CR LF, just use LF

# use dos2unix to transform it
DOS2UNIX=dos2unix
$DOS2UNIX -V > /dev/null 2>&1
ERR_CODE=$?
if [ $ERR_CODE -eq 0 ];then
    $DOS2UNIX setup_env.sh
else
    echo "$DOS2UNIX not exists. you should install it by \"apt install dos2unix\""
fi
chmod +x ./setup_env.sh
source ./setup_env.sh 

BUILD_DIR="./tool/build/build_${PLATFORM}"
if [[ "$BUILD_ABI" != "" ]];then
  BUILD_DIR+="_${BUILD_ABI}"
fi  

if [ ! -d "$BUILD_DIR" ];then
	echo "mkdir \"${BUILD_DIR}\""
	mkdir -p "${BUILD_DIR}"
else 
	echo "\"${BUILD_DIR}\" already exist, clean it up."
	rm -rf "${BUILD_DIR}"/*
fi

cmake -H./  -B"$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "${CMAKE_EXTEND_ARGS[@]}"             \
                        -DPLATFORM=$PLATFORM -DBUILD_SHARED_LIBS=ON -DPRJ_BUILD_ALL_IN_ONE=ON -DPRJ_BUILD_TESTS=ON

ERR_CODE=$?
if [ $ERR_CODE -ne 0 ];then
    echo "  Error on generate project, ERR=$ERR_CODE  "       
    exit $ERR_CODE   
fi 

cmake --build $BUILD_DIR --config $BUILD_TYPE -- -j12
ERR_CODE=$?
if [ $ERR_CODE -ne 0 ];then
    echo "  Error on build $BUILD_ABI $BUILD_TYPE, ERR=$ERR_CODE  " 
    exit $ERR_CODE
fi
echo -e "\n...Build ${PLATFORM} ${BUILD_ABI} ${BUILD_TYPE} finished($ERR_CODE)...\n"
