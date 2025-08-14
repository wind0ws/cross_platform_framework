#pragma once
#ifndef _MY_SCHED_H
#define _MY_SCHED_H

#define MY_SCHED_THREAD_PRIORITY_STR_IDLE "idle"
#define MY_SCHED_THREAD_PRIORITY_STR_LOWEST "lowest"
#define MY_SCHED_THREAD_PRIORITY_STR_NORMAL "normal"
#define MY_SCHED_THREAD_PRIORITY_STR_ABOVE_NORMAL "above_normal"
#define MY_SCHED_THREAD_PRIORITY_STR_HIGHEST "highest"
#define MY_SCHED_THREAD_PRIORITY_STR_TIME_CRITICAL "time_critical"

#ifdef _WIN32
typedef enum
{
  MY_SCHED_THREAD_PRIORITY_IDLE = -15,
  MY_SCHED_THREAD_PRIORITY_LOWEST = -2,
  MY_SCHED_THREAD_PRIORITY_BELOW_NORMAL = -1,
  MY_SCHED_THREAD_PRIORITY_NORMAL = 0,
  MY_SCHED_THREAD_PRIORITY_ABOVE_NORMAL = 1,
  MY_SCHED_THREAD_PRIORITY_HIGHEST = 2,
  MY_SCHED_THREAD_PRIORITY_TIME_CRITICAL = 15,
} my_sched_thread_priority_e;
#else
typedef enum
{
  MY_SCHED_THREAD_PRIORITY_IDLE = 19,
  MY_SCHED_THREAD_PRIORITY_LOWEST = 19,
  MY_SCHED_THREAD_PRIORITY_BELOW_NORMAL = 10,
  MY_SCHED_THREAD_PRIORITY_NORMAL = 0,
  MY_SCHED_THREAD_PRIORITY_ABOVE_NORMAL = -10,
  MY_SCHED_THREAD_PRIORITY_HIGHEST = -20,
  MY_SCHED_THREAD_PRIORITY_TIME_CRITICAL = -20,
} my_sched_thread_priority_e;
#endif // _WIN32

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

  int my_sched_set_thread_affinity(unsigned long thread_id, int cpu_id);

  bool my_sched_check_thread_priority_is_valid(int priority);

  int my_sched_set_thread_priority(unsigned long thread_id, int priority);

  int my_sched_transform_thread_priority(int *out_priority_p, const char *priority_type);

  int my_sched_set_thread_priority_by_type(unsigned long thread_id, const char *priority_type);

#ifdef __cplusplus
}
#endif

#endif // !_MY_SCHED_H
