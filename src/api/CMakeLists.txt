
set(MODULE_NAME "api")

prj_cc_library(
  NAME
    ${MODULE_NAME}
  HDRS
    #${HEADERS}
  SRCS
    "my_api.cpp" 
  COPTS
    # ${PRJ_COMPILE_OPTIONS}
  DEPS
    ${CMAKE_PROJECT_NAME}::common
  DEFINES
  PUBLIC
)

#prj_cc_test(
#  NAME
#    ${MODULE_NAME}_test
#  HDRS
#    ${HEADERS}
#  SRCS
#    "api_test.c"
#  COPTS
#    ${PRJ_COMPILE_OPTIONS}
#  DEPS
#    ${CMAKE_PROJECT_NAME}::${MODULE_NAME}
#  PUBLIC
#)
