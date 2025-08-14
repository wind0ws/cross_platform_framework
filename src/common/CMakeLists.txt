
set(MODULE_NAME "common")

#
# ---------------------------------------------------------------------------------------
# find lcu lib.
#   param: ${PRJ_THIRD_LIB_SHARED} 代表第三方库是否引用其动态库，OFF则引用其静态库
# ---------------------------------------------------------------------------------------
# 
#find_lib_easy("lcu" ${PRJ_THIRD_LIB_SHARED} ${PRJ_THIRD_PARTY_DIR}/lcu)
# 也可以直接include cmake文件，在里面写查找库脚本
include(${PRJ_THIRD_PARTY_DIR}/lcu/find_me.cmake)
message(STATUS "${MODULE_NAME} show: ${_LIB_NAME}-lib=${${_LIB_NAME}-lib}, ${_LIB_NAME}-inc=${${_LIB_NAME}-inc}, ${_LIB_NAME}-asset=${${_LIB_NAME}-asset}")

set(_DEPS ${${_LIB_NAME}-lib})
if(MSVC)
  list(APPEND _DEPS "ws2_32")
endif(MSVC)

set(_SRCS "my_common.c"
  "my_sched.c"
  "my_cjson.c"
  "global_func_impl.c")
  
set(_HDRS ${PRJ_COMMON_INCLUDE_DIRS} # which is "${PRJ_SOURCE_DIR}/src": include "src" dir. for module which depend on this module to use it
  ${${_LIB_NAME}-inc})


prj_cc_library(
  NAME
    ${MODULE_NAME}
  HDRS
    ${_HDRS}
  SRCS
    ${_SRCS}
  COPTS
    # ${PRJ_COMPILE_OPTIONS}
  DEFINES
    # _LCU_MEM_CHECK_FEATURE_ENABLE=0
  DEPS
    ${_DEPS}
  PUBLIC
)

prj_cc_test(
 NAME
   ${MODULE_NAME}_test
 HDRS
  #  ${HEADERS}
 SRCS
   "common_test.c"
 COPTS
  #  ${PRJ_COMPILE_OPTIONS}
 DEPS
   ${CMAKE_PROJECT_NAME}::${MODULE_NAME}
 PUBLIC
)
