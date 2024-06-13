#file(GLOB_RECURSE HEADERS "*.h" "*.hpp")

prj_cc_library(
  NAME
    api
  HDRS
    #${HEADERS}
  SRCS
    "my_api.c" 
    "my_api_legacy.c"
  COPTS
    # ${PRJ_COMPILE_OPTIONS}
  DEPS
    ${CMAKE_PROJECT_NAME}::common
  PUBLIC
)

#prj_cc_test(
#  NAME
#    api_test
#  HDRS
#    ${HEADERS}
#  SRCS
#    "api_test.c"
#  COPTS
#    ${PRJ_COMPILE_OPTIONS}
#  DEPS
#    ${CMAKE_PROJECT_NAME}::api
#  PUBLIC
#)