#pragma once
#ifndef _COMMON_H
#define _COMMON_H

#include <stddef.h>  /* for size_t    */
#include <stdbool.h> /* for bool      */
#include <stdint.h>  /* for uintptr_t */

#define COMMON_GLOBAL_INIT() common_global_init()
#define COMMON_GLOBAL_CLEANUP() common_global_cleanup()

#define MEM_ALIGN_PTR_TO(ptr, num) ((void *)(((uintptr_t)(ptr) + (num - 1)) & ~((uintptr_t)(num - 1))))
#define MEM_ALIGN_PTR_32(ptr) MEM_ALIGN_PTR_TO(ptr, 32)

#ifdef __cplusplus
extern "C"
{
#endif

  int common_global_init();

  int common_setenv(const char *name, const char *value, int overwrite);

  char *common_getenv(const char *name);

  int common_chdir(const char *dir);

  int common_getcwd(char *buffer, size_t size);

  bool common_find_last_slash(char *file_path, size_t file_path_len, size_t *last_slash_index_p);

  int common_aligned32_read_file(const char *file_path, void **out_mem_origin_pp,
                                 long *file_size_p, void **out_mem_aligned_pp);

  int common_global_cleanup();

#ifdef __cplusplus
}
#endif

#endif // !_COMMON_H
