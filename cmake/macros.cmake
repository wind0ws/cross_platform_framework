# get git hash
MACRO(get_git_hash _git_hash _work_dir)
  find_package(Git QUIET)
  if(GIT_FOUND)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} log -1 --pretty=format:%h
        OUTPUT_VARIABLE ${_git_hash}
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        WORKING_DIRECTORY ${_work_dir}
      )
	  # message(STATUS "Git found!!! git_hash=${_git_hash}, work_dir=\"${_work_dir}\"")	
	else()
	  message(STATUS "Git not found! can't get_git_hash")
  endif()
ENDMACRO()

# get git branch
MACRO(get_git_branch _git_branch _work_dir)
  find_package(Git QUIET)
  if(GIT_FOUND)
    execute_process(
      COMMAND ${GIT_EXECUTABLE} symbolic-ref --short -q HEAD
      OUTPUT_VARIABLE ${_git_branch}
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_QUIET
      WORKING_DIRECTORY ${_work_dir}
      )
	  # message(STATUS "Git found!!! git_branch=${_git_branch}, work_dir=\"${_work_dir}\"")	
	else()
	  message(STATUS "Git not found! can't get_git_branch")
  endif()
ENDMACRO(get_git_branch)

#
# setup repo info: PRJ_REPO_BRANCH and PRJ_REPO_REVISION,
# and also add repo info to the compile definitions
#
macro(prj_setup_repo_info _work_dir)
  if (NOT PRJ_REPO_BRANCH)
    set(PRJ_REPO_BRANCH "unknown")
    get_git_branch(PRJ_REPO_BRANCH ${_work_dir})
  endif()
  if (NOT PRJ_REPO_REVISION)
    set(PRJ_REPO_REVISION "unknown")
    get_git_hash(PRJ_REPO_REVISION ${_work_dir})
  endif()
  message(STATUS "repo info: branch=${PRJ_REPO_BRANCH}, revision=${PRJ_REPO_REVISION}")
  add_compile_definitions(
    PRJ_REPO_BRANCH="${PRJ_REPO_BRANCH}"
    PRJ_REPO_REVISION="${PRJ_REPO_REVISION}"
  )
endmacro(prj_setup_repo_info)

#扫描指定scan_dir 目录及其子目录下的 .h 文件所在目录，存放到 return_list 中
MACRO(scan_header_dirs _scan_dir _return_list)
  FILE(GLOB_RECURSE _new_header_list ${_scan_dir}/*.h)
  SET(_dir_list "")
  FOREACH (_file_path ${_new_header_list})
    GET_FILENAME_COMPONENT(dir_path ${_file_path} PATH)
    SET(_dir_list ${_dir_list} ${_dir_path})
  ENDFOREACH ()
  LIST(REMOVE_DUPLICATES _dir_list)
  SET(${_return_list} ${_dir_list})
ENDMACRO(scan_header_dirs)

#
# copy_dir_on_post_build: copy source_folder to target folder
# 
# _target: the name of target
# _target_relative_path: the relative path will append to target dir
# _source_folder: the source folder will read 
#
MACRO(copy_dir_on_post_build _target _target_relative_path _source_folder)
  add_custom_command(TARGET ${_target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      ${_source_folder}/ 
		  $<TARGET_FILE_DIR:${_target}>/${_target_relative_path}
      COMMENT "Copying ${_source_folder} to ${_target} "
  )
ENDMACRO(copy_dir_on_post_build)


# 这里 _src_files 是外部变量名，而不是其引用值，foreach会进行二次解引用
MACRO(copy_file_on_post_build _target _src_files)
	FOREACH (_file_path ${${_src_files}})
		message(STATUS "\"${_target}\" copy_file_on_post_build file_path => \"${_file_path}\"")
		add_custom_command(TARGET ${_target} POST_BUILD        	  # Adds a post-build event to target
		COMMAND ${CMAKE_COMMAND} -E copy_if_different  						# which executes "cmake -E copy_if_different..."
				 ${_file_path}      										    	        # <--this is in-file
				 $<TARGET_FILE_DIR:${_target}>                        # <--this is out-file path
		COMMENT "copy ${_file_path} for ${_target}")        				     	
	ENDFOREACH(_file_path)
ENDMACRO(copy_file_on_post_build)

MACRO(copy_file_on_post_build_to_dir _target _source_file _target_relative_path)
  message(STATUS "\"${_target}\" copy_file_on_post_build_to_dir file_path => \"${_source_file}\", relative_path => \"${_target_relative_path}\"")
  add_custom_command(TARGET ${_target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
      "$<TARGET_FILE_DIR:${_target}>/${_target_relative_path}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${_source_file}"
      "$<TARGET_FILE_DIR:${_target}>/${_target_relative_path}"
    COMMENT "copy ${_source_file} for ${_target}")
ENDMACRO(copy_file_on_post_build_to_dir)


# 注意这里调用这个macro时，_src_files 这里传入的应该是list的变量名，
# 而不是其引用值，因为接下来在另一个macro foreach list会对其二次解引用。
MACRO(copy_file_on_post_build_to_all_targets _src_files)
  get_property(_targets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
  foreach(_target ${_targets})
		message(STATUS "copy file for target(${_target}) ")
		copy_file_on_post_build(${_target} ${_src_files})
  endforeach(_target)
ENDMACRO(copy_file_on_post_build_to_all_targets)


MACRO(source_group_by_dir source_files)
  if(MSVC)
    set(sgbd_cur_dir ${CMAKE_CURRENT_SOURCE_DIR})
    foreach(sgbd_file ${${source_files}})
      string(REGEX REPLACE ${sgbd_cur_dir}/\(.*\) \\1 sgbd_fpath ${sgbd_file})
      string(REGEX REPLACE "\(.*\)/.*" \\1 sgbd_group_name ${sgbd_fpath})
      string(COMPARE EQUAL ${sgbd_fpath} ${sgbd_group_name} sgbd_nogroup)
      string(REPLACE "/" "\\" sgbd_group_name ${sgbd_group_name})
      if(sgbd_nogroup)
          set(sgbd_group_name "\\")
      endif(sgbd_nogroup)
      source_group(${sgbd_group_name} FILES ${sgbd_file})
    endforeach(sgbd_file)
  endif(MSVC)
ENDMACRO(source_group_by_dir)


# Reference:  https://stackoverflow.com/questions/28344564/cmake-remove-a-compile-flag-for-a-single-translation-unit
#
# Applies CMAKE_CXX_FLAGS to all targets in the current CMake directory.
# After this operation, CMAKE_CXX_FLAGS is cleared.
#
macro(apply_global_cxx_flags_to_all_targets)
  separate_arguments(_global_cxx_flags_list UNIX_COMMAND ${CMAKE_CXX_FLAGS})
  get_property(_targets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
  foreach(_target ${_targets})
    target_compile_options(${_target} PUBLIC ${_global_cxx_flags_list})
  endforeach()
  unset(CMAKE_CXX_FLAGS)
  set(_flag_sync_required TRUE)
endmacro(apply_global_cxx_flags_to_all_targets)

#
# Removes the specified compile flag from the specified target.
#   _target     - The target to remove the compile flag from
#   _flag       - The compile flag to remove
#
# Pre: apply_global_cxx_flags_to_all_targets() must be invoked.
#
macro(remove_flag_from_target _target _flag)
  get_target_property(_target_cxx_flags ${_target} COMPILE_OPTIONS)
  if(_target_cxx_flags)
    list(REMOVE_ITEM _target_cxx_flags ${_flag})
    set_target_properties(${_target} PROPERTIES COMPILE_OPTIONS "${_target_cxx_flags}")
  endif()
endmacro(remove_flag_from_target)

#
# Removes the specified compiler flag from the specified file.
#   _target     - The target that _file belongs to
#   _file       - The file to remove the compiler flag from
#   _flag       - The compiler flag to remove.
#
# Pre: apply_global_cxx_flags_to_all_targets() must be invoked.
#
macro(remove_flag_from_file _target _file _flag)
    get_target_property(_target_sources ${_target} SOURCES)
    # Check if a sync is required, in which case we'll force a rewrite of the cache variables.
    if(_flag_sync_required)
        unset(_cached_${_target}_cxx_flags CACHE)
        unset(_cached_${_target}_${_file}_cxx_flags CACHE)
    endif()
    get_target_property(_${_target}_cxx_flags ${_target} COMPILE_OPTIONS)
    # On first entry, cache the target compile flags and apply them to each source file
    # in the target.
    if(NOT _cached_${_target}_cxx_flags)
        # Obtain and cache the target compiler options, then clear them.
        get_target_property(_target_cxx_flags ${_target} COMPILE_OPTIONS)
        set(_cached_${_target}_cxx_flags "${_target_cxx_flags}" CACHE INTERNAL "")
        set_target_properties(${_target} PROPERTIES COMPILE_OPTIONS "")
        # Apply the target compile flags to each source file.
        foreach(_source_file ${_target_sources})
            # Check for pre-existing flags set by set_source_files_properties().
            get_source_file_property(_source_file_cxx_flags ${_source_file} COMPILE_FLAGS)
            if(_source_file_cxx_flags)
                separate_arguments(_source_file_cxx_flags UNIX_COMMAND ${_source_file_cxx_flags})
                list(APPEND _source_file_cxx_flags "${_target_cxx_flags}")
            else()
                set(_source_file_cxx_flags "${_target_cxx_flags}")
            endif()
            # Apply the compile flags to the current source file.
            string(REPLACE ";" " " _source_file_cxx_flags_string "${_source_file_cxx_flags}")
            set_source_files_properties(${_source_file} PROPERTIES COMPILE_FLAGS "${_source_file_cxx_flags_string}")
        endforeach()
    endif()
    list(FIND _target_sources ${_file} _file_found_at)
    if(_file_found_at GREATER -1)
        if(NOT _cached_${_target}_${_file}_cxx_flags)
            # Cache the compile flags for the specified file.
            # This is the list that we'll be removing flags from.
            get_source_file_property(_source_file_cxx_flags ${_file} COMPILE_FLAGS)
            separate_arguments(_source_file_cxx_flags UNIX_COMMAND ${_source_file_cxx_flags})
            set(_cached_${_target}_${_file}_cxx_flags ${_source_file_cxx_flags} CACHE INTERNAL "")
        endif()
        # Remove the specified flag, then re-apply the rest.
        list(REMOVE_ITEM _cached_${_target}_${_file}_cxx_flags ${_flag})
        string(REPLACE ";" " " _cached_${_target}_${_file}_cxx_flags_string "${_cached_${_target}_${_file}_cxx_flags}")
        set_source_files_properties(${_file} PROPERTIES COMPILE_FLAGS "${_cached_${_target}_${_file}_cxx_flags_string}")
    endif()
endmacro(remove_flag_from_file)

#
# set local and parent scopes var.
# make it effective in both local and parent scopes.
#
#   _var:   name of variable
#   _value: value of variable
#
macro(set_local_and_parent_scopes_var _var _value)
  set(${_var} ${_value})
  set(${_var} ${_value} PARENT_SCOPE)
endmacro()

#
# define_dependency_var: define _PRJ_DEPENDENCY_THIRD_LIBS and _PRJ_DEPENDENCY_THIRD_ASSETS var for project
#
macro(define_dependency_var)
  if ((DEFINED _PRJ_DEPENDENCY_THIRD_LIBS) OR (DEFINED _PRJ_DEPENDENCY_THIRD_ASSETS) OR (DEFINED _PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS))
    message(FATAL_ERROR "you are already defined \"_PRJ_DEPENDENCY_THIRD_LIBS\" OR \"_PRJ_DEPENDENCY_THIRD_ASSETS\" OR \"_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS\"")
  endif()
  # ---------------------------------------------------------------------------------------
  # 初始化第三方库依赖列表和依赖资源列表, 后面自行查找的第三方库会被加入到此表中,
  # 最后把这些 第3方库 拷贝到 deploy下的 bin 运行目录中。
  # 这两个变量会在 macros.cmake 中的 find_lib 中被追加。
  # ---------------------------------------------------------------------------------------
  set(_PRJ_DEPENDENCY_THIRD_LIBS "")
  set(_PRJ_DEPENDENCY_THIRD_ASSETS "")
  set(_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS "")
endmacro(define_dependency_var)


#
# filter_dependency_libs_by_copy_mode: 依据依赖库拷贝模式，过滤出真正需要拷贝到部署目录的依赖库。
#   _in_list_var:  输入依赖库列表变量名(全路径, 含静态库/动态库)。
#   _out_list_var: 输出过滤后的依赖库列表变量名。
#
# 规则:
#   - PRJ_DEP_LIB_COPY_MODE=force              : 拷贝全部依赖库(历史行为)。
#   - PRJ_DEP_LIB_COPY_MODE=auto 且本项目产物为动态库: 静态依赖库已链入动态库, 运行期无需拷贝,
#                                                 仅保留动态依赖库(.so/.dylib/.dll);
#                                                 MSVC 的导入库(.lib) 仅链接期需要, 一并剔除。
#   - PRJ_DEP_LIB_COPY_MODE=auto 且本项目产物为静态库: 消费方需静态依赖库参与链接, 保留全部。
#
macro(filter_dependency_libs_by_copy_mode _in_list_var _out_list_var)
  set(_copy_mode "${PRJ_DEP_LIB_COPY_MODE}")
  if("x${_copy_mode}" STREQUAL "x")
    set(_copy_mode "auto")
  endif()
  string(TOLOWER "${_copy_mode}" _copy_mode)

  set(${_out_list_var} "")
  if(("${_copy_mode}" STREQUAL "auto") AND PRJ_BUILD_SHARED)
    # 静态库后缀集合: 非 MSVC 为 .a; MSVC 下 .lib 既是静态库也是 dll 导入库, 均无需拷贝到运行目录。
    set(_static_suffixes "${CMAKE_STATIC_LIBRARY_SUFFIX}")
    foreach(_dep_lib ${${_in_list_var}})
      get_filename_component(_dep_ext "${_dep_lib}" LAST_EXT)
      list(FIND _static_suffixes "${_dep_ext}" _is_static)
      if(_is_static GREATER -1)
        message(STATUS "  [copy-mode=auto,shared] skip static dep lib: ${_dep_lib}")
      else()
        list(APPEND ${_out_list_var} "${_dep_lib}")
      endif()
    endforeach()
  else()
    # force 模式, 或 auto 模式下本项目产物为静态库: 全部拷贝。
    set(${_out_list_var} ${${_in_list_var}})
  endif()
endmacro(filter_dependency_libs_by_copy_mode)


#
# copy_dependency_lib_and_asset: copy dependency lib and asset for target
#     dependency lib will copy to target output dir.
#     dependency asset will copy to relative_path of target output dir.
#
#   _target: the target that will perform copy lib and asset.
#   _target_base_relative_path: asset copy to where, the base relative path will append to target dir
#
macro(copy_dependency_lib_and_asset _target _target_base_relative_path)
  if ((NOT _PRJ_DEPENDENCY_THIRD_LIBS) AND (NOT _PRJ_DEPENDENCY_THIRD_ASSETS) AND (NOT _PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS))
    message(WARNING " maybe \"_PRJ_DEPENDENCY_THIRD_LIBS\" and \"_PRJ_DEPENDENCY_THIRD_ASSETS\" and \"_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS\" not defined, OR nothing we need copy!")
  endif()
  # ---------------------------------------------------------------------------------------
  # 拷贝第三方库文件到部署目录
  # ---------------------------------------------------------------------------------------
  # 依据拷贝模式过滤出真正需要拷贝的依赖库(auto 模式下动态库产物会剔除静态依赖库)
  filter_dependency_libs_by_copy_mode(_PRJ_DEPENDENCY_THIRD_LIBS _PRJ_DEPENDENCY_THIRD_LIBS_TO_COPY)
  list(LENGTH _PRJ_DEPENDENCY_THIRD_LIBS_TO_COPY _PRJ_DEPENDENCY_THIRD_LIBS_TO_COPY_LENGTH)
  message(STATUS "copy mode=${PRJ_DEP_LIB_COPY_MODE}, shared=${PRJ_BUILD_SHARED}, dep libs to copy(${_PRJ_DEPENDENCY_THIRD_LIBS_TO_COPY_LENGTH}) => ${_PRJ_DEPENDENCY_THIRD_LIBS_TO_COPY}")
  if (_PRJ_DEPENDENCY_THIRD_LIBS_TO_COPY_LENGTH GREATER 0)
    message(STATUS "will copy _PRJ_DEPENDENCY_THIRD_LIBS_TO_COPY for you")
    # 这里用的是变量名，而没有引用其值。因为他是macro，在macro里会对其解引用
    copy_file_on_post_build(${_target} _PRJ_DEPENDENCY_THIRD_LIBS_TO_COPY)
  endif()
  
  # ---------------------------------------------------------------------------------------
  # 拷贝第三方库的asset到部署目录
  # ---------------------------------------------------------------------------------------
  list(LENGTH _PRJ_DEPENDENCY_THIRD_ASSETS _PRJ_DEPENDENCY_THIRD_ASSETS_LENGTH)
  message(STATUS "_PRJ_DEPENDENCY_THIRD_ASSETS(${_PRJ_DEPENDENCY_THIRD_ASSETS_LENGTH}) => ${_PRJ_DEPENDENCY_THIRD_ASSETS}")
  if (_PRJ_DEPENDENCY_THIRD_ASSETS_LENGTH GREATER 0)
    message(STATUS "will copy _PRJ_DEPENDENCY_THIRD_ASSETS for you")
    foreach(entry ${_PRJ_DEPENDENCY_THIRD_ASSETS})
      # split key-value. 
      string(REPLACE "=" ";" key_value ${entry})
      list(GET key_value 0 _key)
      list(GET key_value 1 _value)
      #set(_tgt_relative_path "../../res/${_key}")
      set(_tgt_relative_path "${_target_base_relative_path}/${_key}")
      message(STATUS "third_moudle_dir_name = ${_key}, asset_dir = ${_value}, relative_path = ${_tgt_relative_path}")
      copy_dir_on_post_build(${_target} ${_tgt_relative_path} ${_value})
    endforeach()
  endif()

  # ---------------------------------------------------------------------------------------
  # 拷贝第三方库的runtime库到部署目录
  # ---------------------------------------------------------------------------------------
  list(LENGTH _PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS _PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS_LENGTH)
  message(STATUS "_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS(${_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS_LENGTH}) => ${_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS}")
  if (_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS_LENGTH GREATER 0)
    message(STATUS "will copy _PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS for you")
    foreach(entry ${_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS})
      string(REPLACE "|" ";" runtime_lib_info ${entry})
      list(GET runtime_lib_info 0 _runtime_module_name)
      list(GET runtime_lib_info 1 _runtime_platform_dir)
      list(GET runtime_lib_info 2 _runtime_lib_file)
      set(_runtime_tgt_relative_path "${_target_base_relative_path}/${_runtime_module_name}/lib/${_runtime_platform_dir}")
      message(STATUS "third_runtime_module_dir_name = ${_runtime_module_name}, runtime_lib = ${_runtime_lib_file}, relative_path = ${_runtime_tgt_relative_path}")
      copy_file_on_post_build_to_dir(${_target} ${_runtime_lib_file} ${_runtime_tgt_relative_path})
    endforeach()
  endif()
endmacro(copy_dependency_lib_and_asset)


#
# lookup_lib_in_dir: create a var(${_lib_name}-lib) and fill it with lib path. 
#                 check it whether exists, if not exists, fallback to others.
#                 generate 2 variable:
#                    "${_lib_name}-lib": this is full path of lib file.
#                    "${_lib_name}-lib-dir": this is dir of lib.
#  _lib_name: the name of lib, eg. "curl"
#  _lib_file_name: the full file name of lib, eg. "libcurl.a"
#  _lib_dirs: dir list. the dir that will lookup.
#
macro(lookup_lib_in_dir _lib_name _lib_file_name _lib_dir_list)
  # 移除局部的 _lookup_lib_succeed，让外部调用者自己判断
  set(_lib_dirs ${${_lib_dir_list}})
  list(LENGTH _lib_dirs _lib_dirs_list_length)
  if (_lib_dirs_list_length EQUAL 0)
    message(FATAL_ERROR "_lib_dirs is empty!")
  endif()

  foreach(_lib_dir ${_lib_dirs})
    set(${_lib_name}-lib "${_lib_dir}/${_lib_file_name}" CACHE INTERNAL "")
    message(STATUS "  now check lib path: ${${_lib_name}-lib}")
    if(EXISTS "${${_lib_name}-lib}")
      set(${_lib_name}-lib-dir "${_lib_dir}" CACHE INTERNAL "")
      message(STATUS "succeed lookup \"${_lib_name}\" on \"${${_lib_name}-lib}\"")
      break()
    endif()
  endforeach()
endmacro(lookup_lib_in_dir)

#
# get_lib_prefix_suffix: get lib name prefix.
#   _shared: ON for shared lib, OFF for static lib 
#
macro(get_lib_prefix_suffix _shared)
  if(${_shared})
    set(_LIB_PREFIX ${CMAKE_SHARED_LIBRARY_PREFIX})
    set(_LIB_SUFFIX ${CMAKE_SHARED_LIBRARY_SUFFIX})
    if(MSVC)
      # 这里重写 _LIB_SUFFIX: 因为 windows 动态库也是使用对应的 "库名.lib" 来依赖导入dll的。
      # dll不能直接传给linker, 否则报错 LNK1107. 在运行目录下放置对应的dll即可在运行时自动加载.
      set(_LIB_SUFFIX ${CMAKE_STATIC_LIBRARY_SUFFIX}) 
    endif(MSVC)
  else()
    set(_LIB_PREFIX ${CMAKE_STATIC_LIBRARY_PREFIX})
    set(_LIB_SUFFIX ${CMAKE_STATIC_LIBRARY_SUFFIX})
  endif(${_shared})
endmacro(get_lib_prefix_suffix)

#
# standardization_lib_name. 
#  标准化库名称变量名，去除 "lib" 前缀和 "_a", "_static", "_dll" 后缀
#   _name_var: the variable of name.
#
macro(standardization_lib_name _name_var)
  set(_lib_name ${${_name_var}})
  
  # 去除 "lib" 前缀
  if(_lib_name MATCHES "^lib")
    string(REGEX REPLACE "^lib" "" _lib_name "${_lib_name}")
  endif()
  
  # 去除 "_a" 后缀
  if(_lib_name MATCHES "_a$")
    string(REGEX REPLACE "_a$" "" _lib_name "${_lib_name}")
  endif()
  
  # 去除 "_static" 后缀
  if(_lib_name MATCHES "_static$")
    string(REGEX REPLACE "_static$" "" _lib_name "${_lib_name}")
  endif()
  
  # 去除 "_dll" 后缀
  if(_lib_name MATCHES "_dll$")
    string(REGEX REPLACE "_dll$" "" _lib_name "${_lib_name}")
  endif()
  
  set(${_name_var} ${_lib_name})
endmacro(standardization_lib_name)

#
# find_lib: find the given name lib from ${_lib_relative_dir}, 
#           fallback to ${_lib_relative_dir_fallback} if fail.
#           it will generate var "${_lib_name}-lib" and store lib path.
#           also it will generate var "${_lib_name}-inc" and store include header path.
#  _lib_name: the name of lib, not full lib file name. eg: curl
#  _shared:  ON/OFF. find shared lib or static lib.
#  _lib_package_dir: dir of lib package, eg: ${PRJ_SOURCE_DIR}/src/third_party/curl
#  _lib_relative_dir_list: relative dir list variable name, 
#                          eg: "lib/${PLATFORM_TOLOWER}/${PLATFORM_ABI_TOLOWER}_${CMAKE_BUILD_TYPE_TOLOWER}"
#                          and "lib/${PLATFORM_TOLOWER}/${PLATFORM_ABI_TOLOWER}_release"
#
#  example: find_lib("lcu" OFF "${PRJ_SOURCE_DIR}/src/third_party/curl" _lib_relative_dir_list)
#           on android armeabi-v7a debug mode you will get var "lcu-lib" 
#           with it's value will be "${PRJ_SOURCE_DIR}/src/third_party/lcu/lib/android/armeabi-v7a_debug/liblcu_a.a",
#           and "lcu-inc" value will be "${PRJ_SOURCE_DIR}/src/third_party/lcu/include"
#           and "lcu-asset" value will be "${PRJ_SOURCE_DIR}/src/third_party/lcu/asset"
#
macro(find_lib _lib_name _shared _lib_package_dir _lib_relative_dir_list)
  standardization_lib_name(_lib_name)
  message(STATUS "  standardization_lib_name => ${_lib_name}")

  if(NOT "x${${_lib_name}-lib}" STREQUAL "x")
    message(STATUS "${_lib_name}-lib => \"${${_lib_name}-lib}\" is alreay defined. no need lookup again.")
  else()
    message(STATUS "now lookup ${_lib_name} ...")
    if (NOT EXISTS "${_lib_package_dir}")
      message(FATAL_ERROR "can't find lib: ${_lib_name}, because of lib_package_dir(\"${_lib_package_dir}\") not exists!")
    endif()
    
    get_filename_component(_lib_name_alias "${_lib_package_dir}" NAME)  
    message(STATUS "  \"${_lib_name}\" on folder \"${_lib_name_alias}\"")

    # 1. 查找库 路径
    set(_lib_dirs "")
    set(_lib_relative_dirs ${${_lib_relative_dir_list}})
    foreach(_lib_relative_dir ${_lib_relative_dirs})
      list(APPEND _lib_dirs "${_lib_package_dir}/${_lib_relative_dir}")
    endforeach()
    message(STATUS "will lookup _lib_dirs: ${_lib_dirs}")
    
    get_lib_prefix_suffix(${_shared})
    message(STATUS "LIB PREFIX=\"${_LIB_PREFIX}\", SUFFIX=\"${_LIB_SUFFIX}\"")

    set(_lookup_lib_succeed 0)
    if(NOT ${_shared})
      # 目标为静态库的情况下, 先尝试下 "库名字_a" / "库名字_static" 这种静态库存不存在. 若不存在, 后面再尝试 "库名字" 这种静态库.
      # 先尝试 "库名字_a"
      set(_lib_file_name ${_LIB_PREFIX}${_lib_name}_a${_LIB_SUFFIX})
      message(STATUS " ~~~ try lookup for ${_lib_file_name}")
      lookup_lib_in_dir(${_lib_name} ${_lib_file_name} _lib_dirs)
      # lookup_lib_in_dir 宏中的 _lookup_lib_succeed 需要传递出来
      if(EXISTS "${${_lib_name}-lib}")
        set(_lookup_lib_succeed 1)
      endif()
      
      # 如果 "库名字_a" 不存在，再尝试 "库名字_static"
      if(NOT ${_lookup_lib_succeed})
        set(_lib_file_name ${_LIB_PREFIX}${_lib_name}_static${_LIB_SUFFIX})
        message(STATUS " ~~~ try lookup for ${_lib_file_name}")
        lookup_lib_in_dir(${_lib_name} ${_lib_file_name} _lib_dirs)
        if(EXISTS "${${_lib_name}-lib}")
          set(_lookup_lib_succeed 1)
        endif()
      endif()
    endif()
    
    if (NOT ${_lookup_lib_succeed})
      set(_lib_file_name ${_LIB_PREFIX}${_lib_name}${_LIB_SUFFIX})
      message(STATUS " ~~~ lookup for ${_lib_file_name}")
      lookup_lib_in_dir(${_lib_name} ${_lib_file_name} _lib_dirs)
      if(EXISTS "${${_lib_name}-lib}")
        set(_lookup_lib_succeed 1)
      endif()
    endif()

    message(STATUS "${_lib_name}-lib => \"${${_lib_name}-lib}\"")
    if((NOT ${_lookup_lib_succeed}) OR (NOT EXISTS "${${_lib_name}-lib}"))
      message(FATAL_ERROR "lookup \"${_lib_name}\" failed! \"${${_lib_name}-lib}\" not exists! please check the file.")
    endif()
    # windows 动态库还需查找 "库名.lib" 对应依赖的 "库名.dll", 把这个dll库追加到项目列表中供编译后拷贝到运行目录，否则运行报缺dll
    if((DEFINED MSVC) AND (${_shared}))
      #message(STATUS "detect use windows shared libs")
      string(REPLACE ".lib" ".dll" ${_lib_name}-dll "${${_lib_name}-lib}")
      if (NOT EXISTS "${${_lib_name}-dll}")
        message(FATAL_ERROR "\"${${_lib_name}-dll}\" not exists! please check the file.")
      endif()
    endif()
    
    # 2. 查找库 头文件路径(include)
    set(${_lib_name}-inc "${_lib_package_dir}/include" CACHE INTERNAL "") 
    message(STATUS "${_lib_name}-inc => \"${${_lib_name}-inc}\"")
    if (NOT EXISTS "${${_lib_name}-inc}")
      message(FATAL_ERROR "\"${${_lib_name}-inc}\" not exists! did you forgot to copy header? if this lib no need header, just create empty folder for bypass this error")
    endif()
    #include_directories("${${_lib_name}-inc}") # <-- 由用该库的模块手动添加头文件路径
    
    # 3. 查找库 资源文件夹(asset), 如果存在添加键值对到字典中，否则取消这个变量定义 
    set(${_lib_name}-asset "${_lib_package_dir}/asset" CACHE INTERNAL "") 
    message(STATUS "${_lib_name}-asset => \"${${_lib_name}-asset}\"")
    if (EXISTS "${${_lib_name}-asset}")
      message(STATUS "  \"${_lib_name}-asset\" exists!")
      if(DEFINED _PRJ_DEPENDENCY_THIRD_ASSETS)
        message(STATUS "  _PRJ_DEPENDENCY_THIRD_ASSETS is defined, now add \"${_lib_name}-asset\" to dict")
        # cmake字典以分号为分隔符：  a=b;c=d;e=f
        #list(APPEND _PRJ_DEPENDENCY_THIRD_ASSETS ";${_lib_name}=${${_lib_name}-asset}") 
        list(APPEND _PRJ_DEPENDENCY_THIRD_ASSETS ";${_lib_name_alias}=${${_lib_name}-asset}") 
        set(_PRJ_DEPENDENCY_THIRD_ASSETS ${_PRJ_DEPENDENCY_THIRD_ASSETS} PARENT_SCOPE) # <-- 反馈到父级模块
      else()
        message(FATAL_ERROR "\"_PRJ_DEPENDENCY_THIRD_ASSETS\" NOT DEFINED! you should define it on your root CMakeLists.txt")
      endif()
    else()
      unset(${_lib_name}-asset CACHE)  
    endif()
    
    # 4. 把找到的库加入到依赖的三方库list中，供外面做拷贝处理使用。
    if(DEFINED _PRJ_DEPENDENCY_THIRD_LIBS)
      message(STATUS "  _PRJ_DEPENDENCY_THIRD_LIBS is defined, now add \"${_lib_name}-lib\" to list")
      list(APPEND _PRJ_DEPENDENCY_THIRD_LIBS "${${_lib_name}-lib}")
      # MSVC 动态库还需把对应的 dll 也加入到依赖库列表中
      if(DEFINED ${_lib_name}-dll)
        list(APPEND _PRJ_DEPENDENCY_THIRD_LIBS "${${_lib_name}-dll}")
        message(STATUS "  add \"${_lib_name}-dll\"(${${_lib_name}-dll}) to list")
      endif()

      # cmake的变量作用域 只在当前和子模块能感知更新，改也只是对当前和子模块生效，
      # 所以要让上级模块变量也得到更新，需要使用 PARENT_SCOPE
      set(_PRJ_DEPENDENCY_THIRD_LIBS ${_PRJ_DEPENDENCY_THIRD_LIBS} PARENT_SCOPE) # <-- 反馈到父级模块
    else()
      message(FATAL_ERROR "\"_PRJ_DEPENDENCY_THIRD_LIBS\" NOT DEFINED! you should define it on your root CMakeLists.txt")
    endif(DEFINED _PRJ_DEPENDENCY_THIRD_LIBS)
  endif()
endmacro(find_lib) # end of find_lib macro

#
# check_third_party_dir: define PRJ_THIRD_PARTY_DIR and check it path.           
#
macro(check_third_party_dir)
  if (NOT DEFINED PRJ_THIRD_PARTY_DIR)
    if (NOT DEFINED PRJ_SOURCE_DIR)
      message(FATAL_ERROR "you must define \"PRJ_SOURCE_DIR\" first!" )
    endif()
    # 全局缓存 third_party 路径
    set(PRJ_THIRD_PARTY_DIR "${PRJ_SOURCE_DIR}/src/third_party" CACHE STRING "")
    if (NOT EXISTS "${PRJ_THIRD_PARTY_DIR}")
      message(FATAL_ERROR "PRJ_THIRD_PARTY_DIR(\"${PRJ_THIRD_PARTY_DIR}\") not exists!")
    endif()
  endif(NOT DEFINED PRJ_THIRD_PARTY_DIR)
endmacro(check_third_party_dir)

#
# prepend_dir: generate new dirs by ${_suffix} from ${${_relative_dir_list}},
#              and prepend new dirs to origin list head.
# _suffix:     folder suffix, such as "vs2022" or "gnustl_static" 
# _relative_dir_list: list variable name, will generate dir list with suffix 
#                     and prepend new list to this list head.
#
macro(prepend_dir _suffix _relative_dir_list)
  set(_relative_dirs ${${_relative_dir_list}})
  set(_to_prepend_dirs "")
  foreach(_relative_dir ${_relative_dirs})
    list(APPEND _to_prepend_dirs ${_relative_dir}_${_suffix}) # 将带后名称后缀追加到目录名称中
  endforeach()
  list(INSERT _relative_dirs 0 ${_to_prepend_dirs}) # 将新增的带后缀的路径插入到list最前面，供优先查找
endmacro(prepend_dir)

#
# detect_visual_studio_version: detect your vs version and store vs20xx to "_vs_name"
#
macro(detect_visual_studio_version)
  if (MSVC AND ("x${_vs_name}" STREQUAL "x")) # <-- 只查找一次
    set(_vs_name "")
    message(STATUS "  detected your MSVC_VERSION=${MSVC_VERSION}")
    if(${MSVC_VERSION} VERSION_GREATER_EQUAL 1945)      # maybe VS 2024 (version 18.x): 1945~xxxx
       message(FATAL_ERROR "maybe Visual Studio 2024 or newer, should setup vs_name for this version!")
    elseif(${MSVC_VERSION} VERSION_GREATER_EQUAL 1930)  # VS 2022 (version 17.x): 1930~1944
       message(STATUS "Using Visual Studio 2022")
       set(_vs_name "vs2022")
    elseif(${MSVC_VERSION} VERSION_GREATER_EQUAL 1920)  # VS 2019 (version 16.x): 1920~1929
      message(STATUS "Using Visual Studio 2019")
      set(_vs_name "vs2019")
    elseif(${MSVC_VERSION} VERSION_EQUAL 1910)          # VS 2017 (version 15.x): 1910~1919
      message(STATUS "Using Visual Studio 2017")
      set(_vs_name "vs2017")
    elseif(${MSVC_VERSION} VERSION_EQUAL 1900)          # VS 2015 (version 14.x): 1900~1909
      message(STATUS "Using Visual Studio 2015")
      set(_vs_name "vs2015")
    elseif(${MSVC_VERSION} VERSION_EQUAL 1800)          # VS 2013 (version 12.x): 1800~1899
      message(STATUS "Using Visual Studio 2013")
      set(_vs_name "vs2013")
    elseif(${MSVC_VERSION} VERSION_EQUAL 1700)          # VS 2012 (version 11.x): 1700~1799
      message(STATUS "Using Visual Studio 2012")
      set(_vs_name "vs2012")
    else()
      message(FATAL_ERROR "Using an unknown Visual Studio version(${MSVC_VERSION})")
    endif()
  endif()
endmacro(detect_visual_studio_version)

macro(_setup_find_lib_easy_relative_dirs _out_var)
  if ((NOT DEFINED PLATFORM_TOLOWER) OR (NOT DEFINED PLATFORM_ABI_TOLOWER) 
      OR (NOT DEFINED CMAKE_BUILD_TYPE_TOLOWER))
    message(FATAL_ERROR "you must define PLATFORM_TOLOWER and PLATFORM_ABI_TOLOWER and CMAKE_BUILD_TYPE_TOLOWER")
  endif()

  set(_relative_dirs "lib/${PLATFORM_TOLOWER}/${PLATFORM_ABI_TOLOWER}_${CMAKE_BUILD_TYPE_TOLOWER}")
  if (NOT "${CMAKE_BUILD_TYPE_TOLOWER}" STREQUAL "release")
    list(APPEND _relative_dirs "lib/${PLATFORM_TOLOWER}/${PLATFORM_ABI_TOLOWER}_release")
  endif()
  
  # android 平台(且非 c++_static)优先查找 指定的stl类型文件夹. 例如 armeabi-v7a_debug_gnustl_static
  if (ANDROID AND (NOT "${ANDROID_STL}" STREQUAL "c++_static"))
    message(STATUS "detected your ANDROID_STL=${ANDROID_STL}")
    prepend_dir(${ANDROID_STL} _relative_dirs)
  elseif(MSVC)  # msvc 平台优先查找 指定vs版本文件夹. 例如 x32_debug_vs2022
    detect_visual_studio_version()
    prepend_dir(${_vs_name} _relative_dirs)
  endif()

  set(${_out_var} ${_relative_dirs})
endmacro(_setup_find_lib_easy_relative_dirs)

macro(_reset_find_lib_easy_cache _lib_name)
  unset(${_lib_name}-lib CACHE)
  unset(${_lib_name}-lib-dir CACHE)
  unset(${_lib_name}-dll CACHE)
  unset(${_lib_name}-inc CACHE)
  unset(${_lib_name}-asset CACHE)
  unset(${_lib_name}-runtime-lib CACHE)
  unset(${_lib_name}-runtime-lib-dir CACHE)
  unset(${_lib_name}-runtime-module-dir CACHE)
  unset(${_lib_name}-runtime-platform-dir CACHE)
  unset(${_lib_name}-runtime-lib-file-name CACHE)
  unset(${_lib_name}-runtime-res-relative-path CACHE)
  unset(${_lib_name}-runtime-enabled CACHE)
endmacro(_reset_find_lib_easy_cache)

macro(_sync_find_lib_easy_dep_mode _lib_name _dep_mode)
  if((DEFINED ${_lib_name}-dep-mode) AND (NOT "${${_lib_name}-dep-mode}" STREQUAL "${_dep_mode}"))
    message(STATUS "${_lib_name} dependency mode changed: ${${_lib_name}-dep-mode} -> ${_dep_mode}, reset cached lookup vars")
    _reset_find_lib_easy_cache(${_lib_name})
  endif()
  set(${_lib_name}-dep-mode "${_dep_mode}" CACHE INTERNAL "")
endmacro(_sync_find_lib_easy_dep_mode)

macro(_find_lib_easy_link_impl _lib_name _shared _lib_package_dir)
  _setup_find_lib_easy_relative_dirs(_relative_dirs)
  message(STATUS "\"${_lib_name}\" will lookup in relative_dirs: ${_relative_dirs}")
  find_lib(${_lib_name} ${_shared} ${_lib_package_dir} _relative_dirs)
  set(${_lib_name}-runtime-enabled OFF CACHE INTERNAL "")
endmacro(_find_lib_easy_link_impl)

macro(_find_runtime_lib_easy _lib_name _lib_package_dir)
  standardization_lib_name(_lib_name)

  if("x${_lib_package_dir}" STREQUAL "x")
    check_third_party_dir()
    set(_lib_package_dir "${PRJ_THIRD_PARTY_DIR}/${_lib_name}")
  elseif(NOT EXISTS "${_lib_package_dir}")
    message(FATAL_ERROR " \"${_lib_package_dir}\" not exists! check it.")
  endif()

  get_filename_component(_lib_name_alias "${_lib_package_dir}" NAME)
  _setup_find_lib_easy_relative_dirs(_relative_dirs)

  if(MSVC)
    set(_runtime_lib_prefix "")
    set(_runtime_lib_suffix ".dll")
  else()
    set(_runtime_lib_prefix "${CMAKE_SHARED_LIBRARY_PREFIX}")
    set(_runtime_lib_suffix "${CMAKE_SHARED_LIBRARY_SUFFIX}")
  endif()

  set(_runtime_lib_file_name "${_runtime_lib_prefix}${_lib_name}${_runtime_lib_suffix}")
  set(_runtime_lookup_succeed 0)
  foreach(_lib_relative_dir ${_relative_dirs})
    set(_runtime_lib_path "${_lib_package_dir}/${_lib_relative_dir}/${_runtime_lib_file_name}")
    message(STATUS "  now check runtime lib path: ${_runtime_lib_path}")
    if(EXISTS "${_runtime_lib_path}")
      set(_runtime_lookup_succeed 1)
      string(REGEX REPLACE "^lib/" "" _runtime_platform_dir "${_lib_relative_dir}")
      set(${_lib_name}-runtime-lib "${_runtime_lib_path}" CACHE INTERNAL "")
      set(${_lib_name}-runtime-lib-dir "${_lib_package_dir}/${_lib_relative_dir}" CACHE INTERNAL "")
      set(${_lib_name}-runtime-module-dir "${_lib_name_alias}" CACHE INTERNAL "")
      set(${_lib_name}-runtime-platform-dir "${_runtime_platform_dir}" CACHE INTERNAL "")
      set(${_lib_name}-runtime-lib-file-name "${_runtime_lib_file_name}" CACHE INTERNAL "")
      set(${_lib_name}-runtime-res-relative-path "${_lib_name_alias}/lib/${_runtime_platform_dir}/${_runtime_lib_file_name}" CACHE INTERNAL "")
      break()
    endif()
  endforeach()

  if((NOT ${_runtime_lookup_succeed}) OR (NOT EXISTS "${${_lib_name}-runtime-lib}"))
    message(FATAL_ERROR "lookup runtime lib \"${_lib_name}\" failed! \"${_runtime_lib_file_name}\" not exists! please check the file.")
  endif()

  set(${_lib_name}-lib "" CACHE INTERNAL "")
  set(${_lib_name}-inc "${_lib_package_dir}/include" CACHE INTERNAL "")
  message(STATUS "${_lib_name}-inc => \"${${_lib_name}-inc}\"")
  if (NOT EXISTS "${${_lib_name}-inc}")
    message(FATAL_ERROR "\"${${_lib_name}-inc}\" not exists! did you forgot to copy header? if this lib no need header, just create empty folder for bypass this error")
  endif()

  set(${_lib_name}-asset "${_lib_package_dir}/asset" CACHE INTERNAL "")
  message(STATUS "${_lib_name}-asset => \"${${_lib_name}-asset}\"")
  if (EXISTS "${${_lib_name}-asset}")
    if(DEFINED _PRJ_DEPENDENCY_THIRD_ASSETS)
      list(APPEND _PRJ_DEPENDENCY_THIRD_ASSETS ";${_lib_name_alias}=${${_lib_name}-asset}")
      set(_PRJ_DEPENDENCY_THIRD_ASSETS ${_PRJ_DEPENDENCY_THIRD_ASSETS} PARENT_SCOPE)
    else()
      message(FATAL_ERROR "\"_PRJ_DEPENDENCY_THIRD_ASSETS\" NOT DEFINED! you should define it on your root CMakeLists.txt")
    endif()
  else()
    unset(${_lib_name}-asset CACHE)
  endif()

  if(DEFINED _PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS)
    list(APPEND _PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS "${_lib_name_alias}|${${_lib_name}-runtime-platform-dir}|${${_lib_name}-runtime-lib}")
    set(_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS ${_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS} PARENT_SCOPE)
  else()
    message(FATAL_ERROR "\"_PRJ_DEPENDENCY_THIRD_RUNTIME_LIBS\" NOT DEFINED! you should define it on your root CMakeLists.txt")
  endif()

  set(${_lib_name}-runtime-enabled ON CACHE INTERNAL "")
  message(STATUS "${_lib_name}-runtime-lib => \"${${_lib_name}-runtime-lib}\"")
  message(STATUS "${_lib_name}-runtime-res-relative-path => \"${${_lib_name}-runtime-res-relative-path}\"")
endmacro(_find_runtime_lib_easy)

macro(define_find_lib_easy_shared_mode _out_var _cache_var)
  if(${ARGC} GREATER 2)
    set(_shared_mode_default "${ARGV2}")
  else()
    set(_shared_mode_default "${${_out_var}}")
  endif()
  if("x${_shared_mode_default}" STREQUAL "x")
    set(_shared_mode_default "LINK")
  endif()
  string(TOUPPER "${_shared_mode_default}" _shared_mode_default)
  if((NOT "${_shared_mode_default}" STREQUAL "LINK") AND (NOT "${_shared_mode_default}" STREQUAL "RUNTIME"))
    message(FATAL_ERROR "invalid default shared mode \"${_shared_mode_default}\", should be LINK or RUNTIME")
  endif()

  set(${_cache_var} "${_shared_mode_default}" CACHE STRING "${_cache_var}: LINK or RUNTIME")
  set_property(CACHE ${_cache_var} PROPERTY STRINGS LINK RUNTIME)

  set(${_out_var} "${${_cache_var}}")
  if("x${${_out_var}}" STREQUAL "x")
    set(${_out_var} "${_shared_mode_default}")
  endif()
  string(TOUPPER "${${_out_var}}" ${_out_var})
  if((NOT "${${_out_var}}" STREQUAL "LINK") AND (NOT "${${_out_var}}" STREQUAL "RUNTIME"))
    message(FATAL_ERROR "invalid shared mode \"${${_out_var}}\" from ${_cache_var}, should be LINK or RUNTIME")
  endif()
  set(${_cache_var} "${${_out_var}}" CACHE STRING "${_cache_var}: LINK or RUNTIME" FORCE)
endmacro(define_find_lib_easy_shared_mode)

macro(make_runtime_lib_compile_definitions _out_var _prefix _lib_name)
  set(${_out_var} "")
  standardization_lib_name(_lib_name)
  if((DEFINED ${_lib_name}-runtime-enabled) AND (${${_lib_name}-runtime-enabled}))
    list(APPEND ${_out_var}
      ${_prefix}_RUNTIME_LOAD=1
      ${_prefix}_RUNTIME_MODULE_DIR_NAME=\"${${_lib_name}-runtime-module-dir}\"
      ${_prefix}_RUNTIME_PLATFORM_DIR=\"${${_lib_name}-runtime-platform-dir}\"
      ${_prefix}_RUNTIME_LIB_FILE_NAME=\"${${_lib_name}-runtime-lib-file-name}\"
      ${_prefix}_RUNTIME_RES_RELATIVE_PATH=\"${${_lib_name}-runtime-res-relative-path}\")
  else()
    list(APPEND ${_out_var}
      ${_prefix}_RUNTIME_LOAD=0)
  endif()
endmacro(make_runtime_lib_compile_definitions)

macro(show_find_lib_easy_result _lib_name)
  standardization_lib_name(_lib_name)
  message(STATUS "find_me(${_lib_name}) show: ${_lib_name}-lib=${${_lib_name}-lib}, ${_lib_name}-inc=${${_lib_name}-inc}, ${_lib_name}-asset=${${_lib_name}-asset}")
  if((DEFINED ${_lib_name}-runtime-enabled) AND (${${_lib_name}-runtime-enabled}))
    message(STATUS "find_me(${_lib_name}) runtime: enabled=${${_lib_name}-runtime-enabled}, lib=${${_lib_name}-runtime-lib}, res_relative_path=${${_lib_name}-runtime-res-relative-path}")
  endif()
endmacro(show_find_lib_easy_result)

#
# find_lib_easy_by_dep_mode: helper for find_lib with dynamic-library dep mode.
#
# _lib_name: the name of lib that you want to lookup. eg: "curl"
# _shared: ON/OFF. ON for find shared lib, OFF for find static lib.
# _lib_package_dir: base folder for the "_lib_name".
# _shared_mode: LINK/RUNTIME. Only used when _shared is ON. Default is LINK.
#
macro(find_lib_easy_by_dep_mode _lib_name _shared _lib_package_dir)
  standardization_lib_name(_lib_name)

  if("x${_lib_package_dir}" STREQUAL "x")
    check_third_party_dir()
    set(_lib_package_dir "${PRJ_THIRD_PARTY_DIR}/${_lib_name}")
  elseif(NOT EXISTS "${_lib_package_dir}")
    message(FATAL_ERROR " \"${_lib_package_dir}\" not exists! check it.")
  endif()

  set(_shared_mode "LINK")
  if(${ARGC} GREATER 3)
    set(_shared_mode "${ARGV3}")
  endif()
  if("x${_shared_mode}" STREQUAL "x")
    set(_shared_mode "LINK")
  endif()
  string(TOUPPER "${_shared_mode}" _shared_mode)

  if(NOT ${_shared})
    set(_effective_dep_mode "STATIC")
  else()
    if((NOT "${_shared_mode}" STREQUAL "LINK") AND (NOT "${_shared_mode}" STREQUAL "RUNTIME"))
      message(FATAL_ERROR "invalid shared mode \"${_shared_mode}\" for ${_lib_name}, should be LINK or RUNTIME")
    endif()
    set(_effective_dep_mode "${_shared_mode}")
  endif()

  _sync_find_lib_easy_dep_mode(${_lib_name} ${_effective_dep_mode})

  if("${_effective_dep_mode}" STREQUAL "RUNTIME")
    _find_runtime_lib_easy(${_lib_name} ${_lib_package_dir})
  else()
    _find_lib_easy_link_impl(${_lib_name} ${_shared} ${_lib_package_dir})
  endif()
endmacro(find_lib_easy_by_dep_mode)

#
# find_lib_easy: helper for find_lib.
#                find a library with a given name from the subdirectories of a given directory.
#
# _lib_name: the name of lib that you want to lookup. eg: "curl"
# _shared: ON/OFF. ON for find shared lib, OFF for find static lib.
# _lib_package_dir: base folder for the "_lib_name".
#                   eg. "curl" maybe provide package dir with "${PRJ_THIRD_PARTY_DIR}/curl"
# _shared_mode: optional LINK/RUNTIME. Only used when _shared is ON. 
#
macro(find_lib_easy _lib_name _shared _lib_package_dir)
  set(_shared_mode "") # <-- let find_lib_easy_by_dep_mode to decide default shared mode.
  if(${ARGC} GREATER 3)
    set(_shared_mode "${ARGV3}")
  endif()
  find_lib_easy_by_dep_mode(${_lib_name} ${_shared} ${_lib_package_dir} ${_shared_mode})
endmacro(find_lib_easy)
