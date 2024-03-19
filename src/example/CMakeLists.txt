
prj_cc_test(
  NAME
    demo
  HDRS
  SRCS
    "demo.c"
  COPTS
    ${PRJ_COMPILE_OPTIONS}
  DEPS
    #${CMAKE_PROJECT_NAME}::all
    ${CMAKE_PROJECT_NAME} # <-- PRJ_BUILD_ALL_IN_ONE
  PUBLIC
)

#if(PRJ_BUILD_TESTS) 
#  add_executable(check_config "check_config.cpp")
#  target_compile_options(check_config PRIVATE ${PRJ_COMPILE_OPTIONS})
#  target_link_libraries(check_config ${CMAKE_PROJECT_NAME}::all)
#  add_test(NAME check_config COMMAND check_config "${CMAKE_SOURCE_DIR}/tests/config/" "../tests_out/config")
#
#  add_executable(json_checker "json_checker.cpp")
#  target_compile_options(json_checker PRIVATE ${PRJ_COMPILE_OPTIONS})
#  target_link_libraries(json_checker ${CMAKE_PROJECT_NAME}::all)
#  add_test(NAME json_checker COMMAND json_checker "${CMAKE_SOURCE_DIR}/tests/json_checker/" "../tests_out/json_checker")
#
#  add_executable(config_performance "config_performance.cpp")
#  target_compile_options(config_performance PRIVATE ${PRJ_COMPILE_OPTIONS})
#  target_link_libraries(config_performance ${CMAKE_PROJECT_NAME}::all)
#  add_test(NAME config_performance COMMAND config_performance "${CMAKE_SOURCE_DIR}/tests/config_performance/" "../tests_out/config_performance")
#endif()