#pragma once
#ifndef DYNAMIC_LIB_LOADER_H
#define DYNAMIC_LIB_LOADER_H

#ifdef _WIN32
    #include <windows.h>
    typedef HMODULE LIB_HANDLE;
    #define LOAD_LIBRARY(lib_path) LoadLibraryA(lib_path)
    #define LOAD_SYMBOL(lib_handle, symbol) GetProcAddress(lib_handle, symbol)
    #define CLOSE_LIBRARY(lib_handle) do { if (NULL != lib_handle) { FreeLibrary(lib_handle); } } while(0)
#else
    #include <dlfcn.h>
    typedef void* LIB_HANDLE;
    #define LOAD_LIBRARY(lib_path) dlopen(lib_path, RTLD_LAZY)
    #define LOAD_SYMBOL(lib_handle, symbol) dlsym(lib_handle, symbol)
    #define CLOSE_LIBRARY(lib_handle) do { if (NULL != lib_handle) { dlclose(lib_handle); } } while(0) 
#endif // _WIN32

// 检查加载是否成功
#define CHECK_LIB_LOADED_SUCCESS(lib_handle) (NULL != (lib_handle))

#endif // DYNAMIC_LIB_LOADER_H
