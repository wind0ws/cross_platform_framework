# CMake 跨平台项目编译架构

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CMake](https://img.shields.io/badge/CMake-3.15+-blue.svg)](https://cmake.org/)
[![C++](https://img.shields.io/badge/C++-11-blue.svg)](https://isocpp.org/)

一个功能完善的 CMake 跨平台编译框架模板，支持 Windows、Linux、Android 及嵌入式平台的一键编译。

## 项目简介

本项目提供了一套完整的跨平台 C/C++ 项目编译架构，通过统一的脚本和 CMake 配置，实现多平台、多架构的自动化编译。适用于需要在多个平台部署的 C/C++ 项目，如嵌入式系统、移动应用、桌面应用等。

**当前版本**: 3.0.0

## 核心特性

### 编译系统

- ✅ **一键跨平台编译** - 通过统一脚本实现 Windows/Linux/Android/嵌入式平台编译
- ✅ **智能依赖管理** - 自动查找和管理第三方库、头文件及资源文件
- ✅ **模块化架构** - 支持多模块项目，自动处理模块间依赖关系
- ✅ **灵活的构建选项** - 支持静态库/动态库、Debug/Release 等多种构建模式

### 高级功能

- ✅ **符号隐藏** - 自动隐藏内部符号，仅导出指定接口（通过 exports.def/exports.exp）
- ✅ **Address Sanitizer** - 内置 ASan 支持，Debug 模式默认启用
- ✅ **单元测试** - 集成测试框架，支持模块级单元测试（`prj_cc_test()`）
- ✅ **All-in-One 构建** - 支持将多个子模块打包到单个动态库中
- ✅ **预编译头** - 可选的 PCH 支持，加速编译过程
- ✅ **Git 集成** - 自动嵌入 Git 分支和提交信息到编译产物

### 平台支持

- ✅ **Windows** - 支持 Win32/Win64，自动检测 Visual Studio 版本
- ✅ **Android** - 支持多 ABI（armeabi-v7a/arm64-v8a/x86_64），可选 STL 类型
- ✅ **Linux** - 支持 x86/x64 本地编译
- ✅ **嵌入式平台** - 支持交叉编译（如 linaro、rk3308、r328 等）

### 开发体验

- ✅ **自动化资源拷贝** - 编译后自动拷贝依赖资源到部署目录
- ✅ **智能路径检测** - 自动检测 CMake/Ninja/NDK 路径
- ✅ **编译选项分离** - C 和 C++ 编译选项独立配置
- ✅ **Git Hooks** - 内置 commit-msg 规范化提交信息

## 快速开始

### 环境要求

- CMake 3.15+
- C++11 编译器
- Git（可选，用于版本信息嵌入）

**平台特定要求**:

- **Windows**: Visual Studio 2015+ 或 MinGW
- **Android**: Android NDK r21+
- **Linux**: GCC 5+ 或 Clang 3.8+
- **交叉编译**: 对应平台的工具链

### 编译示例

#### Windows 平台

```bash
# 自动检测最新 Visual Studio 版本
make_windows.bat Win64 Release

# 指定 Visual Studio 版本
make_windows.bat Win32 Debug "Visual Studio 16 2019"
make_windows.bat Win64 Release "Visual Studio 17 2022"
```

#### Android 平台

```bash
# 使用默认 c++_static STL
make_android.bat armeabi-v7a Release
make_android.bat arm64-v8a Debug

# 使用 gnustl_static STL
make_android.bat armeabi-v7a Release gnustl_static
```

#### Linux 平台

```bash
# 本地编译 64 位
./make_cross_platform.sh linux m64 Release

# 本地编译 32 位
./make_cross_platform.sh linux m32 Release
```

#### 嵌入式平台（交叉编译）

```bash
# 编译 linaro7.5.0 arm64
./make_cross_platform.sh linaro7.5.0 Release "-DPRJ_ENABLE_ASAN=OFF"

# 编译 rk3308
./make_cross_platform.sh rk3308 Release "-DPRJ_HIDDEN_SYMBOLS=ON"
```

### 编译产物

编译输出位于 `tool/deploy/bin/<PLATFORM>_<ABI>_<BUILD_TYPE>/` 目录：

- Windows x32 Debug: `tool/deploy/bin/windows_x32_debug/`
- Linux x64 Release: `tool/deploy/bin/linux_x64_release/`
- Android arm64-v8a Release: `tool/deploy/bin/android_arm64-v8a_release/`

## 目录结构

```text
cross_platform_framework/
├── 3rdparty_reference/     # 第三方库源码（不参与自动编译）
├── cmake/                  # CMake 脚本和工具链配置
│   ├── toolchains/        # 交叉编译工具链配置文件
│   ├── macros.cmake       # CMake 宏定义
│   ├── platform_detector.cmake  # 平台检测
│   └── utility.cmake      # 工具函数
├── doc/                   # 项目文档
├── src/                   # 源代码目录
│   ├── api/              # 对外接口实现模块
│   ├── common/           # 通用工具模块（建议其他模块依赖此模块）
│   ├── config/           # 配置管理模块
│   ├── example/          # 示例和测试工具
│   ├── jni/              # Android JNI 接口封装
│   ├── third_party/      # 第三方库/头文件/资源
│   │   └── <lib_name>/   # 每个第三方库一个文件夹
│   │       ├── include/  # 头文件
│   │       ├── lib/      # 预编译库
│   │       │   └── <ARCH>_<BUILD_TYPE>/  # 按平台和构建类型组织
│   │       └── asset/    # 资源文件
│   ├── work_flow/        # 业务流程模块
│   ├── version.h         # 版本定义
│   └── exports.def/exp   # 符号导出定义
├── tool/                  # 工具和输出目录
│   ├── build/            # CMake 生成的构建文件
│   └── deploy/           # 部署输出目录
│       ├── bin/          # 编译产物（按平台组织）
│       └── res/          # 依赖的资源文件
├── .githooks/            # Git 钩子脚本
├── CMakeLists.txt        # 根 CMake 配置
├── make_windows.bat      # Windows 编译脚本
├── make_android.bat      # Android 编译脚本
└── make_cross_platform.sh # Linux/交叉编译脚本
```

### 第三方库组织规范

第三方库统一放置在 `src/third_party/<lib_name>/` 目录下，按以下结构组织：

```text
src/third_party/<lib_name>/
├── include/              # 头文件
├── lib/                  # 预编译库
│   ├── windows_x32_debug/
│   ├── windows_x64_release/
│   ├── android_armeabi-v7a_release/
│   ├── android_arm64-v8a_release/
│   ├── linux_x64_release/
│   └── <platform>_<abi>_<build_type>/
├── asset/                # 资源文件（会自动拷贝到部署目录）
└── find_me.cmake         # CMake 查找脚本（可选）
```

## 编译配置

### 构建类型

支持 4 种标准 CMake 构建类型：

| 构建类型 | 说明 | 优化级别 | 调试信息 |
| -------- | ---- | ------- | ------- |
| **Debug** | 调试版本 | 无优化 | 完整 |
| **Release** | 发布版本 | 最大优化 | 无 |
| **MinSizeRel** | 最小体积版本 | 体积优化 | 无 |
| **RelWithDebInfo** | 带调试信息的发布版 | 优化 | 有 |

### 编译选项

| 选项 | 说明 | 默认值 |
| ---- | ---- | ------ |
| **PRJ_BUILD_SHARED** | 编译动态库 | OFF |
| **PRJ_BUILD_ALL_IN_ONE** | 将所有模块打包到一个库 | ON |
| **PRJ_BUILD_TESTS** | 编译单元测试 | OFF |
| **PRJ_ENABLE_ASAN** | 启用 Address Sanitizer | Debug: ON, 其他: OFF |
| **PRJ_HIDDEN_SYMBOLS** | 隐藏内部符号 | Debug: OFF, 其他: ON |
| **PRJ_BUILD_PIC** | 生成位置无关代码 | ON |
| **PRJ_ENABLE_PCH** | 启用预编译头 | OFF |
| **PRJ_BUILD_WARNINGS** | 启用编译器警告 | OFF |
| **PRJ_THIRD_LIB_SHARED** | 使用第三方动态库 | OFF |

### 使用编译选项

通过 `-D` 参数传递给 CMake：

```bash
# Linux 示例：禁用 ASan，启用符号隐藏
./make_cross_platform.sh linux m64 Release "-DPRJ_ENABLE_ASAN=OFF -DPRJ_HIDDEN_SYMBOLS=ON"

# 启用测试和警告
./make_cross_platform.sh linux m64 Debug "-DPRJ_BUILD_TESTS=ON -DPRJ_BUILD_WARNINGS=ON"
```

## 添加新模块

### 1. 创建模块目录

在 `src/` 下创建新模块目录，例如 `src/my_module/`。

### 2. 编写 CMakeLists.txt

```cmake
set(MODULE_NAME "my_module")

prj_cc_library(
  NAME
    ${MODULE_NAME}
  HDRS
    "my_module.h"
  SRCS
    "my_module.cpp"
  COPTS
    # 可选：自定义编译选项
  DEPS
    ${CMAKE_PROJECT_NAME}::common  # 依赖其他模块
  DEFINES
    # 可选：预处理器定义
  PUBLIC
)
```

### 3. 添加单元测试（可选）

```cmake
prj_cc_unit_test(
  NAME
    ${MODULE_NAME}_test
  SRCS
    "my_module_test.cpp"
  DEPS
    ${CMAKE_PROJECT_NAME}::${MODULE_NAME}
)
```

### 4. 在父 CMakeLists.txt 中添加

在 `src/CMakeLists.txt` 中添加：

```cmake
add_subdirectory(my_module)
```

## 添加第三方库

### 1. 准备库文件

将第三方库按平台组织到 `src/third_party/<lib_name>/lib/` 目录：

```text
src/third_party/my_lib/
├── include/
│   └── my_lib.h
└── lib/
    ├── windows_x64_release/
    │   └── my_lib.lib
    ├── android_arm64-v8a_release/
    │   └── libmy_lib.a
    └── linux_x64_release/
        └── libmy_lib.so
```

### 2. 创建 find_me.cmake（可选）

```cmake
# src/third_party/my_lib/find_me.cmake
set(MY_LIB_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/include)
set(MY_LIB_LIBRARIES ${CMAKE_CURRENT_LIST_DIR}/lib/${PRJ_PLATFORM_ABI_BUILD_TYPE}/libmy_lib.a)
```

### 3. 在模块中使用

```cmake
prj_cc_library(
  NAME my_module
  SRCS "my_module.cpp"
  DEPS
    my_lib  # 框架会自动查找 src/third_party/my_lib/
)
```

## 交叉编译配置

### 添加新的交叉编译平台

在 `cmake/toolchains/` 下创建工具链文件，例如 `my_platform.toolchain.cmake`：

```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# 设置编译器路径
set(CMAKE_C_COMPILER /path/to/arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER /path/to/arm-linux-gnueabihf-g++)

# 设置查找路径
set(CMAKE_FIND_ROOT_PATH /path/to/sysroot)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# 可选：添加平台特定编译选项
add_compile_options(-march=armv7-a -mfpu=neon)
```

使用新平台编译：

```bash
./makes_platform.sh my_platform Release
```

## 符号导出控制

### Windows (exports.def)

```def
EXPORTS
    my_api_function
    my_api_init
    my_api_cleanup
```

### Linux/Unix (exports.exp)

```json
{
    global:
        my_api_function;
        my_api_init;
        my_api_cleanup;
    local:
        *;
};
```

当 `PRJ_HIDDEN_SYMBOLS=ON` 时，只有在这些文件中声明的符号会被导出。

## Git Hooks 配置

启用 Git Hooks 以规范化提交信息：

修改 `.git/config`：

```ini
[core]
    hooksPath = .githooks
```

或使用命令：

```bash
git config core.hooksPath .githooks
```

提交信息格式要求：

```text
<type>(<scope>): <subject>

<body>

<footer>
```

类型（type）：

- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具链相关

## 常见问题

### Q: 如何切换静态库/动态库？

```bash
# 编译动态库
./make_cross_platform.sh linux m64 Release "-DPRJ_BUILD_SHARED=ON"

# 编译静态库（默认）
./make_cross_platform.sh linux m64 Release "-DPRJ_BUILD_SHARED=OFF"
```

### Q: 如何禁用 Address Sanitizer？

```bash
./make_cross_platform.sh linux m64 Debug "-DPRJ_ENABLE_ASAN=OFF"
```

### Q: 编译 Android 时如何选择 STL？

```bash
# 使用 c++_static（默认）
make_android.bat arm64-v8a Release

# 使用 gnustl_static
make_android.bat arm64-v8a Release gnustl_static
```

### Q: 如何添加自定义编译选项？

在模块的 `CMakeLists.txt` 中：

```cmake
prj_cc_library(
  NAME my_module
  SRCS "my_module.cpp"
  COPTS
    -Wall
    -Wextra
    $<$<CONFIG:Release>:-O3>  # Release 模式特定选项
)
```

### Q: 第三方库找不到怎么办？

1. 确认库文件路径符合规范：`src/third_party/<lib_name>/lib/<platform>_<abi>_<build_type>/`
2. 检查库文件命名是否正确（Windows: `.lib`, Linux/Android: `.a` 或 `.so`）
3. 查看 CMake 输出日志，确认平台检测是否正确

## 依赖的第三方库

- [lcu (libcutils)](https://github.com/wind0ws/libcutils/) - C 工具库

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v3.0.0

- 完善 CMake 构建系统
- 支持符号隐藏和 Address Sanitizer
- 改进跨平台编译脚本
- 更新 lcu 库到最新版本

---

**注意**: 本框架是一个模板项目，建议根据实际需求进行定制和扩展。
