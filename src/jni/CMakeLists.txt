if (ANDROID)

#file(GLOB_RECURSE HEADERS "*.h" "*.hpp")

prj_cc_library(
  NAME
    jni
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

# prj_cc_test(
#  NAME
#    jni_test
#  HDRS
#   #  ${HEADERS}
#  SRCS
#    "jni_vtn_api_test.c"
#  COPTS
#   #  ${PRJ_COMPILE_OPTIONS}
#  DEPS
#    ${CMAKE_PROJECT_NAME}::jni
#  PUBLIC
# )

endif(ANDROID)
