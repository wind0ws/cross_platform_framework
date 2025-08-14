PUSHD %~DP0 & TITLE setup_env & chcp 65001 & COLOR 0A & setlocal enabledelayedexpansion
:: 非0则不显示每行执行的脚本命令
set ECHO_OFF=1
set ENV_EXIT_CODE=0

if %ECHO_OFF% NEQ 0 (
  @echo off
)

::for /f %%a in ('dir /a:d /b %ANDROID_SDK%\cmake\') do set cmake_version=%%a
::echo "find cmake version %cmake_version%"
::set cmake_version=3.10.2.4988404
::set CMAKE_BIN=%ANDROID_SDK%\cmake\%cmake_version%\bin\cmake.exe
::set NINJA_BIN=%ANDROID_SDK%\cmake\%cmake_version%\bin\ninja.exe
set CMAKE_BIN=cmake.exe
@echo cmake version: 
!CMAKE_BIN! --version
set ERR_CODE=%ERRORLEVEL%
IF !ERR_CODE! NEQ 0 (
   set CMAKE_BIN=D:\env\cmake\bin\cmake.exe
   @echo.
   @echo "cmake not found on your environment, we point a location(!CMAKE_BIN!) for you." 
   if not exist !CMAKE_BIN! (
     @echo ERROR: !CMAKE_BIN! not exists!!
     set ENV_EXIT_CODE=2
     goto label_exit_env
   )
   !CMAKE_BIN! --version
)
@echo.
set NINJA_BIN=ninja.exe
@echo ninja version: 
!NINJA_BIN! --version
set ERR_CODE=%ERRORLEVEL%
IF !ERR_CODE! NEQ 0 (
   set NINJA_BIN=D:\env\cmake\bin\ninja.exe
   @echo.
   @echo "ninja not found on your environment, we point a location(!NINJA_BIN!) for you." 
   if not exist !NINJA_BIN! (
     @echo ERROR: !NINJA_BIN! not exists!!
     set ENV_EXIT_CODE=2
     goto label_exit_env
   )
   !NINJA_BIN! --version
)
@echo.

@echo.
@echo =================== Your Environment ===================
@echo CMAKE_BIN=!CMAKE_BIN!
@echo NINJA_BIN=!NINJA_BIN!
@echo ========================================================
@echo.

:: ON/OFF: ON for SHARED libs.
set BUILD_SHARED_LIBS=ON

set BUILD_ABI=%1
if "%BUILD_ABI%" EQU "" (
  @echo Now you should input build abi.
  goto label_input_abi
) else (
  @echo your BUILD_ABI: %BUILD_ABI%
  goto label_check_build_type
)

:label_input_abi
@echo "which target abi do you want to build: "
set /p BUILD_ABI="please input BUILD_ABI:"

:label_check_build_type
set BUILD_TYPE=%2
if "!BUILD_TYPE!" EQU "" set BUILD_TYPE=Release
if "!BUILD_TYPE!" EQU "Release" goto label_run_next_bat
if "!BUILD_TYPE!" EQU "Debug" goto label_run_next_bat
if "!BUILD_TYPE!" EQU "MinSizeRel" goto label_run_next_bat
if "!BUILD_TYPE!" EQU "RelWithDebInfo" goto label_run_next_bat
@echo unknown BUILD_TYPE=!BUILD_TYPE!, available types are: "Debug" / "Release" / "MinSizeRel" / "RelWithDebInfo"
set ENV_EXIT_CODE=2
goto label_exit_env

:label_run_next_bat
@echo.
set EXTRA_PARAMS=%~3
if "!EXTRA_PARAMS:~0,2!" == "-D" (
  @echo "ok, the No.3 EXTRA_PARAMS = !EXTRA_PARAMS!"
) else (
  set EXTRA_PARAMS=%~4
  if "!EXTRA_PARAMS:~0,2!" == "-D" (
    @echo "ok, the No.4 EXTRA_PARAMS = !EXTRA_PARAMS!"
  ) else (
    set EXTRA_PARAMS=
    @echo "no EXTRA_PARAMS. compile with default params."
  )
)
set CMAKE_EXTEND_ARGS= -DCMAKE_BUILD_TYPE=!BUILD_TYPE! -DBUILD_SHARED_LIBS=%BUILD_SHARED_LIBS% -DPRJ_BUILD_ALL_IN_ONE=ON -DPRJ_BUILD_TESTS=ON !EXTRA_PARAMS! 
@echo.
@echo origin: 
@echo   CMAKE_EXTEND_ARGS=!CMAKE_EXTEND_ARGS!
@echo.
::@echo remove quotation mark:
::@echo   CMAKE_EXTEND_ARGS=%CMAKE_EXTEND_ARGS:"=%
@echo.
@echo   hello... you request compile with (!BUILD_ABI!  !BUILD_TYPE!)...
@echo.
:: 导出参数，供其他批处理导入使用
set EXPORT_VAR_FILE=%TEMP%\env_variables.tmp
del /Q %EXPORT_VAR_FILE% 2>nul
> %EXPORT_VAR_FILE% (
  echo CMAKE_BIN=!CMAKE_BIN!
  echo NINJA_BIN=!NINJA_BIN!
  echo BUILD_ABI=!BUILD_ABI!
  echo BUILD_TYPE=!BUILD_TYPE!
  echo CMAKE_EXTEND_ARGS=!CMAKE_EXTEND_ARGS!
)

:label_exit_env
@echo ENV_EXIT_CODE=!ENV_EXIT_CODE!
@echo.
@exit /b !ENV_EXIT_CODE!
