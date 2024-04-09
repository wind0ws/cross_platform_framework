cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

# ---------------------------------------------------------------------------------------
# Start project
# ---------------------------------------------------------------------------------------
include(CheckSymbolExists)
#include(cmake/ide.cmake)
include(cmake/compiler_warnings.cmake)
include(cmake/macros.cmake)
include(cmake/utility.cmake)
prj_extract_version() # <-- extract PRJ_VERSION variable from src/version.h

project(my_prj VERSION ${PRJ_VERSION} LANGUAGES C CXX)
message(STATUS "PROJECT => ${PROJECT_NAME} : ${PROJECT_VERSION}")

#include(GNUInstallDirs)
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_COLOR_MAKEFILE ON)

# ---------------------------------------------------------------------------------------
# Compiler config
# ---------------------------------------------------------------------------------------
if(NOT CMAKE_C_STANDARD)
  message(STATUS "now define CMAKE_C_STANDARD for project")
  set(CMAKE_C_STANDARD 11)
  set(CMAKE_C_STANDARD_REQUIRED ON)
endif()
if(NOT CMAKE_CXX_STANDARD)
  message(STATUS "now define CMAKE_CXX_STANDARD for project")
  set(CMAKE_CXX_STANDARD 11)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()
set(PRJ_C_STANDARD ${CMAKE_C_STANDARD})
set(PRJ_CXX_STANDARD ${CMAKE_CXX_STANDARD})
message(STATUS "PRJ_C_STANDARD=${PRJ_C_STANDARD}, PRJ_CXX_STANDARD=${PRJ_CXX_STANDARD}")

# ---------------------------------------------------------------------------------------
# Set PRJ_MASTER_PROJECT to ON if we are building this project
# ---------------------------------------------------------------------------------------
# Check if project is being used directly or via add_subdirectory, but allow overriding
if(NOT DEFINED PRJ_MASTER_PROJECT)
#CMAKE_CURRENT_SOURCE_DIR：这个变量表示当前正在处理的 CMakeLists.txt 文件所在的源代码目录。例如，如果有一个子目录中的 CMakeLists.txt 文件被读取和处理，那么 CMAKE_CURRENT_SOURCE_DIR 会指向这个子目录。
#CMAKE_SOURCE_DIR：此变量代表最外层的 CMakeLists.txt 文件所在的源代码目录。换句话说，这是项目源代码的根目录
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
message(STATUS "Build type: " ${CMAKE_BUILD_TYPE})

# ---------------------------------------------------------------------------------------
# detect platform / abi, and setup output dir.
# ---------------------------------------------------------------------------------------
# 项目根目录， 用于sub_dir下的cmake去获取使用。
set(PRJ_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE STRING "")
# 第三方库目录，存放各个库
set(PRJ_THIRD_PARTY_DIR "${PRJ_SOURCE_DIR}/src/third_party" CACHE STRING "")
# 项目通用 include 目录
set(PRJ_COMMON_INCLUDE_DIRS ${PRJ_SOURCE_DIR}/src CACHE STRING "")
set(PRJ_OUTPUT_DIR ${PRJ_SOURCE_DIR}/tool/deploy CACHE STRING "")
# The IDE folder for Project that will be used if Project is included in a CMake
# project that sets
#    set_property(GLOBAL PROPERTY USE_FOLDERS ON)
# For example, Visual Studio supports folders.
set(PRJ_IDE_FOLDER ${PRJ_OUTPUT_DIR} CACHE STRING "")
message(STATUS "root of project: PRJ_SOURCE_DIR => ${PRJ_SOURCE_DIR}")
#set(PRJ_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR})
include(cmake/platform_detector.cmake)

# make sure __cplusplus is defined when using msvc and enable parallel build
if(MSVC)
  string(APPEND CMAKE_CXX_FLAGS " /Zc:__cplusplus /MP")
endif()

set(CMAKE_CXX_EXTENSIONS OFF)
if(CMAKE_SYSTEM_NAME MATCHES "CYGWIN" OR CMAKE_SYSTEM_NAME MATCHES "MSYS")
  set(CMAKE_CXX_EXTENSIONS ON)
endif()

# ---------------------------------------------------------------------------------------
# Build options
# ---------------------------------------------------------------------------------------
# build all in one option
option(PRJ_BUILD_ALL_IN_ONE "Build all in one library" ON)

# build shared option
option(PRJ_BUILD_SHARED "Build shared library" OFF)
option(BUILD_SHARED_LIBS "Build shared library" OFF)
if(PRJ_BUILD_SHARED OR BUILD_SHARED_LIBS)
  set(PRJ_BUILD_SHARED ON)
  set(BUILD_SHARED_LIBS ON)
endif()
# testing options
option(PRJ_BUILD_TESTS "Build tests" OFF)

# not used at current now.
option(PRJ_MINIMIZE "Minimize project library size for mobile deploy" OFF)

# precompiled headers option
option(PRJ_ENABLE_PCH "Build static or shared library using precompiled header to speed up compilation time" OFF)

# build position independent code, default ON
option(PRJ_BUILD_PIC "Build position independent code (-fPIC)" ON)

# sanitizer options
option(PRJ_SANITIZE_ADDRESS "Enable address sanitizer in tests" OFF)

# warning options
option(PRJ_BUILD_WARNINGS "Enable compiler warnings" OFF)

# install options
option(PRJ_INSTALL "Generate the install target" ${PRJ_MASTER_PROJECT})

# third_party lib shared options: if ON, use third_party shared lib.
option(PRJ_THIRD_LIB_SHARED "use shared lib on third_party" OFF)

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
# CMAKE_CXX_VISIBILITY_PRESET , setup visibility for C++ symbols
# ---------------------------------------------------------------------------------------
if (PRJ_MASTER_PROJECT AND NOT DEFINED CMAKE_CXX_VISIBILITY_PRESET)
  set_verbose(CMAKE_CXX_VISIBILITY_PRESET hidden CACHE STRING
              "Preset for the export of private symbols")
  set_property(CACHE CMAKE_CXX_VISIBILITY_PRESET PROPERTY STRINGS
               hidden default)
endif ()

# ---------------------------------------------------------------------------------------
# CMAKE_VISIBILITY_INLINES_HIDDEN , setup visibility for inline functions
# ---------------------------------------------------------------------------------------
if (PRJ_MASTER_PROJECT AND NOT DEFINED CMAKE_VISIBILITY_INLINES_HIDDEN)
  set_verbose(CMAKE_VISIBILITY_INLINES_HIDDEN ON CACHE BOOL
              "Whether to add a compile flag to hide symbols of inline functions")
endif ()

# ---------------------------------------------------------------------------------------
# cxx_variadic_templates: 在 C++11 中，引入了可变模板（Variadic Templates）的概念，
# 它允许函数或类模板接受可变数量的类型参数
# ---------------------------------------------------------------------------------------
list(FIND CMAKE_CXX_COMPILE_FEATURES "cxx_variadic_templates" _index)
if (${_index} GREATER -1)
  # Use cxx_variadic_templates instead of more appropriate cxx_std_11 for
  # compatibility with older CMake versions.
  set(PRJ_REQUIRED_FEATURES cxx_variadic_templates)
endif ()
message(STATUS "Required features: ${PRJ_REQUIRED_FEATURES}")

# ---------------------------------------------------------------------------------------
# auto setup install include dir. 
# ---------------------------------------------------------------------------------------
if(DEFINED(${CMAKE_INSTALL_INCLUDEDIR}))
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

# no need do here. detect ASAN on utility.cmake by PRJ_SANITIZE_ADDRESS
# if (PRJ_SANITIZE_ADDRESS AND PRJ_MASTER_PROJECT)
#   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fno-omit-frame-pointer -fsanitize-recover=address")
#   set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fsanitize=address")
# endif()

# set(PRJ_SYSTEM_HEADERS_ATTRIBUTE "")
# if (PRJ_SYSTEM_HEADERS)
#   set(PRJ_SYSTEM_HEADERS_ATTRIBUTE SYSTEM)
# endif ()

if(PRJ_BUILD_TESTS)
  message(STATUS "Generating tests")
  enable_testing()
endif()

#if (PRJ_MINIMIZE)
#    message(NOTICE "*************************************")
#    message(NOTICE "PRJ_MINIMIZE is enabled, prj will limit its functionality to minimize build size:")
#    message(NOTICE "*************************************")
#
#    set(PRJ_MINIMIZE ON)
#endif()

# ---------------------------------------------------------------------------------------
# set postfix for debug library. 
# ---------------------------------------------------------------------------------------
set(PRJ_DEBUG_POSTFIX "" CACHE STRING "Debug library postfix.")

# ---------------------------------------------------------------------------------------
# default PRJ_COMPILE_OPTIONS
# ---------------------------------------------------------------------------------------
# PRJ_WERROR: set 1 to treat warning as error.
# macro "get_warnings_copts" on CompilerWarnings.cmake
set(PRJ_COMPILE_OPTIONS "")
set(PRJ_CXX_COMPILE_OPTIONS "")
get_warnings_copts(${PRJ_WERROR} PRJ_COMPILE_OPTIONS PRJ_CXX_COMPILE_OPTIONS)
MESSAGE(STATUS " PRJ_COMPILE_OPTIONS: ${PRJ_COMPILE_OPTIONS} \n PRJ_CXX_COMPILE_OPTIONS=${PRJ_CXX_COMPILE_OPTIONS}\n")

# import 3rdparty
#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/fmt" EXCLUDE_FROM_ALL)
#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/filesystem" EXCLUDE_FROM_ALL)
#set(TURBO_SPDLOG_FMT_EXTERNAL ON)
#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/spdlog" EXCLUDE_FROM_ALL)
#set(JSON_BuildTests OFF CACHE INTERNAL "")
#set(JSON_MultipleHeader ON CACHE INTERNAL "")
#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/nlohmann-json" EXCLUDE_FROM_ALL)
#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/mio" EXCLUDE_FROM_ALL)
#if (NOT ANDROID)
#    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/abseil-tiny" EXCLUDE_FROM_ALL)
#endif()

# define "_PRJ_DEPENDENCY_THIRD_ASSETS" and "_PRJ_DEPENDENCY_THIRD_ASSETS"
define_dependency_var()

#子模块可以这样引入别的模块头文件， 
#   模块引入本目录下的 include "current_folder.h"  ; 引入别的模块的 include "src/other_module/other_module.h"

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/src/")

