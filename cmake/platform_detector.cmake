
#============================= setup output dir START =============================
IF (NOT DEFINED PLATFORM OR ("x${PLATFORM}" STREQUAL "x"))
  if ((NOT ("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")) OR (NOT ("${CMAKE_SYSTEM_NAME}" STREQUAL "Generic")))
    if (DEFINED ANDROID_ABI)
      set(PLATFORM Android)
    elseif(DEFINED WIN32)
      set(PLATFORM Windows)
    else()
      MESSAGE(WARNING "not defined PLATFORM, use CMAKE_SYSTEM_NAME(${CMAKE_SYSTEM_NAME}) as PLATFORM")
      set(PLATFORM ${CMAKE_SYSTEM_NAME})
    endif()
  else()
    MESSAGE(FATAL_ERROR "PLATFORM can not be empty! current CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}")
  endif()
ELSE()
  MESSAGE(STATUS "your PLATFORM = ${PLATFORM}")
ENDIF()
#detect current PLATFORM_ABI
IF(DEFINED PLATFORM_ABI)
  message(STATUS "your PLATFORM_ABI = ${PLATFORM_ABI}")
ELSEIF(ANDROID)
  set(PLATFORM_ABI ${ANDROID_ABI})
  # ANDROID_PLATFORM_LEVEL: such as 16/19/21
  add_compile_definitions(ANDROID_PLATFORM_LEVEL=${ANDROID_PLATFORM_LEVEL})
ELSE()
  IF(CMAKE_CL_64)
    if((CMAKE_C_FLAGS MATCHES "m32") OR (CMAKE_SIZEOF_VOID_P EQUAL 4))
      message(STATUS "CL64 detect m32 in flags OR (VOID_P == 4), PLATFORM_ABI is x32")
      set(PLATFORM_ABI x32)
    else()
      message(STATUS "normal x64")
      set(PLATFORM_ABI x64)
    endif()
  ELSE(CMAKE_CL_64)
    if((CMAKE_C_FLAGS MATCHES "m64") OR (CMAKE_SIZEOF_VOID_P EQUAL 8))
      message(STATUS "CL32 detect m64 in flags OR (VOID_P == 8), PLATFORM_ABI is x64")
      set(PLATFORM_ABI x64)
    else()
      message(STATUS "normal x32")
      set(PLATFORM_ABI x32)
    endif()
  ENDIF(CMAKE_CL_64)
ENDIF(DEFINED PLATFORM_ABI)
string(TOLOWER "${PLATFORM}" PLATFORM_TOLOWER)
string(TOLOWER "${PLATFORM_ABI}" PLATFORM_ABI_TOLOWER)
string(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_TOLOWER)
# define PLATFORM info on code
add_compile_definitions(
  _PLATFORM="${PLATFORM}"
  _PLATFORM_ABI="${PLATFORM_ABI}"
)

if (DEFINED(ANDROID) AND ("${ANDROID_ABI}" MATCHES "x86_64"))
  message(STATUS "it is android-x86_64. let's append CMAKE_SYSTEM_LIBRARY_PATH for fix lib not found error in cmake")
  list(APPEND CMAKE_SYSTEM_LIBRARY_PATH "${ANDROID_SYSTEM_LIBRARY_PATH}/usr/lib64")
  set(CMAKE_SYSTEM_LIBRARY_PATH ${CMAKE_SYSTEM_LIBRARY_PATH} PARENT_SCOPE)
  message(STATUS "current CMAKE_SYSTEM_LIBRARY_PATH => ${CMAKE_SYSTEM_LIBRARY_PATH}")
elseif(WIN32)
  # for export all symbols on windows 
  # cmake -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE -DBUILD_SHARED_LIBS=TRUE
  option(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS "export dll ALL_SYMBOLS" OFF)
endif()


if (DEFINED DEPLOY_DIR)
  message(STATUS "you defined DEPLOY_DIR => ${DEPLOY_DIR}")
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${DEPLOY_DIR})
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${DEPLOY_DIR})
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${DEPLOY_DIR})
else()
  if (NOT DEFINED PRJ_OUTPUT_DIR)
    message(FATAL_ERROR "you must defined PRJ_OUTPUT_DIR variable first!")
  endif()
  set(_APPEND_PATH_FOR_OUTPUT_DIR "")
  if(ANDROID)
    string(TOLOWER "${ANDROID_STL}" ANDROID_STL_TOLOWER)
    set(_APPEND_PATH_FOR_OUTPUT_DIR "_${ANDROID_STL_TOLOWER}")
  endif(ANDROID)
  set(ALL_CONFIG_TYPES "DEBUG" "RELEASE" "RELWITHDEBINFO" "MINSIZEREL")
  foreach(cfg ${ALL_CONFIG_TYPES})
    string(TOLOWER "${cfg}" _CFG_TYPE_TOLOWER)
    set(_output_dir_tmp "${PRJ_OUTPUT_DIR}/bin/${PLATFORM_TOLOWER}_${PLATFORM_ABI_TOLOWER}_${_CFG_TYPE_TOLOWER}${_APPEND_PATH_FOR_OUTPUT_DIR}")
    message(STATUS "setup OUTPUT_DIRECTORY for ${cfg} -> ${_output_dir_tmp}")
    # bin, executeable
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${cfg} ${_output_dir_tmp})
    # shared libs
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${cfg} ${_output_dir_tmp})
    # static libs
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${cfg} ${_output_dir_tmp})
  endforeach()
endif()

#============================= setup output dir END =============================

# ---------------------------------------------------------------------------------------
# setup common flags
# ---------------------------------------------------------------------------------------
IF ( WIN32 AND NOT CYGWIN AND NOT ( CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" ) AND NOT ANDROID)
  # suppress warnings for VS: 
  # C4001：single line comment warning
  # C4711：warning of function 'function' selected for inline expansion
  # C4819: utf8 coding page warning
  # C4820: 'bytes' bytes padding added after construct 'member_name'
  # C5045: compiler will insert Spectre mitigation for memory load if /Qspectre switch specified
  # C5105: winbase.h undefined behavior warning
  add_compile_options( /wd4001 /wd4711 /wd4819 /wd4820 /wd5045 /wd5105 )
  #add optimiziation options
  add_compile_options(/bigobj /nologo /EHsc /GF /MP)
  #solution folder
  #set_property(GLOBAL PROPERTY USE_FOLDERS ON)
  #put ZERO_CHECK/ALL_BUILD in all_targets folder
  #set_property(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "all_targets")
  
  string(APPEND CMAKE_C_FLAGS_RELEASE        " /Ot /MT")
  string(APPEND CMAKE_C_FLAGS_DEBUG          " /MTd /DEBUG")
  string(APPEND CMAKE_CXX_FLAGS_RELEASE      " /Ot /MT")
  string(APPEND CMAKE_CXX_FLAGS_DEBUG        " /MTd /DEBUG /Zi")
  #string(APPEND CMAKE_C_FLAGS_DEBUG   " -fsanitize=address,undefined") 
  #string(APPEND CMAKE_CXX_FLAGS_DEBUG " -fsanitize=address,undefined") 

  set(COMMON_C_FLGAS   " /utf-8 /W3 ")
  set(COMMON_CXX_FLAGS "")
  set(COMMON_EXE_LINKER_FLAGS "/ignore:4099")  # Ignore warnings about missing pdb: 4099 
  set(COMMON_SHARED_LINKER_FLAGS "${COMMON_EXE_LINKER_FLAGS}")
  set(COMMON_STATIC_LINKER_FLAGS "${COMMON_EXE_LINKER_FLAGS}")
ELSE() 
  set(COMMON_C_FLGAS " -Wall -Wno-unused-local-typedefs -Wno-unused-function -Wno-comment -Wno-unknown-pragmas -fPIC")
  set(COMMON_CXX_FLAGS " -Wno-write-strings")
  # Android 5.0 及以上需要设置 PIE, 为啥不设置-fPIC, 因为已经 set(POSITION_INDEPENDENT_CODE TRUE)
  set(COMMON_EXE_LINKER_FLAGS "-fPIE")
  set(COMMON_SHARED_LINKER_FLAGS "${COMMON_EXE_LINKER_FLAGS}")
  set(COMMON_STATIC_LINKER_FLAGS "")
  #add _GNU_SOURCE for pthread_setname_np
  #add_compile_definitions(_GNU_SOURCE=1)
ENDIF()

string(APPEND CMAKE_C_FLAGS   "${COMMON_C_FLGAS}")
string(APPEND CMAKE_CXX_FLAGS "${COMMON_C_FLGAS} ${COMMON_CXX_FLGAS}")
string(APPEND CMAKE_EXE_LINKER_FLAGS " ${COMMON_EXE_LINKER_FLAGS}")
string(APPEND CMAKE_SHARED_LINKER_FLAGS " ${COMMON_SHARED_LINKER_FLAGS}")
if (COMMON_STATIC_LINKER_FLAGS)
  string(APPEND CMAKE_STATIC_LINKER_FLAGS " ${COMMON_STATIC_LINKER_FLAGS}")
endif()

# ---------------------------------------------------------------------------------------
# replace MD to MT
# ---------------------------------------------------------------------------------------
IF (WIN32 AND MSVC)
    set(flag_var
            CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
            CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
            CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO
            )

    foreach (variable ${flag_var})
        if (${variable} MATCHES "/MD")
            string(REGEX REPLACE "/MD" "/MT" ${variable} "${${variable}}")
        endif ()
    endforeach ()

    #foreach(tgt_name ${target_names})
    #    set_property(TARGET ${tgt_name} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    #    set_property(TARGET ${tgt_name} PROPERTY VS_DEBUGGER_WORKING_DIRECTORY "${PRJ_OUTPUT_DIR}")
    #endforeach()
    #set_property(TARGET ${target_prj_demo} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
ENDIF (WIN32 AND MSVC) 
