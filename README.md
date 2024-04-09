
# cmake跨平台项目编译架构
  > 在一个脚本(`make_cross_platform.sh`)中实现交叉编译。  

  1. 支持跨平台一键编译, 例如: `./make_cross_platform.sh r328 Release`
  2. 自动查找库及其资源、头文件, 第三方库和头文件统一放到 `src/third_party/库名` 文件夹下.
     支持编译后自动拷贝各个库依赖的资源到部署目录下.
  3. 自动查找第三方库变量设为`CACHE`的，避免一个project多个子模块单独依赖造成的多次查找问题.
  4. 自动添加当前目录到当前模块的`target_include_dicrectories`中，由于是public的，依赖此模块的也能自动获得.
  5. 脚本支持自动查找cmake/ninja/ndk路径. 支持检测环境变量，若不存在使用兜底路径，具体可以看编译脚本里的配置.
  6. 支持编译安卓选择stl: `c++_static` 或 `gnustl_static`, 并自动选择对应的库(例如:`armeabi-v7a_release_gnustl_static`). 
     默认不带stl名称的库文件夹(例如`armeabi-v7a_release`)是`c++_static`类型的，这也是Android默认编译的stl类型.
  7. 支持windows编译脚本编译传递vs版本，以及编译时自动选择对应vs版本的库目录(例如: `x32_debug_vs2022`).
  8. 在开启`PRJ_BUILD_ALL_IN_ONE`且编译动态库时，会自动将ALL_IN_ONE依赖的子模块库类型改为 `STATIC`, 这样就可以将子模块代码打包进动态库中.
  9. 在windows msvc下抑制LNK4099警告：依赖的库缺少pdb调试信息.
  10. 项目C/CXX编译选项分开: 若在定义lib库时没有定义编译选项, 自动选择 `PRJ_COMPILE_OPTIONS` 和 `PRJ_CXX_COMPILE_OPTIONS` .
  11. 支持单元测试(`prj_cc_test()`), 可以给每个模块编写单独的测试用例.
  12. 更新 [lcu](https://github.com/wind0ws/libcutils/) 版本到1.7.0正式版.



# 目录结构
  - 3rdparty_reference 第三方库源码：不参与自动化编译，  
                       请将编译好的库放入 `src/third_party/库名称/lib/<ARCH_TYPE>_<BUILD_TYPE>` 目录下
  - cmake 依赖脚本
  - doc   文档
  - src   源码
    - api         对外接口实现模块
    - common      通用工具模块
    - config      配置管理模块
    - example     测试工具源码
    - jni         安卓JNI实现模块，包装C/C++接口成JNI接口
    - third_party 三方库：放置第三方库/头文件及资源
    - work_flow   工作流流转模块: 输入数据，在内部模块之间流转，抛出处理结果
  - tool 工具：编译临时目录、发布目录等等
    - build  编译目录，例如使用cmake生成的工程就在这里
	- deploy 部署发布目录
	  - bin 编译产物输出目录
	  - res 依赖的库资源或配置
 
 
 
 # 编译方式
  > 支持4种BUILD_TYPE: *Debug*, *Release*, *MinSizeRel*, *RelWithDebInfo*
  1. windows:  
     > 自动检测并使用系统安装的最新 Visual Studio 版本:  
       ```shell
          make_windows.bat Win32 Debug
       ```  
     > 指定Visual Studio版本(首先确保系统里已安装对应版本):  
       ```shell
          make_windows.bat Win64 Debug "Visual Studio 14 2015 Win64"  
          make_windows.bat Win32 Release "Visual Studio 14 2015"  
          make_windows.bat Win32 MinSizeRel "Visual Studio 16 2019"  
          make_windows.bat Win64 RelWithDebInfo "Visual Studio 16 2019"  
       ```  
  2. android:  
     > 支持编译不同的`ANDROID_PLATFORM_ABI`及`ANDROID_STL(c++_static/gnustl_static)`.  
     > 默认不加stl参数则使用的是`c++_static`
       ```shell
          make_android.bat armeabi-v7a Debug 
          make_android.bat arm64-v8a Release
          make_android.bat armeabi-v7a MinSizeRel gnustl_static
          make_android.bat arm64-v8a RelWithDebInfo gnustl_static
          make_android.bat x86_64 Release
       ```  
  3. linux 及其他平台:  
     > 如需交叉编译，需先在 *cmake/toolchains/* 下新建对应平台的交叉编译文件。  
     > 例如rk3308, 则在 *cmake/toolchains/* 下新建 *rk3308.toolchain.cmake* 交叉编译文件，  
       并在里面按照cmake语法写上编译器位置及必要的编译参数（如果没有就不写），具体的参考工程里自带的写法。
      ```shell
        # 编译64位linux
        make_cross_platform.sh linux m64 Release
        # 编译32位linux
        make_cross_platform.sh linux m64 Release
        
        #编译rk3308
        make_cross_platform.sh rk3308 Release
        #编译r328
        make_cross_platform.sh r328 Release
      ```  