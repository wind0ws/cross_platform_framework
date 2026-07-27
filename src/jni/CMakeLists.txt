if (ANDROID)

set(MODULE_NAME "jni")

prj_cc_library(
  NAME
      ${MODULE_NAME}
  HDRS
    #${HEADERS}
  SRCS
    "jni_entrance.c" 
    "jni_my_api.c" 
  COPTS
    # ${PRJ_COMPILE_OPTIONS}
  DEPS
    ${CMAKE_PROJECT_NAME}::api
  PUBLIC
)

endif(ANDROID)
