#pragma once
#ifndef MY_API_H
#define MY_API_H

#include <stddef.h>

// ================================= ATTR MACRO START =================================

#if !defined(__WINDOWS__) && (defined(WIN32) || defined(WIN64) || defined(_MSC_VER) || defined(_WIN32))
#define __WINDOWS__
#endif

/* export symbols by default, this is necessary for copy pasting the C and header file */
#if !defined(ATTR_HIDE_SYMBOLS) && !defined(ATTR_IMPORT_SYMBOLS) && !defined(ATTR_EXPORT_SYMBOLS)
#define ATTR_EXPORT_SYMBOLS
#endif

#ifdef __WINDOWS__
#define _ATTR_CDECL __cdecl
#define _ATTR_STDCALL __stdcall
#define ATTR_CALLING_CONVENTION _ATTR_CDECL

#if defined(ATTR_HIDE_SYMBOLS)
#define ATTR_PUBLIC(type) type ATTR_CALLING_CONVENTION
#elif defined(ATTR_EXPORT_SYMBOLS)
#define ATTR_PUBLIC(type) __declspec(dllexport) type ATTR_CALLING_CONVENTION
#elif defined(ATTR_IMPORT_SYMBOLS)
#define ATTR_PUBLIC(type) __declspec(dllimport) type ATTR_CALLING_CONVENTION
#endif

#else /* !__WINDOWS__ */

#define _ATTR_CDECL
#define _ATTR_STDCALL
#define ATTR_CALLING_CONVENTION _ATTR_CDECL

#if (defined(__GNUC__) || defined(__SUNPRO_CC) || defined(__SUNPRO_C)) && (defined(ATTR_EXPORT_SYMBOLS))
#define ATTR_PUBLIC(type) __attribute__((visibility("default"))) type
#else
#define ATTR_PUBLIC(type) type
#endif

#endif // __WINDOWS__

// ================================= ATTR MACRO END  =================================

#ifdef __cplusplus
extern "C"
{
#endif

  ATTR_PUBLIC(const char *) my_api_get_version();

#ifdef __cplusplus
};
#endif

#endif // !MY_API_H
