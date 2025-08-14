#pragma once
#ifndef HANDLE_CHECKER_H
#define HANDLE_CHECKER_H

#include "common_macro.h"

#ifndef MODULE_UID
#error you must define MODULE_UID first for check module handle!
#endif // !MODULE_UID

typedef enum
{
  // reserved. module uid must not use this.
  MODULE_UID_RESERVED = 0,

  MODULE_UID_API = 20240000,
  MODULE_UID_AUTH,
  MODULE_UID_WORK_FLOW,

} module_uid_e;

/* handle checker data entity */
typedef struct
{
  int uid;
} base_handle_t, *base_handle_ptr;

// assign module with your uid.
#define _HANDLE_CHECKER_ASSIGN_UID(handle, expected_uid) \
  do                                                     \
  {                                                      \
    ((base_handle_ptr)handle)->uid = (expected_uid);     \
  } while (0)

// define handle checker data entity
#define HANDLE_CHECKER_DEFINE_UID_MEMBER base_handle_t _base;
// init checker with MODULE_UID.
#define HANDLE_CHECKER_INIT(handle) _HANDLE_CHECKER_ASSIGN_UID(handle, MODULE_UID)
// reset checker with invalid value.
#define HANDLE_CHECKER_DESTROY(handle) _HANDLE_CHECKER_ASSIGN_UID(handle, MODULE_UID_RESERVED)

#define HANDLE_CHECKER_CHECK_WITH_UID(handle, expected_uid)                                   \
  do                                                                                          \
  {                                                                                           \
    if (!handle || ((base_handle_ptr)handle)->uid != (expected_uid))                          \
    {                                                                                         \
      EMERGENCY_LOG(" module uid error on %s:%d. expected=%d, but yours.uid=%d in handle=%p", \
                    __func__, __LINE__, (expected_uid),                                       \
                    (handle) ? ((base_handle_ptr)handle)->uid : 0, (void *)(handle));         \
      return 1;                                                                               \
    }                                                                                         \
  } while (0)

// check current handle with specified uid.
#define HANDLE_CHECKER_DO_CHECK(handle) HANDLE_CHECKER_CHECK_WITH_UID(handle, MODULE_UID)

#endif // ! HANDLE_CHECKER_H
