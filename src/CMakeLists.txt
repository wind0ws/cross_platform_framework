

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/common")

#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/work_flow")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/api")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/example")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/jni")

set(_ALL_IN_ONE_DEP_MODULE ${CMAKE_PROJECT_NAME}::api)
if (ANDROID)
  set(_ALL_IN_ONE_DEP_MODULE ${CMAKE_PROJECT_NAME}::jni)
endif(ANDROID)
message(STATUS "_ALL_IN_ONE_DEP_MODULE => ${_ALL_IN_ONE_DEP_MODULE}")


if(PRJ_BUILD_ALL_IN_ONE)
   # 查找当前目录和子目录所有源文件并他们的的文件名储存到变量 CUR_SRCS
   #aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/ CUR_SRCS)
   # 收集当前目录(不包含子目录)的源文件
   #file(GLOB _SRCS "${CMAKE_CURRENT_SOURCE_DIR}/*.c" "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/*.hpp")
   #file(GLOB _HDRS "${CMAKE_CURRENT_SOURCE_DIR}/*.h")
   set(_SRCS "modules.c")
   
    prj_cc_library(
        NAME
          ${CMAKE_PROJECT_NAME} # <-- 使用项目名作为 target 名称，不会在 target 名称前面再次追加 CMAKE_PROJECT_NAME
        HDRS
          #${_HDRS} # <-- 当前目录不需要显式添加，会在 prj_cc_library function 里自动添加当前目录到 include_directories
        SRCS
          ${_SRCS}
        COPTS # <-- C OPTIONS
          # ${PRJ_COMPILE_OPTIONS} # <-- 若无添加特殊参数需求，无需显式设置，会自动设置此参数，下面CXX同理
        CCOPTS # <-- CXX OPTIONS
          # ${PRJ_CXX_COMPILE_OPTIONS}
        DEPS
          ${_ALL_IN_ONE_DEP_MODULE}
          # ${CMAKE_PROJECT_NAME}::common
          # ${CMAKE_PROJECT_NAME}::api
          # ${CMAKE_PROJECT_NAME}::work_flow
          #${PRJ_DEPENDS_LOG}
        PUBLIC
    )

    if (MSVC AND (NOT CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS))
      set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES LINK_FLAGS "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/exports.def")
    elseif(("${CMAKE_C_VISIBILITY_PRESET}" STREQUAL "hidden") OR ("${CMAKE_CXX_VISIBILITY_PRESET}" STREQUAL "hidden"))
      message(STATUS " !!! decteced visibility=hidden for ${CMAKE_PROJECT_NAME} !!! ")
      # 使用 target_link_options 替代直接设置 LINK_FLAGS，确保与 rpath 设置共存
      target_link_options(${CMAKE_PROJECT_NAME} PRIVATE "LINKER:--version-script=${CMAKE_CURRENT_LIST_DIR}/exports.exp")
    endif()

    # Merge library
    #if (APPLE)
    #    add_custom_command(OUTPUT libmerge.a
    #    COMMAND libtool -static -o libmerge.a $<TARGET_FILE:math> $<TARGET_FILE:nn>
    #    DEPENDS math nn)
    #else()
    #    add_custom_command(OUTPUT libmerge.a
    #    COMMAND ar crsT libmerge.a $<TARGET_FILE:math> $<TARGET_FILE:nn>
    #    DEPENDS math nn)
    #endif()
    #add_custom_target(_merge ALL DEPENDS libmerge.a)

    # ---------------------------------------------------------------------------------------
    # copy "_PRJ_DEPENDENCY_THIRD_LIBS" and "_PRJ_DEPENDENCY_THIRD_ASSETS" to target output dir.
    # ---------------------------------------------------------------------------------------
    copy_dependency_lib_and_asset(${CMAKE_PROJECT_NAME} "../../res")
    
endif(PRJ_BUILD_ALL_IN_ONE)
