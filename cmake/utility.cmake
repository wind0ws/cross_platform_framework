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
  set(PRJ_DEBUG_POSTFIX "" CACHE STRING "Debug library postfix.")
endif()

# show all toolchain version
function(prj_show_toolchain_version)
  if(NOT CMAKE_CROSSCOMPILING)
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

    if(MSVC_VERSION VERSION_GREATER 1900) # Allow non fatal security warnings for msvc 2015
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

# copy asan dll for ${target_name} in msvc
function(_msvc_auto_copy_asan_dll target_name)
  if(NOT MSVC)
    message(FATAL_ERROR "this function only for MSVC compiler")
    return()
  endif()

  # 自动查找并复制 ASan DLL 到输出目录
  get_filename_component(VC_COMPILER_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)

  if(CMAKE_SIZEOF_VOID_P EQUAL 8) # 64位系统
    set(ASAN_DLL_NAME "clang_rt.asan_dynamic-x86_64.dll")
  else() # 32位系统
    set(ASAN_DLL_NAME "clang_rt.asan_dynamic-i386.dll")
  endif()

  set(ASAN_DLL_PATH "${VC_COMPILER_DIR}/${ASAN_DLL_NAME}")

  if(EXISTS "${ASAN_DLL_PATH}")
    add_custom_command(TARGET ${target_name} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${ASAN_DLL_PATH}"
      "$<TARGET_FILE_DIR:${target_name}>"
      COMMENT "Copying ASan DLL to output directory"
    )
  else()
    message(WARNING "ASan DLL not found at ${ASAN_DLL_PATH}")
  endif()
endfunction(_msvc_auto_copy_asan_dll target_name)

# 获取Android NDK主版本号
macro(_get_ndk_major_version ndk_major_ver)
  if(NOT ANDROID)
    message(FATAL_ERROR "this macro only for android NDK")
  endif()

  # 在全局作用域缓存NDK主版本号
  if(NOT DEFINED PRJ_NDK_MAJOR_VERSION_CACHED)
    if(DEFINED CMAKE_ANDROID_NDK_VERSION)
      string(REGEX MATCH "^([0-9]+)" _match_result "${CMAKE_ANDROID_NDK_VERSION}")

      if(_match_result)
        set(PRJ_NDK_MAJOR_VERSION_CACHED "${CMAKE_MATCH_1}" CACHE INTERNAL "Cached NDK major version")
      else()
        set(PRJ_NDK_MAJOR_VERSION_CACHED "16" CACHE INTERNAL "Cached NDK major version (default)")
      endif()
    else()
      set(PRJ_NDK_MAJOR_VERSION_CACHED "16" CACHE INTERNAL "Cached NDK major version (default)")
    endif()
  endif()

  set(${ndk_major_ver} ${PRJ_NDK_MAJOR_VERSION_CACHED})
endmacro(_get_ndk_major_version)

function(prj_enable_sanitizer target_name)
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang|MSVC")
    message(FATAL_ERROR "ASan supported only for gcc/clang/msvc")
  endif()

  if(MSVC AND("${MSVC_VERSION}" VERSION_LESS "1929"))
    message(STATUS "ASan begin supported from msvc 2019(16.9), but yours MSVC_VERSION=${MSVC_VERSION}, so disabled ASan.")
    return()
  endif()

  ## 如果你用到某个第三方库, 且 ASan 报了一些错误你没法修正, 可以对特定源文件关闭 ASan(sanitizer) vptr 检测.
  ## set_source_files_properties(${_SRC_DIR}/xxx_api_wrapper.cpp PROPERTIES COMPILE_FLAGS "-fno-sanitize=vptr")
  
  message(STATUS " ASan enabled for \"${target_name}\"")

  if(MSVC)
    # 注释不要写在内部行后面
    #  Oy- 等效于 -fno-omit-frame-pointer
    target_compile_options(${target_name} PRIVATE
      /fsanitize=address
      /Oy-
    )
    # 1. 这里的 fsanitize:address 而不是 fsanitize=address
    # 2. /INFERASANLIBS 是自动推断 ASANLib 位置
    # 3. /INCREMENTAL:NO 是禁用增量链接, ASan不支持
    # 4. /NODEFAULTLIB:LIBCMT # <-- 不能加这个参数, 加了ASan会失效, 可以 ignore:4098
    target_link_options(${target_name} PRIVATE
      /fsanitize:address
      /INFERASANLIBS
      /INCREMENTAL:NO
    )
    _msvc_auto_copy_asan_dll(${target_name})
  else()
    set(_NDK_MAJOR_VERSION 16) # <-- 非Android平台设置多少都无所谓, 只有Android平台才会读这个

    if(ANDROID)
      _get_ndk_major_version(_NDK_MAJOR_VERSION)
    endif()

    if(ANDROID AND _NDK_MAJOR_VERSION LESS 21)
      set(SANITIZE_FLAGS "-fsanitize=address") # <-- Android NDK 21 以下版本不支持 sanitize undefined 参数
    else()
      set(SANITIZE_FLAGS "-fsanitize=address,undefined")
    endif()

    list(APPEND SANITIZE_FLAGS
      -fno-sanitize=signed-integer-overflow
      -fno-sanitize-recover=all
      -fno-omit-frame-pointer)

    target_compile_options(${target_name} PRIVATE
      ${SANITIZE_FLAGS}
    )
    target_link_options(${target_name} PRIVATE
      ${SANITIZE_FLAGS}
    )
  endif()
endfunction(prj_enable_sanitizer)

# 检测当前工具链是否支持 IPO/LTO，结果缓存到 PRJ_IPO_SUPPORTED_CACHED（每种工具链只检测一次）。
# 使用 check_ipo_supported 的 RESULT 形式：不支持时只置为 NO，不会 fatal error，
# 从而避免 CMP0069=NEW 下直接设置 IPO 属性导致交叉编译（如 linaro/uclibc）在 generate 阶段报错。
macro(_prj_check_ipo_supported _result_var)
  if(NOT DEFINED PRJ_IPO_SUPPORTED_CACHED)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT _ipo_ok OUTPUT _ipo_output LANGUAGES C CXX)

    if(_ipo_ok)
      set(PRJ_IPO_SUPPORTED_CACHED ON CACHE INTERNAL "IPO/LTO supported by toolchain")
      message(STATUS "IPO/LTO supported: will enable for shared libs in non-Debug build.")
    else()
      set(PRJ_IPO_SUPPORTED_CACHED OFF CACHE INTERNAL "IPO/LTO supported by toolchain")
      message(STATUS "IPO/LTO not supported by toolchain, skip: ${_ipo_output}")
    endif()
  endif()

  set(${_result_var} ${PRJ_IPO_SUPPORTED_CACHED})
endmacro(_prj_check_ipo_supported)

# 精简动态库产物体积：对动态库开启 IPO/LTO，并按 PRJ_STRIP_SHARED_LIB_MODE 在链接期 strip 符号。
# 两项都只对 _lib_type=SHARED 生效。
#
# 1) IPO/LTO：仅非 Debug 且非 ASAN 时开启，用 per-config 属性 INTERPROCEDURAL_OPTIMIZATION_<CONFIG>。
#    工具链不支持 LTO 时经 check_ipo_supported 自动跳过（避免 CMP0069=NEW 下 generate 报错）。
# 2) strip：由 PRJ_STRIP_SHARED_LIB_MODE(none|debug|all) 控制，其默认值已按构建类型编码
#    （Debug=none 保留全部符号供排查，非 Debug=all 彻底精简），也可编译传参覆盖。
#    - debug: --strip-debug 去 DWARF 调试段(实测占 .so 约 89%)，保留 .symtab 供崩溃回溯。
#    - all  : --strip-all 连符号表一并去掉，产物最小。
#    - ASAN 构建强制不 strip（诊断需要符号）；MSVC 无 --strip-* 标志，跳过。
function(_prj_optimize_shared_lib _tgt_name _lib_type)
  if(NOT _lib_type STREQUAL "SHARED")
    return()
  endif()

  # --- IPO/LTO：仅非 Debug、非 ASAN ---
  string(TOUPPER "${CMAKE_BUILD_TYPE}" _build_type_upper)

  if(NOT PRJ_ENABLE_ASAN AND NOT _build_type_upper STREQUAL "DEBUG")
    _prj_check_ipo_supported(_ipo_ok)

    if(_ipo_ok)
      set_property(TARGET ${_tgt_name} PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
      set_property(TARGET ${_tgt_name} PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO TRUE)
      set_property(TARGET ${_tgt_name} PROPERTY INTERPROCEDURAL_OPTIMIZATION_MINSIZEREL TRUE)
      message(STATUS "  enable IPO/LTO (INTERPROCEDURAL_OPTIMIZATION for non-Debug configs) for shared lib \"${_tgt_name}\"")
    endif()
  endif()

  # --- link-time strip：按 PRJ_STRIP_SHARED_LIB_MODE，ASAN/MSVC 不 strip ---
  if(PRJ_ENABLE_ASAN OR MSVC)
    return()
  endif()

  if(PRJ_STRIP_SHARED_LIB_MODE STREQUAL "debug")
    target_link_options(${_tgt_name} PRIVATE "LINKER:--strip-debug")
    message(STATUS "  enable link-time --strip-debug for shared lib \"${_tgt_name}\"")
  elseif(PRJ_STRIP_SHARED_LIB_MODE STREQUAL "all")
    target_link_options(${_tgt_name} PRIVATE "LINKER:--strip-all")
    message(STATUS "  enable link-time --strip-all for shared lib \"${_tgt_name}\"")
  elseif(PRJ_STRIP_SHARED_LIB_MODE STREQUAL "none")
    message(STATUS "  keep all symbols (PRJ_STRIP_SHARED_LIB_MODE=none) for shared lib \"${_tgt_name}\"")
  else()
    message(WARNING "  unknown PRJ_STRIP_SHARED_LIB_MODE=\"${PRJ_STRIP_SHARED_LIB_MODE}\" (expect none|debug|all), skip strip.")
  endif()
endfunction(_prj_optimize_shared_lib)

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

# 为 Visual Studio 设置参数: 比如MT, Debug工作目录
macro(_setup_vs_params _tgt_name)
  if(MSVC)
    if(NOT DEFINED PRJ_OUTPUT_DIR) # <-- which is deploy dir
      message(FATAL_ERROR "you must defined PRJ_OUTPUT_DIR variable first!")
    endif()

    # 移除全局标志修改，改用目标属性
    # CMake 3.15+ 推荐使用 MSVC_RUNTIME_LIBRARY 属性
    set_property(TARGET ${_tgt_name} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    set_property(TARGET ${_tgt_name} PROPERTY VS_DEBUGGER_WORKING_DIRECTORY ${PRJ_OUTPUT_DIR}) # also can be "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
  endif(MSVC)
endmacro(_setup_vs_params)

# 去除 cmake 编译时候带的环境(rpath)，并重设为库所在的当前目录(和 libs 目录)
macro(_setup_rpath _tgt_name)
  if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    message(STATUS "setup rpath for ${_tgt_name}")
    set(CMAKE_SKIP_RPATH TRUE)
    # 使用 target_link_options 替代 set_target_properties，确保可以与其他链接选项共存
    target_link_options(${_tgt_name} PRIVATE "LINKER:--enable-new-dtags")
    target_link_options(${_tgt_name} PRIVATE "LINKER:-rpath,$ORIGIN:$ORIGIN/lib:$ORIGIN/libs:$ORIGIN/..:$ORIGIN/../lib:$ORIGIN/../libs")
    set_target_properties(${_tgt_name} PROPERTIES SKIP_BUILD_RPATH TRUE)
  elseif(APPLE)
    # macOS 使用 @executable_path, @loader_path, @rpath
    message(STATUS "setup rpath for ${_tgt_name} on macOS")
    set_target_properties(${_tgt_name} PROPERTIES
      INSTALL_RPATH "@executable_path;@executable_path/../lib;@executable_path/../Frameworks"
      BUILD_WITH_INSTALL_RPATH TRUE
    )
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

  # Linker language can be inferred from sources, 
  # but in the case of DLLs we don't have any .cc files so it would be ambiguous. 
  # We could set it explicitly only in the case of DLLs but, 
  # because "CXX" is always the correct linker language for static or for shared libraries, 
  # we set it unconditionally.
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
# TESTONLY: 测试支持库标记。仅当 PRJ_BUILD_UNIT_TESTS 或 PRJ_BUILD_TOOLS 任一开启时才构建，
#           且永不参与 install/发版。用于声明仅供测试/工具消费的支持库（桩、mock、共享测试工具）。
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

  # 测试支持库（TESTONLY）：只有当单元测试和工具都不构建时才跳过。
  # 此类库可能被单元测试或 vtn_api_test 工具消费，任一类测试产物在构建即需保留。
  if(PRJ_CC_LIB_TESTONLY AND NOT (PRJ_BUILD_UNIT_TESTS OR PRJ_BUILD_TOOLS))
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

  # Check if this is a header-only library.
  # Note that as of February 2019, many popular OS's (for example,
  # Ubuntu 16.04 LTS) only come with cmake 3.5 by default.
  # For this reason, we can't use list(FILTER...)
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

  set(_lib_type "STATIC")
  if(PRJ_BUILD_SHARED OR BUILD_SHARED_LIBS)
    set(_lib_type "SHARED")
    
    # "PRJ_BUILD_ALL_IN_ONE" 选项打开的情况下 强制所有依赖的 子模块 编译为静态库，以便主库可以将它们全部包含进来.
    if(PRJ_BUILD_ALL_IN_ONE AND(NOT _NAME STREQUAL "${CMAKE_PROJECT_NAME}"))
      set(_lib_type "STATIC")
      message(STATUS "  PRJ_BUILD_ALL_IN_ONE is ON, let \"${_NAME}\" lib_type change to ${_lib_type}, for \"${CMAKE_PROJECT_NAME}\" to include it.")
    endif()
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
      # 设置 C源文件的编译选项
      set_property(TARGET ${_NAME} APPEND PROPERTY COMPILE_OPTIONS $<$<COMPILE_LANGUAGE:C>:${PRJ_CC_LIB_COPTS}>)

      # 设置 C++源文件的编译选项
      set_property(TARGET ${_NAME} APPEND PROPERTY COMPILE_OPTIONS $<$<COMPILE_LANGUAGE:CXX>:${PRJ_CC_LIB_CCOPTS}>)
    else()
      target_compile_options(${_NAME} PRIVATE ${PRJ_CC_LIB_COPTS})
    endif(PRJ_CC_LIB_CCOPTS)

    if(PRJ_CC_LIB_DEFINES)
      message(STATUS "  setup definitions for ${_NAME}")
      target_compile_definitions(${_NAME} PUBLIC ${PRJ_CC_LIB_DEFINES})
    endif()

    if(PRJ_ENABLE_ASAN)
      prj_enable_sanitizer(${_NAME})
    endif()

    # 非 Debug 动态库：开启 IPO/LTO + 链接期 strip 调试信息，精简产物体积
    # （工具链不支持 IPO 时自动跳过；ASAN/Debug/RelWithDebInfo 保留调试信息）。
    _prj_optimize_shared_lib(${_NAME} ${_lib_type})

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
      # set(_GENERATE_SO_NAME "${CMAKE_SHARED_LIBRARY_PREFIX}${_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}")
      # message(STATUS "_GENERATE_SO_NAME=${_GENERATE_SO_NAME}")
      # set_target_properties(${_NAME} PROPERTIES LINK_FLAGS "-Wl,-soname,${_GENERATE_SO_NAME}")
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

# prj_cc_unit_test()
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
# By default, prj_cc_unit_test will always create a binary named ${CMAKE_PROJECT_NAME}_${NAME}.
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
# prj_cc_unit_test (
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
#
# prj_cc_unit_test - 创建单元测试可执行程序
#   受 PRJ_BUILD_UNIT_TESTS 控制（Debug 默认开，Release 默认关）
#   用于仅开发期验证的单元测试
#
function(prj_cc_unit_test)
  if(NOT PRJ_BUILD_UNIT_TESTS)
    return()
  endif()

  cmake_parse_arguments(PRJ_CC_UNIT_TEST
    ""
    "NAME"
    "HDRS;SRCS;COPTS;DEFINES;LINKOPTS;DEPS"
    ${ARGN}
  )

  set(_NAME "${CMAKE_PROJECT_NAME}_${PRJ_CC_UNIT_TEST_NAME}")

  add_executable(${_NAME} "")
  target_sources(${_NAME} PRIVATE ${PRJ_CC_UNIT_TEST_SRCS})
  target_include_directories(${_NAME}
    PUBLIC ${PRJ_COMMON_INCLUDE_DIRS} ${PRJ_CC_UNIT_TEST_HDRS}
    PRIVATE ${GMOCK_INCLUDE_DIRS} ${GTEST_INCLUDE_DIRS}
  )

  if(PRJ_CC_UNIT_TEST_DEFINES)
    target_compile_definitions(${_NAME} PUBLIC ${PRJ_CC_UNIT_TEST_DEFINES})
  endif()

  if(PRJ_CC_UNIT_TEST_COPTS)
    target_compile_options(${_NAME} PRIVATE ${PRJ_CC_UNIT_TEST_COPTS})
  endif()

  if(PRJ_ENABLE_ASAN)
    prj_enable_sanitizer(${_NAME})
  endif()

  target_link_libraries(${_NAME}
    PUBLIC ${PRJ_CC_UNIT_TEST_DEPS}
    PRIVATE ${PRJ_CC_UNIT_TEST_LINKOPTS}
  )

  # Add all targets to a folder in the IDE for organization.
  set_property(TARGET ${_NAME} PROPERTY FOLDER ${PRJ_IDE_FOLDER}/test)

  batch_setup_target_properties(${_NAME})

  add_test(NAME ${_NAME} COMMAND ${_NAME})

  # setup executable alias
  add_executable(${CMAKE_PROJECT_NAME}::${PRJ_CC_UNIT_TEST_NAME} ALIAS ${_NAME})
  message(STATUS "${CMAKE_PROJECT_NAME}::${PRJ_CC_UNIT_TEST_NAME} ALIAS ${_NAME} (unit test)")

  message(STATUS "target: ${_NAME} executable(unit_test)")
endfunction(prj_cc_unit_test)

#
# prj_cc_tool - 创建工具/示例可执行程序
#   受 PRJ_BUILD_TOOLS 控制（始终默认开）
#   用于发版验证工具（vtn_api_test）和对外示例（vtn_example）
#
function(prj_cc_tool)
  if(NOT PRJ_BUILD_TOOLS)
    return()
  endif()

  cmake_parse_arguments(PRJ_CC_TOOL
    ""
    "NAME"
    "HDRS;SRCS;COPTS;DEFINES;LINKOPTS;DEPS"
    ${ARGN}
  )

  set(_NAME "${CMAKE_PROJECT_NAME}_${PRJ_CC_TOOL_NAME}")

  add_executable(${_NAME} "")
  target_sources(${_NAME} PRIVATE ${PRJ_CC_TOOL_SRCS})
  target_include_directories(${_NAME}
    PUBLIC ${PRJ_COMMON_INCLUDE_DIRS} ${PRJ_CC_TOOL_HDRS}
    PRIVATE ${GMOCK_INCLUDE_DIRS} ${GTEST_INCLUDE_DIRS}
  )

  if(PRJ_CC_TOOL_DEFINES)
    target_compile_definitions(${_NAME} PUBLIC ${PRJ_CC_TOOL_DEFINES})
  endif()

  if(PRJ_CC_TOOL_COPTS)
    target_compile_options(${_NAME} PRIVATE ${PRJ_CC_TOOL_COPTS})
  endif()

  if(PRJ_ENABLE_ASAN)
    prj_enable_sanitizer(${_NAME})
  endif()

  target_link_libraries(${_NAME}
    PUBLIC ${PRJ_CC_TOOL_DEPS}
    PRIVATE ${PRJ_CC_TOOL_LINKOPTS}
  )

  # Add all targets to a folder in the IDE for organization.
  set_property(TARGET ${_NAME} PROPERTY FOLDER ${PRJ_IDE_FOLDER}/tools)

  batch_setup_target_properties(${_NAME})

  add_test(NAME ${_NAME} COMMAND ${_NAME})

  # setup executable alias
  add_executable(${CMAKE_PROJECT_NAME}::${PRJ_CC_TOOL_NAME} ALIAS ${_NAME})
  message(STATUS "${CMAKE_PROJECT_NAME}::${PRJ_CC_TOOL_NAME} ALIAS ${_NAME} (tool)")

  message(STATUS "target: ${_NAME} executable(tool)")
endfunction(prj_cc_tool)

#
# prj_cc_test - 已废弃，向后兼容层
#   建议迁移到 prj_cc_unit_test 或 prj_cc_tool
#   当前行为：映射到 prj_cc_unit_test
#
function(prj_cc_test)
  if(NOT PRJ_BUILD_UNIT_TESTS)
    return()
  endif()

  cmake_parse_arguments(PRJ_CC_TEST
    "PUBLIC"  # 兼容旧的 PUBLIC 参数（但已忽略）
    "NAME"
    "HDRS;SRCS;COPTS;DEFINES;LINKOPTS;DEPS"
    ${ARGN}
  )

  message(WARNING "prj_cc_test is deprecated. Please use prj_cc_unit_test or prj_cc_tool instead. Current target: ${PRJ_CC_TEST_NAME}")

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

  if(PRJ_ENABLE_ASAN)
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
