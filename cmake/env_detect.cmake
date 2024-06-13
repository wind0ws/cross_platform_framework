include(CheckCXXCompilerFlag)
include(CheckSymbolExists)
include(CheckCXXSourceRuns)

macro(CHECK_PTHREAD_SETNAME)
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)
    list(APPEND CMAKE_REQUIRED_LIBRARIES pthread)
    check_symbol_exists(pthread_setname_np "pthread.h" HAVE_PTHREAD_SETNAME_NP)
    list(REMOVE_ITEM CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)

    if(HAVE_PTHREAD_SETNAME_NP)
        add_compile_definitions(HAVE_PTHREAD_SETNAME_NP)
    endif()
endmacro(CHECK_PTHREAD_SETNAME)

function(CheckForLinuxPlatform)
    SET(COMMON_FLAG "-w -pipe -Wl,-z,muldefs -fstack-protector -fstack-protector-all -fomit-frame-pointer -fPIC -ffunction-sections -fdata-sections -fvisibility=hidden -fvisibility-inlines-hidden -Bsymbolic")

    set(CMAKE_C_VISIBILITY_PRESET hidden PARENT_SCOPE)
    set(CMAKE_CXX_VISIBILITY_PRESET hidden PARENT_SCOPE)

    add_compile_definitions(POCO_STATIC POCO_NO_AUTOMATIC_LIBS POCO_OS_FAMILY_UNIX)

    CHECK_CXX_COMPILER_FLAG("-Wl,--gc-sections" COMPILER_SUPPORTS_GC_SECTIONS)

    if(COMPILER_SUPPORTS_GC_SECTIONS)
        set(COMMON_FLAG " ${COMMON_FLAG} -Wl,--gc-sections")
    endif()

    set(CMAKE_REQUIRED_FLAGS "-static-libstdc++ -static-libgcc")
    set(COMPILER_SUPPORTS_STATIC_STDCXX_EXITCODE 0)
    set(COMPILER_SUPPORTS_STATIC_STDCXX_EXITCODE__TRYRUN_OUTPUT "")
    CHECK_CXX_SOURCE_RUNS("#include <iostream> \n int main() { std::cout << \"aa\" << std::endl; return 0; }" COMPILER_SUPPORTS_STATIC_STDCXX)

    if(COMPILER_SUPPORTS_STATIC_STDCXX)
        set(COMMON_FLAG "${COMMON_FLAG} -static-libstdc++ -static-libgcc")
    endif()

    unset(CMAKE_REQUIRED_FLAGS)

    if(PLATFORM_ABI MATCHES "x86|x64")
        CHECK_CXX_COMPILER_FLAG("-msse -mfpmath=sse" COMPILER_SUPPORTS_MSSE)

        if(COMPILER_SUPPORTS_MSSE)
            set(COMMON_FLAG "-msse -mfpmath=sse -DUSE_SSE -D_USE_SSE ${COMMON_FLAG}")
        endif()
    elseif(PLATFORM_ABI MATCHES "aarch64")
        set(COMMON_FLAG "${COMMON_FLAG} -DUSE_NEON -DFLOAT_APPROX")
    else()
        file(READ ${CMAKE_CURRENT_LIST_DIR}/cmake/test-neon.txt _test_neon)

        set(CMAKE_REQUIRED_FLAGS "-mfpu=neon -mfloat-abi=softfp -DUSE_NEON -DFLOAT_APPROX")
        check_cxx_source_compiles("${_test_neon}" COMPILER_SUPPORTS_ARM_NEON_SOFTFP)

        if(COMPILER_SUPPORTS_ARM_NEON_SOFTFP)
            set(COMMON_FLAG "${COMMON_FLAG} ${CMAKE_REQUIRED_FLAGS}")
        endif()

        unset(CMAKE_REQUIRED_FLAGS)

        set(CMAKE_REQUIRED_FLAGS "-mfpu=neon -mfloat-abi=hard -DUSE_NEON -DFLOAT_APPROX")
        check_cxx_source_compiles("${_test_neon}" COMPILER_SUPPORTS_ARM_NEON_HARD)

        if(COMPILER_SUPPORTS_ARM_NEON_HARD)
            set(COMMON_FLAG "${COMMON_FLAG} ${CMAKE_REQUIRED_FLAGS}")
        endif()

        unset(CMAKE_REQUIRED_FLAGS)
        unset(_test_neon)
    endif()

    CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)

    if(COMPILER_SUPPORTS_CXX11)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    else()
        message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
    endif()

    MESSAGE(STATUS "CMAKE_SIZEOF_VOID_P  = " ${CMAKE_SIZEOF_VOID_P})

    IF(CMAKE_SIZEOF_VOID_P EQUAL 8)
        MESSAGE(STATUS "current platform: Linux  64")

        IF(PLATFORM_ABI MATCHES "x86")
            MESSAGE(STATUS "build 32 bit lib in 64 os system")

            SET(COMMON_FLAG "${COMMON_FLAG} -m32")
            add_compile_options(-m32)
            add_link_options(-m32)
            set(BUILD_32_LIB ON PARENT_SCOPE)
        ENDIF()
    ELSE()
        IF(PLATFORM_ABI MATCHES "x64")
            MESSAGE(FATAL_ERROR "can not build 64bit on 32 os system")
        ENDIF()
    ENDIF(CMAKE_SIZEOF_VOID_P EQUAL 8)

    CHECK_PTHREAD_SETNAME()

    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        SET(COMMON_FLAG "${COMMON_FLAG} -O0 -g3")
    else()
        SET(COMMON_FLAG "${COMMON_FLAG} -Os")
    endif()

    SET(LINK_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/../libs/linux/${PLATFORM_ABI} PARENT_SCOPE)
    SET(AIUI_LIBRARY_TYPE ${PLATFORM_ABI} PARENT_SCOPE)

    set(COMMON_FLAG "${COMMON_FLAG} -Wl,--exclude-libs,ALL")
    set(COMMON_FLAG "${COMMON_FLAG} -Wl,--unresolved-symbols=ignore-in-shared-libs")

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)

    SET(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
endfunction(CheckForLinuxPlatform)

macro(msvc_source_group_by_dir abs_cur_dir source_files)
    if(MSVC)
        set(sgbd_cur_dir ${${abs_cur_dir}})

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
endmacro(msvc_source_group_by_dir)

function(CheckForWindowsPlatform)
    IF(MSVC)
        SET(COMMON_FLAG "-w /utf-8 /nologo /Gm- /Ob2 /errorReport:prompt /WX- /Zc:wchar_t /Zc:inline /Zc:forScope /GR /Gd /Oy- /MT /EHsc /MP")

        if(NOT AIUI_DEBUG)
            set(COMMON_FLAG "${COMMON_FLAG} /Os")
        endif(NOT AIUI_DEBUG)

        CHECK_CXX_COMPILER_FLAG("/std:c++latest" COMPILER_SUPPORTS_CXXLATEST)
        CHECK_CXX_COMPILER_FLAG("/std:c++11" COMPILER_SUPPORTS_CXX11)

        if(COMPILER_SUPPORTS_CXX11)
            set(COMMON_FLAG "${COMMON_FLAG} /std:c++11")
        elseif(COMPILER_SUPPORTS_CXXLATEST)
            set(COMMON_FLAG "${COMMON_FLAG} /std:c++latest")
        endif(COMPILER_SUPPORTS_CXX11)
    ENDIF(MSVC)

    set(COMMON_FLAG "${COMMON_FLAG} -DUNICODE -D_UNICODE")

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
endfunction(CheckForWindowsPlatform)

function(CheckForAndroidPlatform)
    SET(COMMON_FLAG " -w -fPIC -ffunction-sections -fdata-sections -fvisibility=hidden")

    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        SET(COMMON_FLAG "${COMMON_FLAG} -O0 -g3")
    else()
        SET(COMMON_FLAG "${COMMON_FLAG} -Os")
    endif()

    CHECK_CXX_COMPILER_FLAG("-Wl,--gc-sections" COMPILER_SUPPORTS_GC_SECTIONS)

    if(COMPILER_SUPPORTS_GC_SECTIONS)
        set(COMMON_FLAG "-Wl,--gc-sections ${COMMON_FLAG}")
    endif()

    CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
    CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)

    if(COMPILER_SUPPORTS_CXX14)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    elseif(COMPILER_SUPPORTS_CXX11)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    else()
        message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
    endif()

    CHECK_PTHREAD_SETNAME()

    add_compile_definitions(POCO_STATIC POCO_NO_AUTOMATIC_LIBS POCO_NO_SHAREDMEMORY POCO_OS_FAMILY_UNIX POCO_ANDROID)

    set(COMMON_FLAG "${COMMON_FLAG} -Wl,--unresolved-symbols=ignore-in-shared-libs")

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)

    SET(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
endfunction(CheckForAndroidPlatform)

function(CheckForiOSPlatform)
    SET(COMMON_FLAG " -w -fPIC -ffunction-sections -fdata-sections -fvisibility=hidden")

    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        SET(COMMON_FLAG "${COMMON_FLAG} -O0 -g3")
    else()
        SET(COMMON_FLAG "${COMMON_FLAG} -Os")
    endif()

    CHECK_CXX_COMPILER_FLAG("-Wl,-dead_strip" COMPILER_SUPPORTS_GC_SECTIONS)

    if(COMPILER_SUPPORTS_GC_SECTIONS)
        set(COMMON_FLAG "-Wl,-dead_strip ${COMMON_FLAG}")
    endif()

    CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
    CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)

    if(COMPILER_SUPPORTS_CXX14)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    elseif(COMPILER_SUPPORTS_CXX11)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    else()
        message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
    endif()

    CHECK_PTHREAD_SETNAME()

    add_compile_definitions(POCO_STATIC POCO_NO_AUTOMATIC_LIBS POCO_NO_SHAREDMEMORY POCO_OS_FAMILY_UNIX POCO_IOS)

    set(COMMON_FLAG "${COMMON_FLAG} -Wl")

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)

    SET(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
endfunction(CheckForiOSPlatform)
