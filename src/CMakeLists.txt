
#find_lib_easy("lcu" ON)
#message(STATUS "src show: lcu-lib=${lcu-lib}, lcu-inc=${lcu-inc}, lcu-asset=${lcu-asset}")


add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/common")
#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/jni")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/api")
#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/work_flow")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/example")


if(PRJ_BUILD_ALL_IN_ONE)
   # 查找当前目录和子目录所有源文件并他们的的文件名储存到变量 CUR_SRCS
   #aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/ CUR_SRCS)
   # 收集当前目录(不包含子目录)的源文件
   file(GLOB CUR_SRCS "${CMAKE_CURRENT_SOURCE_DIR}/*.c" "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/*.hpp")
   #file(GLOB CUR_HDRS "${CMAKE_CURRENT_SOURCE_DIR}/*.h")
   #message(STATUS "src show: lcu-lib=${lcu-lib}, lcu-inc=${lcu-inc}")
   
    prj_cc_library(
        NAME
          ${CMAKE_PROJECT_NAME}
        HDRS
          #${CUR_HDRS} #<-- 当前目录不需要显式添加，会在function里自动添加
          #${lcu-inc}
        SRCS
          ${CUR_SRCS}
        COPTS # <-- C OPTIONS
          ${PRJ_COMPILE_OPTIONS}
        CCOPTS # <-- CXX OPTIONS
          ${PRJ_CXX_COMPILE_OPTIONS}
        DEPS
          ${CMAKE_PROJECT_NAME}::common
          #${CMAKE_PROJECT_NAME}::jni
          ${CMAKE_PROJECT_NAME}::api
          #${CMAKE_PROJECT_NAME}::work_flow
          #${PRJ_DEPENDS_LOG}
          #${lcu-lib}
        PUBLIC
    )

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
    # 拷贝第三方库文件到部署目录
    # ---------------------------------------------------------------------------------------
    list(LENGTH _PRJ_DEPENDENCY_THIRD_LIBS _PRJ_DEPENDENCY_THIRD_LIBS_LENGTH)
    message(STATUS "_PRJ_DEPENDENCY_THIRD_LIBS(${_PRJ_DEPENDENCY_THIRD_LIBS_LENGTH}) => ${_PRJ_DEPENDENCY_THIRD_LIBS}")
    if (_PRJ_DEPENDENCY_THIRD_LIBS_LENGTH GREATER 0)
      message(STATUS "will copy _PRJ_DEPENDENCY_THIRD_LIBS for you")
      # 这里用的是变量名，而没有引用其值。因为他是macro，在macro里会对其解引用
      copy_file_on_post_build(${CMAKE_PROJECT_NAME} _PRJ_DEPENDENCY_THIRD_LIBS)
    endif()
    
    # ---------------------------------------------------------------------------------------
    # 拷贝第三方库的asset到部署目录
    # ---------------------------------------------------------------------------------------
    list(LENGTH _PRJ_DEPENDENCY_THIRD_ASSETS _PRJ_DEPENDENCY_THIRD_ASSETS_LENGTH)
    message(STATUS "_PRJ_DEPENDENCY_THIRD_ASSETS(${_PRJ_DEPENDENCY_THIRD_ASSETS_LENGTH}) => ${_PRJ_DEPENDENCY_THIRD_ASSETS}")
    if (_PRJ_DEPENDENCY_THIRD_ASSETS_LENGTH GREATER 0)
      message(STATUS "will copy _PRJ_DEPENDENCY_THIRD_ASSETS for you")
      foreach(entry ${_PRJ_DEPENDENCY_THIRD_ASSETS})
        # 将每个键值对拆分为键和值
        string(REPLACE "=" ";" key_value ${entry})
        list(GET key_value 0 _key)
        list(GET key_value 1 _value)
        set(_tgt_relative_path "../../res/${_key}")
        message(STATUS "third_moudle_name = ${_key}, asset = ${_value}, relative_path = ${_tgt_relative_path}")
        copy_dir_on_post_build(${CMAKE_PROJECT_NAME} ${_tgt_relative_path} ${_value})
      endforeach()
    endif()
endif()


