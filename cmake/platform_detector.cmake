# ============================= setup output dir START =============================
if(NOT DEFINED PLATFORM OR("x${PLATFORM}" STREQUAL "x"))
  if(ANDROID)
    set(PLATFORM Android)
  elseif(WIN32)
    set(PLATFORM Windows)
  elseif(APPLE)
    set(PLATFORM macOS)
  elseif(UNIX AND NOT APPLE)
    # 优先使用 CMAKE_SYSTEM_NAME，但做更精确的判断
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      set(PLATFORM Linux)
    else()
      set(PLATFORM ${CMAKE_SYSTEM_NAME})
    endif()
  elseif(NOT CMAKE_CROSSCOMPILING)
    message(WARNING "not defined PLATFORM, use CMAKE_SYSTEM_NAME(${CMAKE_SYSTEM_NAME}) as PLATFORM")
    set(PLATFORM ${CMAKE_SYSTEM_NAME})
  else()
    message(FATAL_ERROR "PLATFORM can not be empty! current CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}")
  endif()
endif()

message(STATUS "your PLATFORM = ${PLATFORM}")

# detect current PLATFORM_ABI
if ((DEFINED PLATFORM_ABI) AND(NOT "x${PLATFORM_ABI}" STREQUAL "x"))
  message(STATUS "your PLATFORM_ABI = ${PLATFORM_ABI}")
elseif(ANDROID)
  set(PLATFORM_ABI ${ANDROID_ABI})
  add_compile_definitions(ANDROID_PLATFORM_LEVEL=${ANDROID_PLATFORM_LEVEL})
else()
  # 统一使用 CMAKE_SIZEOF_VOID_P 判断位数
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(PLATFORM_ABI x64)
  elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    set(PLATFORM_ABI x32)
  else()
    message(FATAL_ERROR "Unknown pointer size: ${CMAKE_SIZEOF_VOID_P}")
  endif()
  
  message(STATUS "detected PLATFORM_ABI = ${PLATFORM_ABI} (CMAKE_SIZEOF_VOID_P=${CMAKE_SIZEOF_VOID_P})")
endif()

string(TOLOWER "${PLATFORM}" PLATFORM_TOLOWER)
string(TOLOWER "${PLATFORM_ABI}" PLATFORM_ABI_TOLOWER)
string(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_TOLOWER)

# define PLATFORM info macro on code
add_compile_definitions(
  _PLATFORM="${PLATFORM}"
  _PLATFORM_ABI="${PLATFORM_ABI}"
)

if((DEFINED ANDROID) AND("${ANDROID_ABI}" MATCHES "x86_64"))
  message(STATUS "it is android-x86_64. let's append CMAKE_SYSTEM_LIBRARY_PATH for fix lib not found error in cmake")
  list(APPEND CMAKE_SYSTEM_LIBRARY_PATH "${ANDROID_SYSTEM_LIBRARY_PATH}/usr/lib64")
  set(CMAKE_SYSTEM_LIBRARY_PATH ${CMAKE_SYSTEM_LIBRARY_PATH} PARENT_SCOPE)
  message(STATUS "current CMAKE_SYSTEM_LIBRARY_PATH => ${CMAKE_SYSTEM_LIBRARY_PATH}")
endif()

if (DEFINED DEPLOY_DIR)
  message(STATUS "you defined DEPLOY_DIR => ${DEPLOY_DIR}")
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${DEPLOY_DIR})
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${DEPLOY_DIR})
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${DEPLOY_DIR})
else()
  if(NOT DEFINED PRJ_OUTPUT_DIR)
    message(FATAL_ERROR "you must defined PRJ_OUTPUT_DIR variable first!")
  endif()

  set(_APPEND_PATH_FOR_OUTPUT_DIR "")

  if(ANDROID)
    string(TOLOWER "${ANDROID_STL}" ANDROID_STL_TOLOWER)
    set(_APPEND_PATH_FOR_OUTPUT_DIR "_${ANDROID_STL_TOLOWER}")
  endif(ANDROID)

  set(_ALL_BUILD_TYPES "DEBUG" "RELEASE" "RELWITHDEBINFO" "MINSIZEREL")

  foreach(_build_type_item ${_ALL_BUILD_TYPES})
    string(TOLOWER "${_build_type_item}" _BUILD_TYPE_ITEM_TOLOWER)
    set(_output_dir_tmp "${PRJ_OUTPUT_DIR}/bin/${PLATFORM_TOLOWER}_${PLATFORM_ABI_TOLOWER}_${_BUILD_TYPE_ITEM_TOLOWER}${_APPEND_PATH_FOR_OUTPUT_DIR}")
    message(STATUS "setup OUTPUT_DIRECTORY for ${_build_type_item} -> ${_output_dir_tmp}")

    # bin, executeable
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${_build_type_item} ${_output_dir_tmp})

    # shared libs
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${_build_type_item} ${_output_dir_tmp})

    # static libs
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${_build_type_item} ${_output_dir_tmp})
  endforeach()
endif()

# ============================= setup output dir END =============================

# ---------------------------------------------------------------------------------------
# setup common flags
# ---------------------------------------------------------------------------------------
if (WIN32 AND NOT CYGWIN AND NOT(CMAKE_SYSTEM_NAME STREQUAL "WindowsStore") AND NOT ANDROID)
  # suppress warnings for VS:
  # C4001：single line comment warning
  # C4711：warning of function 'function' selected for inline expansion
  # C4819: utf8 coding page warning
  # C4820: 'bytes' bytes padding added after construct 'member_name'
  # C5045: compiler will insert Spectre mitigation for memory load if /Qspectre switch specified
  # C5105: winbase.h undefined behavior warning
  add_compile_options(/wd4001 /wd4711 /wd4819 /wd4820 /wd5045 /wd5105)

  # add optimiziation options
  add_compile_options(/bigobj /nologo /EHsc /GF /MP)

  # solution folder
  # set_property(GLOBAL PROPERTY USE_FOLDERS ON)
  # put ZERO_CHECK/ALL_BUILD in all_targets folder
  # set_property(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "all_targets")
  string(APPEND CMAKE_C_FLAGS_RELEASE " /Ot /MT")
  string(APPEND CMAKE_C_FLAGS_DEBUG " /MTd /DEBUG")
  string(APPEND CMAKE_CXX_FLAGS_RELEASE " /Ot /MT")
  string(APPEND CMAKE_CXX_FLAGS_DEBUG " /MTd /DEBUG /Zi")

  # string(APPEND CMAKE_C_FLAGS_DEBUG   " -fsanitize=address,undefined")
  # string(APPEND CMAKE_CXX_FLAGS_DEBUG " -fsanitize=address,undefined")
  set(COMMON_C_FLGAS " /utf-8 /W3 ")
  set(COMMON_CXX_FLAGS "")
  # ignore warnings about LIBCMT: 4098
  # ignore warnings about missing pdb: 4099
  set(COMMON_EXE_LINKER_FLAGS "/ignore:4098 /ignore:4099") 
  set(COMMON_SHARED_LINKER_FLAGS "${COMMON_EXE_LINKER_FLAGS}")
  set(COMMON_STATIC_LINKER_FLAGS "${COMMON_EXE_LINKER_FLAGS}")
  # add_link_options(/NODEFAULTLIB:LIBCMT) # <-- 不能加这个参数, 加了 ASan 会失效.
   # 在 Release 编译启用链接时代码生成
  add_compile_options($<$<CONFIG:Release>:/GL>)
  add_link_options($<$<CONFIG:Release>:/LTCG>)
  set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
else()
  set(COMMON_C_FLGAS " -Wall -Wno-unused-local-typedef -Wno-unused-local-typedefs -Wno-unused-function -Wno-comment -Wno-unknown-pragmas -fPIC")
  set(COMMON_CXX_FLAGS " -Wno-write-strings")

  # Android 5.0 及以上需要设置 PIE, 为啥不设置-fPIC, 因为已经 set(POSITION_INDEPENDENT_CODE TRUE)
  set(COMMON_EXE_LINKER_FLAGS "-fPIE")
  set(COMMON_SHARED_LINKER_FLAGS "${COMMON_EXE_LINKER_FLAGS}")
  set(COMMON_STATIC_LINKER_FLAGS "")

  # add _GNU_SOURCE for pthread_setname_np
  # add_compile_definitions(_GNU_SOURCE=1)
endif()

string(APPEND CMAKE_C_FLAGS "${COMMON_C_FLGAS}")
string(APPEND CMAKE_CXX_FLAGS "${COMMON_C_FLGAS} ${COMMON_CXX_FLGAS}")
string(APPEND CMAKE_EXE_LINKER_FLAGS " ${COMMON_EXE_LINKER_FLAGS}")
string(APPEND CMAKE_SHARED_LINKER_FLAGS " ${COMMON_SHARED_LINKER_FLAGS}")

if(COMMON_STATIC_LINKER_FLAGS)
  string(APPEND CMAKE_STATIC_LINKER_FLAGS " ${COMMON_STATIC_LINKER_FLAGS}")
endif()

# ---------------------------------------------------------------------------------------
# replace MD to MT
# ---------------------------------------------------------------------------------------
if(WIN32 AND MSVC)
  # 移除全局标志修改，改为使用 cmake_policy 或目标属性
  # 如果需要全局设置，使用 CMAKE_MSVC_RUNTIME_LIBRARY
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.15")
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
  else()
    # 仅为旧版本 CMake 保留此代码
    set(flag_var
      CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
      CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
      CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
      CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO
    )

    foreach(variable ${flag_var})
      if(${variable} MATCHES "/MD")
        string(REGEX REPLACE "/MD" "/MT" ${variable} "${${variable}}")
      endif()
    endforeach()
  endif()
endif(WIN32 AND MSVC)
