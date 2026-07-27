# 3.13支持LINK_FLAGS, 3.15支持CMAKE_MSVC_RUNTIME_LIBRARY
cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# ---------------------------------------------------------------------------------------
# Start project
# ---------------------------------------------------------------------------------------
include(CheckSymbolExists)

# include(cmake/ide.cmake)
include(cmake/compiler_warnings.cmake)
include(cmake/macros.cmake)
include(cmake/utility.cmake)
prj_extract_version() # <-- extract PRJ_VERSION variable from src/version.h

project(my_prj VERSION ${PRJ_VERSION} LANGUAGES C CXX)
message(STATUS "PROJECT => ${PROJECT_NAME} : ${PROJECT_VERSION}")
# ---------------------------------------------------------------------------------------
# Compiler config：语言标准 + 特性检测。
# 必须在 project() 之后 include（依赖 project() 填充的 CMAKE_CXX_COMPILE_FEATURES）。
# ---------------------------------------------------------------------------------------
include(cmake/compiler_config.cmake)

# include(GNUInstallDirs)
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_COLOR_MAKEFILE ON)

# default we enable it on below.
# set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# show version of toochain.
prj_show_toolchain_version()

# ---------------------------------------------------------------------------------------
# Set PRJ_MASTER_PROJECT to ON if we are building this project
# ---------------------------------------------------------------------------------------
# Check if project is being used directly or via add_subdirectory, but allow overriding
if(NOT DEFINED PRJ_MASTER_PROJECT)
  # CMAKE_CURRENT_SOURCE_DIR：这个变量表示当前正在处理的 CMakeLists.txt 文件所在的源代码目录。例如，如果有一个子目录中的 CMakeLists.txt 文件被读取和处理，那么 CMAKE_CURRENT_SOURCE_DIR 会指向这个子目录。
  # CMAKE_SOURCE_DIR：此变量代表最外层的 CMakeLists.txt 文件所在的源代码目录。换句话说，这是项目源代码的根目录
  if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(PRJ_MASTER_PROJECT ON)
  else()
    set(PRJ_MASTER_PROJECT OFF)
  endif()
endif()

message(STATUS "PRJ_MASTER_PROJECT => ${PRJ_MASTER_PROJECT}")

# ---------------------------------------------------------------------------------------
# Set default build type to release
# ---------------------------------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose Release or Debug" FORCE)
endif()
message(STATUS "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")

# ---------------------------------------------------------------------------------------
# detect platform / abi, and setup output dir.
# ---------------------------------------------------------------------------------------
# 项目根目录， 用于sub_dir下的cmake去获取使用。
set(PRJ_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE STRING "")

# 第三方库目录，存放第三方库/头文件/资源
set(PRJ_THIRD_PARTY_DIR "${PRJ_SOURCE_DIR}/src/third_party" CACHE STRING "")

# 项目通用 include 目录(所有模块都可以访问的头文件目录), 可以支持配置多个
set(PRJ_COMMON_INCLUDE_DIRS ${PRJ_SOURCE_DIR}/src CACHE STRING "")

# 项目编译输出文件夹
set(PRJ_OUTPUT_DIR ${PRJ_SOURCE_DIR}/tool/deploy CACHE STRING "")

# The IDE folder for Project that will be used
# if Project is included in a CMake project that sets.
# set_property(GLOBAL PROPERTY USE_FOLDERS ON)
# For example, Visual Studio supports folders.
set(PRJ_IDE_FOLDER ${PRJ_OUTPUT_DIR} CACHE STRING "")
message(STATUS "root of project: PRJ_SOURCE_DIR => ${PRJ_SOURCE_DIR}")
# ---------------------------------------------------------------------------------------
# setup PRJ_REPO_BRANCH / PRJ_REPO_REVISION, and also add_definitions to code.
# ---------------------------------------------------------------------------------------
prj_setup_repo_info(${PRJ_SOURCE_DIR})

# ---------------------------------------------------------------------------------------
# now we can include platform_detector.cmake,
# because we have defined PRJ_SOURCE_DIR/PRJ_OUTPUT_DIR.
# ---------------------------------------------------------------------------------------
include(cmake/platform_detector.cmake)

# ---------------------------------------------------------------------------------------
# Build options
# ---------------------------------------------------------------------------------------
# build all in one option
option(PRJ_BUILD_ALL_IN_ONE "Build all in one library" ON)

# build shared option
option(PRJ_BUILD_SHARED "Build shared library" ON)
set(BUILD_SHARED_LIBS ${PRJ_BUILD_SHARED} CACHE BOOL "Build shared library, alias for PRJ_BUILD_SHARED")

# if not same, error occurred.
if(NOT(PRJ_BUILD_SHARED STREQUAL BUILD_SHARED_LIBS))
  message(FATAL_ERROR
    "PRJ_BUILD_SHARED (${PRJ_BUILD_SHARED}) and BUILD_SHARED_LIBS (${BUILD_SHARED_LIBS}) must have the same value!\n"
    "Please set them to the same value (both ON or both OFF)."
  )
endif()

# testing options
# 单元测试：Debug 默认开，Release 默认关（仅开发验证）
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(_DEFAULT_BUILD_UNIT_TESTS ON)
else()
  set(_DEFAULT_BUILD_UNIT_TESTS OFF)
endif()
option(PRJ_BUILD_UNIT_TESTS "Build unit tests" ${_DEFAULT_BUILD_UNIT_TESTS})

# 工具和示例：始终默认开（发版验证和对外交付必需）
option(PRJ_BUILD_TOOLS "Build tools and examples (vtn_api_test, vtn_example)" ON)

# 向后兼容：PRJ_BUILD_TESTS 映射到 PRJ_BUILD_UNIT_TESTS
# 若用户显式设置了 PRJ_BUILD_TESTS，同步到新开关
if(DEFINED CACHE{PRJ_BUILD_TESTS})
  set(PRJ_BUILD_UNIT_TESTS ${PRJ_BUILD_TESTS} CACHE BOOL "Build unit tests" FORCE)
  message(WARNING "PRJ_BUILD_TESTS is deprecated, use PRJ_BUILD_UNIT_TESTS instead. Auto-synced value: ${PRJ_BUILD_TESTS}")
endif()

# not used at current now.
option(PRJ_MINIMIZE "Minimize project library size for mobile deploy" OFF)

# precompiled headers option
option(PRJ_ENABLE_PCH "Build static or shared library using precompiled header to speed up compilation time" OFF)

# build position independent code, default ON
option(PRJ_BUILD_PIC "Build position independent code (-fPIC)" ON)

# =================== ASan options start ======================================
set(_DEFAULT_ASAN OFF)

if(PRJ_MASTER_PROJECT AND(CMAKE_BUILD_TYPE STREQUAL "Debug"))
  set(_DEFAULT_ASAN ON)
endif()

# ASan: address sanitizer options
option(PRJ_ENABLE_ASAN "Enable address sanitizer in tests" ${_DEFAULT_ASAN})

if(PRJ_ENABLE_ASAN)
  if(MSVC AND("${MSVC_VERSION}" VERSION_LESS "1929"))
    message(STATUS "ASan begin supported from msvc 2019(16.9), but yours MSVC_VERSION=${MSVC_VERSION}, so disabled ASan.")
    set(PRJ_ENABLE_ASAN OFF)
  else()
    add_compile_definitions(PRJ_ENABLE_ASAN=1)
  endif()
endif(PRJ_ENABLE_ASAN)

# =================== ASan options end ======================================

# =================== 动态库 strip options start ============================
# 链接期 strip 动态库符号以精简产物体积。默认策略：Debug 版保留全部符号供排查，
# 非 Debug 版彻底 strip。可用 -DPRJ_STRIP_SHARED_LIB_MODE=<none|debug|all> 覆盖：
#   none  : 不 strip，保留全部符号(含 .debug_* DWARF)，用于在非 Debug 版排查问题。
#   debug : 仅去 DWARF 调试段，保留 .symtab 函数名表(崩溃回溯 addr2line 可用)。
#   all   : 去调试段与符号表，产物最小(非 Debug 默认值)。
# 说明：仅对 GNU/Clang(类 ld) 生效，MSVC 无 --strip-* 标志；ASAN 构建强制不 strip。
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(_DEFAULT_STRIP_SHARED_LIB_MODE "none")
else()
  set(_DEFAULT_STRIP_SHARED_LIB_MODE "all")
endif()

set(PRJ_STRIP_SHARED_LIB_MODE "${_DEFAULT_STRIP_SHARED_LIB_MODE}" CACHE STRING
  "Strip shared lib symbols at link time: none|debug|all (default: none for Debug, all otherwise)")
set_property(CACHE PRJ_STRIP_SHARED_LIB_MODE PROPERTY STRINGS none debug all)
# =================== 动态库 strip options end ==============================

# warning options
option(PRJ_BUILD_WARNINGS "Enable compiler warnings" OFF)

# install options
option(PRJ_INSTALL "Generate the install target" ${PRJ_MASTER_PROJECT})

# for export all symbols on windows, usually we use "exports.def" file to declare exported symbols.
# cmake -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE -DBUILD_SHARED_LIBS=TRUE
option(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS "export dll ALL_SYMBOLS on windows" OFF)

# third_party lib shared options: if ON, use third_party shared lib.
option(PRJ_THIRD_LIB_SHARED "use shared lib on third_party" OFF)
message(STATUS "PRJ_THIRD_LIB_SHARED=${PRJ_THIRD_LIB_SHARED}")

# ---------------------------------------------------------------------------------------
# 依赖库拷贝模式(拷贝第三方依赖库到部署 bin 目录时生效)：
#   auto  -> 默认。若本项目产物是动态库(PRJ_BUILD_SHARED=ON)，静态依赖库已被链入动态库，
#            运行期无需再拷贝，故只拷贝动态依赖库；产物是静态库时仍拷贝全部依赖库。
#   force -> 强制拷贝所有依赖库(静态库 + 动态库)，即历史行为。
# 注：仅影响"拷贝到部署目录"，不影响链接(链接始终使用依赖库全路径)。
# ---------------------------------------------------------------------------------------
set(PRJ_DEP_LIB_COPY_MODE "auto" CACHE STRING "dependency lib copy mode: auto or force")
set_property(CACHE PRJ_DEP_LIB_COPY_MODE PROPERTY STRINGS auto force)
message(STATUS "PRJ_DEP_LIB_COPY_MODE=${PRJ_DEP_LIB_COPY_MODE}")

# =================== PRJ_HIDDEN_SYMBOLS options start ======================================
if(PRJ_MASTER_PROJECT AND NOT(CMAKE_BUILD_TYPE STREQUAL "Debug"))
  set(_DEFAULT_HIDDEN_SYMBOLS ON)
else()
  set(_DEFAULT_HIDDEN_SYMBOLS OFF)
endif()

# hidden symbols options
option(PRJ_HIDDEN_SYMBOLS "Hidden internal c/cxx symbols" ${_DEFAULT_HIDDEN_SYMBOLS})

# =================== PRJ_HIDDEN_SYMBOLS options end ======================================
# clang-tidy
if(${CMAKE_VERSION} VERSION_GREATER "3.5")
  option(PRJ_TIDY "run clang-tidy" OFF)
endif()

if(PRJ_TIDY)
  set(CMAKE_CXX_CLANG_TIDY "clang-tidy")
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
  message(STATUS "Enabled clang-tidy")
endif()

if(PRJ_BUILD_PIC)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# ---------------------------------------------------------------------------------------
# CMAKE_C_VISIBILITY_PRESET , setup visibility for C symbols
# CMAKE_CXX_VISIBILITY_PRESET , setup visibility for C++ symbols
# CMAKE_VISIBILITY_INLINES_HIDDEN , setup visibility for inline functions
# ---------------------------------------------------------------------------------------
if(PRJ_HIDDEN_SYMBOLS)
  if(NOT DEFINED CMAKE_C_VISIBILITY_PRESET)
    set_verbose(CMAKE_C_VISIBILITY_PRESET hidden CACHE STRING
      "Preset for the export c of private symbols")
    set_property(CACHE CMAKE_C_VISIBILITY_PRESET PROPERTY STRINGS
      hidden default)
  endif()

  if(NOT DEFINED CMAKE_CXX_VISIBILITY_PRESET)
    set_verbose(CMAKE_CXX_VISIBILITY_PRESET hidden CACHE STRING
      "Preset for the export cxx of private symbols")
    set_property(CACHE CMAKE_CXX_VISIBILITY_PRESET PROPERTY STRINGS
      hidden default)
  endif()

  if(NOT DEFINED CMAKE_VISIBILITY_INLINES_HIDDEN)
    set_verbose(CMAKE_VISIBILITY_INLINES_HIDDEN ON CACHE BOOL
      "Whether to add a compile flag to hide symbols of inline functions")
  endif()
endif()

message(STATUS " CMAKE_C_VISIBILITY_PRESET=${CMAKE_C_VISIBILITY_PRESET}")
message(STATUS " CMAKE_CXX_VISIBILITY_PRESET=${CMAKE_CXX_VISIBILITY_PRESET}")
message(STATUS " CMAKE_VISIBILITY_INLINES_HIDDEN=${CMAKE_VISIBILITY_INLINES_HIDDEN}")

# ---------------------------------------------------------------------------------------
# auto setup install include dir.
# ---------------------------------------------------------------------------------------
if(DEFINED ${CMAKE_INSTALL_INCLUDEDIR})
  message(STATUS "CMAKE_INSTALL_INCLUDEDIR is defined.")
  set(_install_include_dir ${CMAKE_INSTALL_INCLUDEDIR})
else()
  set(_install_include_dir ${PRJ_OUTPUT_DIR}/inc)
endif()

# PRJ_INC_DIR 是cmake install时头文件安装位置
set_verbose(PRJ_INC_DIR ${_install_include_dir} CACHE STRING
  "Installation directory for include files, a relative path that "
  "will be joined with ${CMAKE_INSTALL_PREFIX} or an absolute path.")
message(STATUS "INSTALL_INCLUDEDIR=${_install_include_dir}  PRJ_INC_DIR=${PRJ_INC_DIR}")

option(PRJ_SYSTEM_HEADERS "Expose headers with marking them as system." OFF)
option(PRJ_PEDANTIC "Enable extra warnings and expensive tests." ON)
option(PRJ_WERROR "Halt the compilation with an error on compiler warnings." OFF)
option(PRJ_INSTALL "Generate the install target." OFF)

set(PRJ_SYSTEM_HEADERS_ATTRIBUTE "")

if(PRJ_SYSTEM_HEADERS)
  set(PRJ_SYSTEM_HEADERS_ATTRIBUTE SYSTEM)
endif()

if(PRJ_BUILD_UNIT_TESTS OR PRJ_BUILD_TOOLS)
  message(STATUS "Generating tests (UNIT_TESTS=${PRJ_BUILD_UNIT_TESTS}, TOOLS=${PRJ_BUILD_TOOLS})")
  enable_testing()
endif()

# if (PRJ_MINIMIZE)
# message(NOTICE "*************************************")
# message(NOTICE "PRJ_MINIMIZE is enabled, prj will limit its functionality to minimize build size:")
# message(NOTICE "*************************************")
#
# set(PRJ_MINIMIZE ON)
# endif()

# ---------------------------------------------------------------------------------------
# set postfix for debug library.
# ---------------------------------------------------------------------------------------
set(PRJ_DEBUG_POSTFIX "" CACHE STRING "Debug library postfix.")

# ---------------------------------------------------------------------------------------
# default PRJ_COMPILE_OPTIONS(for C) and PRJ_CXX_COMPILE_OPTIONS(for CXX)
# ---------------------------------------------------------------------------------------
# PRJ_WERROR: set 1 to treat warning as error.
# macro "get_warnings_copts" on compiler_warnings.cmake
set(PRJ_COMPILE_OPTIONS "")
set(PRJ_CXX_COMPILE_OPTIONS "")
get_warnings_copts(${PRJ_WERROR} PRJ_COMPILE_OPTIONS PRJ_CXX_COMPILE_OPTIONS)
message(STATUS " PRJ_COMPILE_OPTIONS: ${PRJ_COMPILE_OPTIONS} \n PRJ_CXX_COMPILE_OPTIONS=${PRJ_CXX_COMPILE_OPTIONS}\n")

# import 3rdparty
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/fmt" EXCLUDE_FROM_ALL)
# set(JSON_BuildTests OFF CACHE INTERNAL "")
# set(JSON_MultipleHeader ON CACHE INTERNAL "")
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/nlohmann-json" EXCLUDE_FROM_ALL)
# if (NOT ANDROID)
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/abseil-tiny" EXCLUDE_FROM_ALL)
# endif()

# ---------------------------------------------------------------------------------------
# macros.cmake : define "_PRJ_DEPENDENCY_THIRD_LIBS" and "_PRJ_DEPENDENCY_THIRD_ASSETS"
# ---------------------------------------------------------------------------------------
define_dependency_var()

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/src/")
