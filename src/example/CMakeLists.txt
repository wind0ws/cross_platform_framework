
set(MODULE_NAME example)

set(_HDRS  "${CMAKE_CURRENT_LIST_DIR}/include")
set(_SRCS  "${CMAKE_CURRENT_LIST_DIR}/src/log/slog.c"
           "${CMAKE_CURRENT_LIST_DIR}/example.c")

set(_DEPENDS_LIB  "")
if (UNIX)
  find_package(Threads REQUIRED)
  list(APPEND _DEPENDS_LIB ${CMAKE_THREAD_LIBS_INIT})
  if (ANDROID)
    list(APPEND _DEPENDS_LIB log) # <-- 依赖 android log 打印库
  endif(ANDROID)
endif (UNIX)

prj_cc_test(
  NAME
    ${MODULE_NAME}
  HDRS
    ${_HDRS}
  SRCS
    ${_SRCS}
  COPTS
    ${PRJ_COMPILE_OPTIONS}
  DEPS
    ${_DEPENDS_LIB}
    #${CMAKE_PROJECT_NAME}::all
    #${CMAKE_PROJECT_NAME} # <-- PRJ_BUILD_ALL_IN_ONE
  PUBLIC
)

if(PRJ_BUILD_TESTS)
  if(MSVC)
    # VS_STARTUP_PROJECT not support alias target, so find the real name first.
    get_target_property(_startup_tgt_name ${CMAKE_PROJECT_NAME}::example ALIASED_TARGET)
    #set vs startup project. 
    set_property(DIRECTORY ${PRJ_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${_startup_tgt_name})
    message(STATUS "  set startup project:  ${_startup_tgt_name}")
  endif(MSVC)
endif(PRJ_BUILD_TESTS)

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
