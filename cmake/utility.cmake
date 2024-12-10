# Get  version from src/version.h and put it in PRJ_VERSION
function(prj_extract_version)
  set(version_header_file "${CMAKE_CURRENT_SOURCE_DIR}/src/version.h")

  if(NOT EXISTS "${version_header_file}")
    message(FATAL_ERROR "can't read version header file: \"${version_header_file}\"")
  endif()

  file(READ ${version_header_file} file_contents)
  string(REGEX MATCH "PRJ_VER_MAJOR ([0-9]+)" _ "${file_contents}")

  if(NOT CMAKE_MATCH_COUNT EQUAL 1)
    message(FATAL_ERROR "Could not extract major version number from src/version.h")
  endif()

  set(ver_major ${CMAKE_MATCH_1})

  string(REGEX MATCH "PRJ_VER_MINOR ([0-9]+)" _ "${file_contents}")

  if(NOT CMAKE_MATCH_COUNT EQUAL 1)
    message(FATAL_ERROR "Could not extract minor version number from src/version.h")
  endif()

  set(ver_minor ${CMAKE_MATCH_1})
  string(REGEX MATCH "PRJ_VER_PATCH ([0-9]+)" _ "${file_contents}")

  if(NOT CMAKE_MATCH_COUNT EQUAL 1)
    message(FATAL_ERROR "Could not extract patch version number from src/version.h")
  endif()

  set(ver_patch ${CMAKE_MATCH_1})

  set(PRJ_VERSION_MAJOR ${ver_major} PARENT_SCOPE)
  set(PRJ_VERSION_MINOR ${ver_minor} PARENT_SCOPE)
  set(PRJ_VERSION_PATCH ${ver_patch} PARENT_SCOPE)
  set(PRJ_VERSION "${ver_major}.${ver_minor}.${ver_patch}" PARENT_SCOPE)
endfunction(prj_extract_version)

# define the debug library postfix
if(NOT DEFINED PRJ_DEBUG_POSTFIX)
  # set(PRJ_DEBUG_POSTFIX d STRING "Debug library postfix.")
  set(PRJ_DEBUG_POSTFIX "" CACHE STRING "Debug library postfix.")
endif()

# show all toolchain version
function(prj_show_toolchain_version)
  if (NOT CMAKE_CROSSCOMPILING)
    message(STATUS "we are only show toolchain version when CMAKE_CROSSCOMPILING.")
    return()
  endif()

  set(_ALL_TOOLS
    ${CMAKE_C_COMPILER}
    ${CMAKE_CXX_COMPILER}
    ${CMAKE_LINKER}
    ${CMAKE_AR}
    ${CMAKE_RANLIB}
    ${CMAKE_NM}
    ${CMAKE_OBJCOPY}
    ${CMAKE_STRIP}
  )
  
  message(STATUS "\n ============ now try show toolchain version ============ \n")
  foreach(TOOL ${_ALL_TOOLS})
    execute_process(COMMAND ${TOOL} --version
                    OUTPUT_VARIABLE TOOL_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    RESULT_VARIABLE TOOL_RESULT)
    if(NOT TOOL_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to execute ${TOOL} --version")
    endif()
    message(STATUS "${TOOL} version: ${TOOL_VERSION}")
  endforeach()
  message(STATUS "\n ============ show all toolchain version done ============ \n")
endfunction(prj_show_toolchain_version)


# Turn on warnings on the given target
function(prj_enable_warnings target_name)
  if(NOT PRJ_BUILD_WARNINGS)
    return()
  endif()

  if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    list(APPEND MSVC_OPTIONS "/W3")

    if(MSVC_VERSION GREATER 1900) # Allow non fatal security warnings for msvc 2015
      list(APPEND MSVC_OPTIONS "/WX")
    endif()
  endif()

  target_compile_options(
    ${target_name}
    PRIVATE $<$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:GNU>>:
    -Wall
    -Wextra
    -Wconversion
    -pedantic
    -Werror
    -Wfatal-errors>
    $<$<CXX_COMPILER_ID:MSVC>:${MSVC_OPTIONS}>)
endfunction(prj_enable_warnings)

# Enable address sanitizer (gcc/clang only)
function(prj_enable_sanitizer target_name)
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    message(FATAL_ERROR "sanitizer supported only for gcc/clang")
  endif()

  message(STATUS "address sanitizer enabled for \"${target_name}\"")
  target_compile_options(${target_name} PRIVATE -fsanitize=address,undefined)
  target_compile_options(${target_name} PRIVATE -fno-sanitize=signed-integer-overflow)
  target_compile_options(${target_name} PRIVATE -fno-sanitize-recover=all)
  target_compile_options(${target_name} PRIVATE -fno-omit-frame-pointer)
  target_link_libraries(${target_name} PRIVATE -fsanitize=address,undefined)

  # target_link_libraries(${target_name} PRIVATE -fsanitize=address,undefined -fuse-ld=gold)
endfunction(prj_enable_sanitizer)

# Joins arguments and places the results in ${result_var}.
function(join result_var)
  set(result "")

  foreach(arg ${ARGN})
    set(result "${result}${arg}")
  endforeach()

  set(${result_var} "${result}" PARENT_SCOPE)
endfunction(join)

# Sets a cache variable with a docstring joined from multiple arguments:
# set(<variable> <value>... CACHE <type> <docstring>...)
# This allows splitting a long docstring for readability.
function(set_verbose)
  # cmake_parse_arguments is broken in CMake 3.4 (cannot parse CACHE) so use
  # list instead.
  list(GET ARGN 0 var)
  list(REMOVE_AT ARGN 0) # var
  list(GET ARGN 0 val)
  list(REMOVE_AT ARGN 0) # val <-- attention：val must be not empty, otherwise it will cause CACHE to be val
  list(REMOVE_AT ARGN 0) # CACHE
  list(GET ARGN 0 type)
  list(REMOVE_AT ARGN 0) # type
  join(doc ${ARGN})
  set(${var} ${val} CACHE ${type} ${doc})
endfunction(set_verbose)

macro(_setup_vs_params _tgt_name)
  if(MSVC)
    if(NOT DEFINED PRJ_OUTPUT_DIR) # <-- which is deploy dir
      message(FATAL_ERROR "you must defined PRJ_OUTPUT_DIR variable first!")
    endif()
    set(_all_flags_var
            CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
            CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
            CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO
            )
    foreach (_item_flag_var ${_all_flags_var})
        if (${_item_flag_var} MATCHES "/MD")
            string(REGEX REPLACE "/MD" "/MT" ${_item_flag_var} "${${_item_flag_var}}")
        endif ()
    endforeach ()

    # message(STATUS " setup vs params for ${_tgt_name}, VS_DEBUGGER_WORKING_DIRECTORY: ${PRJ_OUTPUT_DIR}")
    set_property(TARGET ${_tgt_name} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    set_property(TARGET ${_tgt_name} PROPERTY VS_DEBUGGER_WORKING_DIRECTORY ${PRJ_OUTPUT_DIR}) # also can be "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
  endif(MSVC)
endmacro(_setup_vs_params)

macro(_setup_rpath _tgt_name)
  # 去除cmake编译时候带的环境，并重设为库所在的当前目录
  if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    SET(CMAKE_SKIP_RPATH TRUE)
    set_target_properties(${_tgt_name} PROPERTIES LINK_FLAGS "-Wl,-rpath,\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/libs")
  endif()
endmacro(_setup_rpath)

#
# batch setup properties for target: setup c/cxx standard, linker_language, rpath, vs param...
# tgt_name: the target name
#
macro(batch_setup_target_properties _tgt_name)
  if((NOT PRJ_C_STANDARD) OR(NOT PRJ_CXX_STANDARD))
    message(FATAL_ERROR "you must define \"PRJ_C_STANDARD\" and \"PRJ_CXX_STANDARD\" first!")
  endif()

  # INTERFACE libraries can't have the CXX_STANDARD property set
  # message(STATUS "setup \"${_tgt_name}\": C_STANDARD=${PRJ_C_STANDARD}, CXX_STANDARD=${PRJ_CXX_STANDARD}")
  set_property(TARGET ${_tgt_name} PROPERTY C_STANDARD ${PRJ_C_STANDARD})
  set_property(TARGET ${_tgt_name} PROPERTY C_STANDARD_REQUIRED ON)
  set_property(TARGET ${_tgt_name} PROPERTY CXX_STANDARD ${PRJ_CXX_STANDARD})
  set_property(TARGET ${_tgt_name} PROPERTY CXX_STANDARD_REQUIRED ON)

  # Linker language can be inferred from sources, but in the case of DLLs we
  # don't have any .cc files so it would be ambiguous. We could set it
  # explicitly only in the case of DLLs but, because "CXX" is always the
  # correct linker language for static or for shared libraries, we set it
  # unconditionally.
  set_property(TARGET ${_tgt_name} PROPERTY LINKER_LANGUAGE "CXX")
  _setup_vs_params(${_tgt_name})
  _setup_rpath(${_tgt_name})
endmacro(batch_setup_target_properties)

# prj_cc_library()
#
# CMake function to imitate Bazel's cc_library rule.
#
# Parameters:
# NAME: name of target (see Note)
# HDRS: List of public header files for the library
# SRCS: List of source files for the library
# DEPS: List of other libraries to be linked in to the binary targets
# COPTS: List of private compile options for C. if not provide, use PRJ_COMPILE_OPTIONS instead!
# CCOPTS: List of private compile options for CXX.
# if CCOPTS not provide:
# 1. COPTS not provide too, use PRJ_CXX_COMPILE_OPTIONS instead!
# 2. COPTS was provided, use COPTS as CXX options.
# DEFINES: List of public defines
# LINKOPTS: List of link options
# PUBLIC: Add this so that this library will be exported under ${CMAKE_PROJECT_NAME}::
# Also in IDE, target will appear in ${CMAKE_PROJECT_NAME} folder while non PUBLIC will be in ${CMAKE_PROJECT_NAME}/internal.
# TESTONLY: When added, this target will only be built if BUILD_TESTING=ON.
#
# Note:
# By default, prj_cc_library will always create a library named ${CMAKE_PROJECT_NAME}_${NAME},
# and alias target ${CMAKE_PROJECT_NAME}::${NAME}.
# eg. The ${CMAKE_PROJECT_NAME}::form should always be used.
# This is to reduce namespace pollution.
#
# prj_cc_library(
# NAME
# awesome
# HDRS
# "a.h"
# SRCS
# "a.cc"
# )
# prj_cc_library(
# NAME
# fantastic_lib
# SRCS
# "b.cc"
# DEPS
# ${CMAKE_PROJECT_NAME}::awesome # not "awesome" !
# PUBLIC
# )
#
# prj_cc_library(
# NAME
# main_lib
# ...
# DEPS
# ${CMAKE_PROJECT_NAME}::fantastic_lib
# )
#
# TODO: Implement "ALWAYSLINK"
function(prj_cc_library)
  cmake_parse_arguments(PRJ_CC_LIB
    "DISABLE_INSTALL;PUBLIC;TESTONLY"
    "NAME"
    "HDRS;SRCS;COPTS;CCOPTS;DEFINES;LINKOPTS;DEPS"
    ${ARGN}
  )

  if(PRJ_CC_LIB_TESTONLY AND NOT PRJ_BUILD_TESTS)
    return()
  endif()

  if(PRJ_ENABLE_INSTALL)
    set(_NAME "${PRJ_CC_LIB_NAME}")
  else()
    if("${PRJ_CC_LIB_NAME}" MATCHES "${CMAKE_PROJECT_NAME}") # <== we are not going to repeat the CMAKE_PROJECT_NAME
      set(_NAME "${PRJ_CC_LIB_NAME}")
    else()
      set(_NAME "${CMAKE_PROJECT_NAME}_${PRJ_CC_LIB_NAME}")
    endif()
  endif(PRJ_ENABLE_INSTALL)

  # Check if this is a header-only library
  # Note that as of February 2019, many popular OS's (for example, Ubuntu
  # 16.04 LTS) only come with cmake 3.5 by default.  For this reason, we can't
  # use list(FILTER...)
  set(PRJ_CC_SRCS "${PRJ_CC_LIB_SRCS}")

  foreach(src_file IN LISTS PRJ_CC_SRCS)
    if(${src_file} MATCHES ".*\\.(h|inc|in)")
      list(REMOVE_ITEM PRJ_CC_SRCS "${src_file}")
    endif()
  endforeach()

  if(PRJ_CC_SRCS STREQUAL "")
    set(PRJ_CC_LIB_IS_INTERFACE 1)
  else()
    set(PRJ_CC_LIB_IS_INTERFACE 0)
  endif()

  if(PRJ_BUILD_SHARED OR BUILD_SHARED_LIBS)
    set(_lib_type "SHARED")

    if(PRJ_BUILD_ALL_IN_ONE AND(NOT _NAME STREQUAL "${CMAKE_PROJECT_NAME}"))
      set(_lib_type "STATIC")
      message(STATUS "PRJ_BUILD_ALL_IN_ONE is ON, let \"${_NAME}\" lib_type change to ${_lib_type}, for \"${CMAKE_PROJECT_NAME}\" to include it.")
    endif()
  else()
    set(_lib_type "STATIC")
  endif()

  if(PRJ_MINIMIZE)
    list(APPEND PRJ_CC_LIB_DEFINES "PRJ_MINIMIZE")
  endif()

  if(NOT PRJ_CC_LIB_IS_INTERFACE)
    if(_lib_type STREQUAL "STATIC" OR _lib_type STREQUAL "SHARED")
      # add_library(${_NAME} "") # <-- 如果不显式的设置库类型，那么库的类型由 BUILD_SHARED_LIBS 这个开关来控制，ON则为SHARED
      add_library(${_NAME} ${_lib_type} "") # <-- 无视 BUILD_SHARED_LIBS 开关，自行控制库的编译类型
      target_sources(${_NAME} PRIVATE ${PRJ_CC_LIB_SRCS} ${PRJ_CC_LIB_HDRS})
      target_link_libraries(${_NAME}
        PUBLIC ${PRJ_CC_LIB_DEPS}
        PRIVATE
        ${PRJ_CC_LIB_LINKOPTS}
        ${PRJ_DEFAULT_LINKOPTS}
      )
    else()
      message(FATAL_ERROR "invalid lib type: ${_lib_type}, should be \"STATIC\" or \"SHARED\"")
    endif()

    if(NOT DEFINED PRJ_SOURCE_DIR)
      message(FATAL_ERROR "you must define PRJ_SOURCE_DIR first. eg. set(PRJ_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}) on root CMakeLists.txt of project")
    endif()

    # add current dir to include directories
    list(APPEND PRJ_CC_LIB_HDRS ${CMAKE_CURRENT_SOURCE_DIR})
    list(REMOVE_DUPLICATES PRJ_CC_LIB_HDRS) # <-- remove duplicates

    # message(STATUS "target: ${_NAME}: HDRS => ${PRJ_CC_LIB_HDRS}")
    target_include_directories(${_NAME}
      PUBLIC
      ${PRJ_CC_LIB_HDRS} # add custom headers
      $<BUILD_INTERFACE:${PRJ_SOURCE_DIR}/> # PRJ_SOURCE_DIR is defined by ourself, which on root CMakeLists.txt.

      # $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/> # PROJECT_SOURCE_DIR is the dir which CMakeLists.txt declare project(xxxx)
      $<INSTALL_INTERFACE:${PRJ_INC_DIR}>
    )

    # auto detect compile options for target
    # use PRJ_COMPILE_OPTIONS and PRJ_CXX_COMPILE_OPTIONS if OPTS not provided.
    if((NOT PRJ_CC_LIB_COPTS) AND PRJ_COMPILE_OPTIONS)
      message(STATUS "  detect COPTS not defined, use PRJ_COMPILE_OPTIONS instead.")
      set(PRJ_CC_LIB_COPTS ${PRJ_COMPILE_OPTIONS})
    endif()

    if((NOT PRJ_CC_LIB_CCOPTS) AND PRJ_CXX_COMPILE_OPTIONS)
      message(STATUS "  detect CCOPTS not defined, use PRJ_CXX_COMPILE_OPTIONS instead.")
      set(PRJ_CC_LIB_CCOPTS ${PRJ_CXX_COMPILE_OPTIONS})
    endif()

    if(PRJ_CC_LIB_CCOPTS)
      # 获取当前target的编译参数
      get_target_property(TARGET_COMPILE_OPTIONS ${_NAME} COMPILE_OPTIONS)

      # message(STATUS "  \"${_NAME}\" COMPILE_OPTIONS=${COMPILE_OPTIONS}")
      # 设置C源文件的编译选项
      set_property(TARGET ${_NAME} APPEND PROPERTY COMPILE_OPTIONS $<$<COMPILE_LANGUAGE:C>:${PRJ_CC_LIB_COPTS}>)

      # 设置C++源文件的编译选项
      set_property(TARGET ${_NAME} APPEND PROPERTY COMPILE_OPTIONS $<$<COMPILE_LANGUAGE:CXX>:${PRJ_CC_LIB_CCOPTS}>)
    else()
      target_compile_options(${_NAME} PRIVATE ${PRJ_CC_LIB_COPTS})
    endif(PRJ_CC_LIB_CCOPTS)

    if(PRJ_CC_LIB_DEFINES)
      message(STATUS "  setup definitions for ${_NAME}")
      target_compile_definitions(${_NAME} PUBLIC ${PRJ_CC_LIB_DEFINES})
    endif()

    if(PRJ_SANITIZE_ADDRESS)
      prj_enable_sanitizer(${_NAME})
    endif()

    # Add all prj targets to a a folder in the IDE for organization.
    if(PRJ_CC_LIB_PUBLIC)
      set_property(TARGET ${_NAME} PROPERTY FOLDER ${PRJ_IDE_FOLDER})
    elseif(PRJ_CC_LIB_TESTONLY)
      set_property(TARGET ${_NAME} PROPERTY FOLDER ${PRJ_IDE_FOLDER}/test)
    else()
      set_property(TARGET ${_NAME} PROPERTY FOLDER ${PRJ_IDE_FOLDER}/internal)
    endif()

    # INTERFACE libraries can't have the CXX_STANDARD property set
    batch_setup_target_properties(${_NAME})

    # When being installed, we lose the ${CMAKE_PROJECT_NAME}_ prefix.  We want to put it back
    # to have properly named lib files.  This is a no-op when we are not being installed.
    if(PRJ_ENABLE_INSTALL)
      set_target_properties(${_NAME} PROPERTIES
        OUTPUT_NAME "${CMAKE_PROJECT_NAME}_${_NAME}"
        SOVERSION 0
      )
    endif()

    set_target_properties(${_NAME} PROPERTIES
      DEBUG_POSTFIX "${PRJ_DEBUG_POSTFIX}")

    if(PRJ_ENABLE_SOVERSION)
      set(_SO_VER 0)

      if(DEFINED PRJ_VERSION_MAJOR)
        set(_SO_VER ${PRJ_VERSION_MAJOR})
      endif()

      set_target_properties(${_NAME} PROPERTIES
        VERSION ${PROJECT_VERSION}
        SOVERSION ${_SO_VER}
        OUTPUT_NAME ${_NAME})
      
      # if ((NOT CYGWIN) AND UNIX AND (_lib_type STREQUAL "SHARED"))
      #   set(_GENERATE_SO_NAME "${CMAKE_SHARED_LIBRARY_PREFIX}${_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}")
      #   message(STATUS "_GENERATE_SO_NAME=${_GENERATE_SO_NAME}")
      #   set_target_properties(${_NAME} PROPERTIES LINK_FLAGS "-Wl,-soname,${_GENERATE_SO_NAME}")
      # endif()
    endif(PRJ_ENABLE_SOVERSION)

    message(STATUS "target: ${_NAME} ${_lib_type}")

  else()
    # Generating header-only library
    add_library(${_NAME} INTERFACE)
    target_include_directories(${_NAME}
      INTERFACE
      $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/>
      $<INSTALL_INTERFACE:${PRJ_INC_DIR}>
    )

    target_link_libraries(${_NAME}
      INTERFACE
      ${PRJ_CC_LIB_DEPS}
      ${PRJ_CC_LIB_LINKOPTS}
      ${PRJ_DEFAULT_LINKOPTS}
    )
    target_compile_definitions(${_NAME} INTERFACE ${PRJ_CC_LIB_DEFINES})

    message(STATUS "target: ${_NAME} interface")
  endif(NOT PRJ_CC_LIB_IS_INTERFACE)

  target_compile_features(${_NAME} INTERFACE ${PRJ_REQUIRED_FEATURES})

  if(NOT PRJ_CC_LIB_TESTONLY AND PRJ_ENABLE_INSTALL)
    install(TARGETS ${_NAME} EXPORT ${PROJECT_NAME}Targets
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
  endif()

  # setup library alias
  add_library(${CMAKE_PROJECT_NAME}::${PRJ_CC_LIB_NAME} ALIAS ${_NAME})
endfunction(prj_cc_library)

# prj_cc_test()
#
# CMake function to imitate Bazel's cc_test rule.
#
# Parameters:
# NAME: name of target (see Usage below)
# SRCS: List of source files for the binary
# DEPS: List of other libraries to be linked in to the binary targets
# COPTS: List of private compile options
# DEFINES: List of public defines
# LINKOPTS: List of link options
#
# Note:
# By default, prj_cc_test will always create a binary named ${CMAKE_PROJECT_NAME}_${NAME}.
# This will also add it to ctest list as ${CMAKE_PROJECT_NAME}_${NAME}.
#
# Usage:
# prj_cc_library(
# NAME
# awesome
# HDRS
# "a.h"
# SRCS
# "a.cc"
# PUBLIC
# )
#
# prj_cc_test(
# NAME
# awesome_test
# HDRS
# SRCS
# "awesome_test.cc"
# DEPS
# ${CMAKE_PROJECT_NAME}::awesome
# gmock
# gtest_main
# )
function(prj_cc_test)
  if(NOT PRJ_BUILD_TESTS)
    return()
  endif()

  cmake_parse_arguments(PRJ_CC_TEST
    ""
    "NAME"
    "HDRS;SRCS;COPTS;DEFINES;LINKOPTS;DEPS"
    ${ARGN}
  )

  set(_NAME "${CMAKE_PROJECT_NAME}_${PRJ_CC_TEST_NAME}")

  add_executable(${_NAME} "")
  target_sources(${_NAME} PRIVATE ${PRJ_CC_TEST_SRCS})
  target_include_directories(${_NAME}
    PUBLIC ${PRJ_COMMON_INCLUDE_DIRS} ${PRJ_CC_TEST_HDRS}
    PRIVATE ${GMOCK_INCLUDE_DIRS} ${GTEST_INCLUDE_DIRS}
  )

  if(PRJ_CC_TEST_DEFINES)
    target_compile_definitions(${_NAME} PUBLIC ${PRJ_CC_TEST_DEFINES})
  endif()

  if(PRJ_CC_TEST_COPTS)
    target_compile_options(${_NAME} PRIVATE ${PRJ_CC_TEST_COPTS})
  endif()

  if(PRJ_SANITIZE_ADDRESS)
    prj_enable_sanitizer(${_NAME})
  endif()

  target_link_libraries(${_NAME}
    PUBLIC ${PRJ_CC_TEST_DEPS}
    PRIVATE ${PRJ_CC_TEST_LINKOPTS}
  )

  # Add all targets to a folder in the IDE for organization.
  set_property(TARGET ${_NAME} PROPERTY FOLDER ${PRJ_IDE_FOLDER}/test)

  batch_setup_target_properties(${_NAME})

  add_test(NAME ${_NAME} COMMAND ${_NAME})

  # setup executable alias
  add_executable(${CMAKE_PROJECT_NAME}::${PRJ_CC_TEST_NAME} ALIAS ${_NAME})
  message(STATUS "${CMAKE_PROJECT_NAME}::${PRJ_CC_TEST_NAME} ALIAS ${_NAME}")

  message(STATUS "target: ${_NAME} executable(test)")
endfunction(prj_cc_test)
