call setup_env.bat %*
if %ERRORLEVEL% NEQ 0 (
  @echo error on setup_env, check it.
  @exit /b 2
) 
:: 导入参数
set IMPORT_VAR_FILE=%TEMP%\env_variables.tmp
for /f "tokens=1* delims==" %%i in (%IMPORT_VAR_FILE%) do (
    set "%%i=%%j"
) 

set MY_TAG=make_android
PUSHD %~DP0 &TITLE %MY_TAG% &COLOR 0A & setlocal enabledelayedexpansion

set NDK_VERSION=16.1.4479499
set ERR_CODE=0
@echo [%MY_TAG%] your BUILD_ABI: %BUILD_ABI%
@echo [%MY_TAG%] your BUILD_TYPE: %BUILD_TYPE%
@echo [%MY_TAG%] your CMAKE_EXTEND_ARGS: %CMAKE_EXTEND_ARGS%


@echo.
@echo detect env ANDROID_NDK=%ANDROID_NDK%
if "%ANDROID_NDK%" EQU "" (
  @echo "ANDROID_NDK NOT found on your env, now detect ANDROID_SDK=%ANDROID_SDK%"
  if "%ANDROID_SDK%" NEQ "" (
    set ANDROID_NDK=%ANDROID_SDK%\ndk\%NDK_VERSION%
  ) else (
    @echo "oops, ANDROID_SDK NOT found on your env, we point a ANDROID_NDK path for you."
    set ANDROID_NDK=D:\Android\ndk-multiversion\android-ndk-r16b
  )
  @echo now assume ANDROID_NDK=!ANDROID_NDK!
)
if not exist "!ANDROID_NDK!" (
    @echo "error: NDK(!ANDROID_NDK!) NOT found."
    set ERR_CODE=2
    goto label_exit_make
) 

set ANDROID_TOOLCHAIN_FILE=!ANDROID_NDK!\build\cmake\android.toolchain.cmake
set ANDROID_PLATFORM=android-19 
set ANDROID_STL=c++_static
::set ANDROID_STL=gnustl_static

set PARAM_STL=%~3
if "!PARAM_STL!" NEQ "" (
  if "!PARAM_STL:~0,2!" == "-D" (
    @echo "[%MY_TAG%] the No.3 is extra_params, try read stl at param4..."
    goto lable_try_read_stl_at_param4
  ) else goto label_check_stl
) else (
  goto lable_try_read_stl_at_param4
)

:lable_try_read_stl_at_param4
set PARAM_STL=%~4
if "!PARAM_STL!" NEQ "" (
  @echo "use the No.4 to check_stl"
  goto label_check_stl
) else goto label_entry

:label_check_stl
if "!PARAM_STL!" EQU "c++_static" goto label_set_stl
if "!PARAM_STL!" EQU "gnustl_static" goto label_set_stl
@echo "you provide ANDROID_STL(!PARAM_STL!), which is NOT supported. available stl are 'c++_static' OR 'gnustl_static'"
set ERR_CODE=2
goto label_exit_make

:label_set_stl
set ANDROID_STL=!PARAM_STL!
@echo use your ANDROID_STL=!ANDROID_STL!

:label_entry
if not exist !ANDROID_TOOLCHAIN_FILE! (
  @echo "ERROR: !ANDROID_TOOLCHAIN_FILE! not exists, should use NDK version greater than or equal r16b."
  set ERR_CODE=2
  goto label_exit_make
)

@echo.
@echo ==================================================================
@echo ANDROID_NDK=!ANDROID_NDK!
@echo ANDROID_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN_FILE!
@echo ANDROID_PLATFORM=!ANDROID_PLATFORM!
@echo ANDROID_STL=!ANDROID_STL!
@echo ==================================================================
@echo.


:label_check_params
if "%BUILD_ABI%" EQU "armeabi-v7a" goto label_main
if "%BUILD_ABI%" EQU "arm64-v8a" goto label_main
if "%BUILD_ABI%" EQU "x86" goto label_main
if "%BUILD_ABI%" EQU "x86_64" goto label_main
if "%BUILD_ABI%" EQU "mips" goto label_main
if "%BUILD_ABI%" EQU "mips64" goto label_main
@echo params check failed: unknown BUILD_ABI=%BUILD_ABI%
set ERR_CODE=2
goto label_exit_make

:label_main
@echo Your BUILD_ABI=%BUILD_ABI%
set BUILD_DIR=.\tool\build\build_android_%BUILD_ABI%
TITLE=%BUILD_DIR%
rmdir /S /Q "%BUILD_DIR:"=%" 2>nul
mkdir "%BUILD_DIR:"=%"

%CMAKE_BIN% -H.\ -B%BUILD_DIR:"=%                           ^
            "-GNinja"                                       ^
            -DANDROID_ARM_NEON=TRUE                         ^
            -DANDROID_ABI=%BUILD_ABI%                       ^
            -DANDROID_NDK=!ANDROID_NDK!                     ^
            -DANDROID_PLATFORM=!ANDROID_PLATFORM!           ^
            -DANDROID_TOOLCHAIN=clang                       ^
            -DANDROID_STL=!ANDROID_STL!                     ^
            -DCMAKE_BUILD_TYPE=%BUILD_TYPE%                 ^
            -DCMAKE_TOOLCHAIN_FILE=!ANDROID_TOOLCHAIN_FILE! ^
            -DCMAKE_MAKE_PROGRAM=%NINJA_BIN%                ^
            %CMAKE_EXTEND_ARGS%
::            -DBUILD_SHARED_LIBS=ON -DPRJ_BUILD_ALL_IN_ONE=ON -DPRJ_BUILD_TESTS=ON

set ERR_CODE=%ERRORLEVEL%
IF !ERR_CODE! NEQ 0 (
   @echo "Error on generate project: !ERR_CODE!"
   goto label_exit_make
)

%NINJA_BIN% -C %BUILD_DIR:"=% -j 8
set ERR_CODE=%ERRORLEVEL%
::mkdir %OUTPUT_DIR%
::copy /Y .\build_android_v7a\libcutils_test %OUTPUT_DIR%\\
::copy /Y .\build_android_v7a\liblcu_a.a %OUTPUT_DIR%\\
::copy /Y .\build_android_v7a\liblcu.so %OUTPUT_DIR%\\
@echo.
@echo "compile %PLATFORM% %BUILD_ABI% %BUILD_TYPE% finished(!ERR_CODE!). bye bye..."

:label_exit_make
::@pause>nul
::color 0F
del /Q %IMPORT_VAR_FILE% 2>nul
@exit /b !ERR_CODE!
