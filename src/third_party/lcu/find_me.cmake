

# 下面几种写法均可. 根据需求选择简易写法还是复杂写法。
set(_LIB_NAME "lcu")
set(_LIB_IS_SHARED ${PRJ_THIRD_LIB_SHARED})
#set(_LIB_IS_SHARED ON)
#set(_relative_lib_dirs "lib/${PLATFORM_TOLOWER}/${PLATFORM_ABI_TOLOWER}_${CMAKE_BUILD_TYPE_TOLOWER}" 
#                       "lib/${PLATFORM_TOLOWER}/${PLATFORM_ABI_TOLOWER}_release")
#find_lib(${_LIB_NAME} ${_LIB_IS_SHARED} "${CMAKE_CURRENT_LIST_DIR}" _relative_lib_dirs)

find_lib_easy(${_LIB_NAME} ${_LIB_IS_SHARED} ${CMAKE_CURRENT_LIST_DIR})


# 由于lcu依赖pthread和android log, 这里查找其依赖并加入到当前库列表中(${_LIB_NAME}-lib)
set(${_LIB_NAME}_DEPENDS_SYS "")
if (UNIX)
  find_package(Threads REQUIRED)
  list(APPEND ${_LIB_NAME}_DEPENDS_SYS ${CMAKE_THREAD_LIBS_INIT})
  if (ANDROID)
    list(APPEND ${_LIB_NAME}_DEPENDS_SYS log) # <-- lcu 依赖android log打印库
  endif(ANDROID)
elseif(MSVC)
  if (NOT ${_LIB_IS_SHARED}) # <-- lcu静态库，windows 下 lcu_a.a 还需依赖 pthread_lib.lib 静态库
    if (("${${_LIB_NAME}-lib-dir}" STREQUAL "") OR (NOT EXISTS "${${_LIB_NAME}-lib-dir}"))
      message(FATAL_ERROR "${_LIB_NAME}-lib-dir=\"${${_LIB_NAME}-lib-dir}\"  NOT EXISTS!!! check it!")
    endif()
    list(APPEND ${_LIB_NAME}_DEPENDS_SYS "${${_LIB_NAME}-lib-dir}/pthread_lib.lib")
  endif()
endif (UNIX)

if (${_LIB_NAME}_DEPENDS_SYS)
  # 将本库依赖的系统库添加到当前库列表中，并将变量反馈到父模块。
  # 这样父模块只需要依赖变量 ${_LIB_NAME}-lib 就可以获取此库的所有依赖。
  list(APPEND ${_LIB_NAME}-lib "${${_LIB_NAME}_DEPENDS_SYS}")
  set(${_LIB_NAME}-lib "${${_LIB_NAME}-lib}" PARENT_SCOPE) # <-- 反馈到父级模块
endif()

message(STATUS "find_me(${_LIB_NAME}) show: ${_LIB_NAME}-lib=${${_LIB_NAME}-lib}, ${_LIB_NAME}-inc=${${_LIB_NAME}-inc}, ${_LIB_NAME}-asset=${${_LIB_NAME}-asset}")
