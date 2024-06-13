#file(GLOB_RECURSE HEADERS "*.h" "*.hpp")

#
# ---------------------------------------------------------------------------------------
# find lcu lib.
#   param: ${PRJ_THIRD_LIB_SHARED} 代表第三方库是否引用其动态库，OFF则引用其静态库
# ---------------------------------------------------------------------------------------
# 
#find_lib_easy("lcu" ${PRJ_THIRD_LIB_SHARED} ${PRJ_THIRD_PARTY_DIR}/lcu)
# 也可以直接include cmake文件，在里面写查找库脚本
include(${PRJ_THIRD_PARTY_DIR}/lcu/find_me.cmake)
message(STATUS "common show: lcu-lib=${lcu-lib}, lcu-inc=${lcu-inc}, lcu-asset=${lcu-asset}")

# find socket lib
set(socket-lib "")
if(MSVC)
  set(socket-lib "ws2_32")
endif(MSVC)

prj_cc_library(
  NAME
    common
  HDRS
    #${HEADERS}
    ${PRJ_COMMON_INCLUDE_DIRS} # which is "${PRJ_SOURCE_DIR}/src": include "src" dir. for module which depend on this module to use it
    ${lcu-inc}
  SRCS
    "common.c"
  COPTS
    # ${PRJ_COMPILE_OPTIONS}
  DEPS
    ${lcu-lib}
    ${socket-lib}
	#${PRJ_DEPENDS_LOG}
  PUBLIC
)

prj_cc_test(
 NAME
   common_test
 HDRS
  #  ${HEADERS}
 SRCS
   "common_test.c"
 COPTS
  #  ${PRJ_COMPILE_OPTIONS}
 DEPS
   ${CMAKE_PROJECT_NAME}::common
 PUBLIC
)
