#pragma once
#ifndef _COMMON_H
#define _COMMON_H

#define COMMON_GLOBAL_INIT() common_global_init()
#define COMMON_GLOBAL_CLEANUP() common_global_cleanup()

#ifdef __cplusplus
extern "C" {
#endif

  int common_global_init();

  int common_global_cleanup();

#ifdef __cplusplus
}
#endif

#endif // !_COMMON_H
