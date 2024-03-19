
# 此目录存放第三方库
> 包含库的头文件(`include`)/库文件(`lib`)/库依赖资源(`asset`)。 

> 以curl为例：放置的结构目录应如下：
  - curl 
    - asset
	  - xxx.cert
	- include
	  - curl.h
	- lib
	  - android
	    - armeabi-v7a_release
	    - arm64-v8a_release
	  - linux
	    - x64_release
	  - windows
	    - x32_debug
		- x32_release
		- x64_debug
		- x64_release
	  - rk3308
	    - x64_release

## 1. 头文件 存放规则： 放入以下文件夹: *库名文件夹/include*
## 2. 资源 存放规则： 放入以下文件夹: *库名文件夹/asset*
## 3. 库文件 存放规则：
   1. *库名文件夹/平台文件夹/平台架构_编译类型文件夹/库文件*
      > 注意：```平台(PLATFORM)文件夹```、 ```平台架构(PLATFORM_ABI)_编译类型(CMAKE_BUILD_TYPE)文件夹``` 字母全部取***小写形式***。

      > 例如: 放置 curl 库到 android armeabi-v7a release下，
       那么应该把 libcurl.a 拷贝到： `android/armeabi-v7a_release/` 这里即可。
       同理，如果有动态库（libcurl.so）也同样拷贝到对应的结构目录下。
	   
   2. 对于android和windows平台，由于ANDROID_STL和vs版本不同也会导致编译冲突报错，故建议放置对应的.  
    2.1 android 默认编译使用的stl是**c++_static**, 若不是此STL，则需要编译对应的stl的库放入指定文件夹。
        > 例如放置arm64-v8a的gnustl_static的curl库，那么debug库应该放在 `android/arm64-v8a_debug_gnustl_static/`，
         release库应放在 `android/arm64-v8a_release_gnustl_static/`
    2.2 windows 目录下默认不带 *_vs20xx* 版本的库为兜底库，默认为vs2015编译，若不存在你在用的vs版本的库可能编译会冲突报错，故建议编译你在用的vs版本库。
       > 兜底库采用的是vs2015编译的，也就是文件夹没有标记vs版本的即是vs2015编译的。
         对于那些没有用特定vs版本编译的库统一用兜底库。

         风险点： 由于兜底库和你正在用的vs版本可能不同，那么可能会导致编译冲突报错，
                  出现这样的问题那么有两种解决办法：
                  1. 你装兜底库对应的vs版本，并用这个版本编译;
                  2. 找到你需要的库源码，用你在用的vs版本编译出来放到指定文件夹。
                     例如你用的是vs2017，准备编译x32平台，那么请至少编译release版本的库放在 x32_release_vs2017 文件夹下.
                     当然你顺手把 debug/minsizerel/relwithdebinfo 等模式编译了更好。



### 库查找规则
  > 首先从对应 *平台架构_编译模式* 文件夹下找库（根据cmake脚本里的需求找动态库还是静态库），
    如果找不到那么会从对应 *平台架构_release* 文件夹下找。
    如果这两个文件夹都找不到则报错!
    
  > 接着上面的示例，curl release库被放到 `android/armeabi-v7a_release/` 这里, 
    假如现在我们编译debug模式的，找curl库会先找 `android/armeabi-v7a_debug/` , 找不到会回退到release文件夹里找。
  
  > 接上述"库文件 存放规则"说明，对于android/windows，还会优先查找对应ANDROID_STL和vs版本文件夹下的库，
    如果不存在会回退到不带特殊版本标记的文件夹，如果都找不到则报错。
	
    1. 示例1: 查找 rk3308 x64 debug 的curl库，那么脚本会按照下述文件夹顺序去找，都找不到则报错。
       1. *lib/rk3308/x64_debug/*
       2. *lib/rk3308/x64_release/*

    2. 示例2: 查找 rk3308 x64 release 的curl库，那么脚本会按照下述文件夹顺序去找，都找不到则报错。
       1. *lib/rk3308/x64_release/*

    3. 示例3: 查找 android arm64-v8a debug gnustl_static 的curl库，那么脚本会按照下述文件夹顺序去找，都找不到则报错。
       1. *lib/android/arm64-v8a_debug_gnustl_static/*
       2. *lib/android/arm64-v8a_release_gnustl_static/*
       3. *lib/android/arm64-v8a_debug/*
       4. *lib/android/arm64-v8a_release/*

    4. 示例4: 查找 android armeabi-v7a debug **c++_static** 的curl库，那么脚本会按照下述文件夹顺序去找，都找不到则报错。
       1. *lib/android/armeabi-v7a_debug/*
       2. *lib/android/armeabi-v7a_release/*

    5. 示例5: 查找 vs2019 win32 debug 的curl库，那么脚本会按照下述文件夹顺序去找，都找不到则报错。
       1. *lib/windows/x32_debug_vs2019/*
       2. *lib/windows/x32_release_vs2019/*
       3. *lib/windows/x32_debug/*
       4. *lib/windows/x32_release/*

    6. 示例6: 查找 vs2015 win64 debug 的curl库，那么脚本会按照下述文件夹顺序去找，都找不到则报错。
       1. *lib/windows/x64_debug/*
       2. *lib/windows/x64_release/*
  
