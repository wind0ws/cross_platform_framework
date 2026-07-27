# ---------------------------------------------------------------------------------------
# compiler_config.cmake — 编译器语言标准与特性检测
#
# 职责：统一设置 C/C++ 语言标准，并探测编译器可选特性。
# 时序：必须在 project() 之后 include —— 本文件依赖 project() 填充的
#       CMAKE_CXX_COMPILE_FEATURES；仅使用 CMake 内置变量，不依赖任何 PRJ_* option。
#       导出的 PRJ_C_STANDARD / PRJ_CXX_STANDARD / PRJ_REQUIRED_FEATURES
#       在 add_subdirectory 期间被 batch_setup_target_properties 等消费。
# ---------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------
# 语言标准：未显式指定时默认 C11 / C++11
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
# cxx_variadic_templates: 在 C++11 中，引入了可变模板（Variadic Templates）的概念，
# 它允许函数或类模板接受可变数量的类型参数
# ---------------------------------------------------------------------------------------
list(FIND CMAKE_CXX_COMPILE_FEATURES "cxx_variadic_templates" _index_for_cxx_variadic_templates)

if(${_index_for_cxx_variadic_templates} GREATER -1)
  # Use cxx_variadic_templates instead of more appropriate cxx_std_11 for
  # compatibility with older CMake versions.
  set(PRJ_REQUIRED_FEATURES cxx_variadic_templates)
endif()

message(STATUS "Required features: ${PRJ_REQUIRED_FEATURES}")
