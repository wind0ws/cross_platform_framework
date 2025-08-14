#if (!defined(_WIN32) && !defined(_GNU_SOURCE))
#define _GNU_SOURCE
#endif // _GNU_SOURCE

#include "mem/mem_debug.h"
#define LOG_TAG "SCHED"
#include "my_logger.h"
#include "my_sched.h"
#include "mem/strings.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <sched.h>
#include <unistd.h>
#include <sys/resource.h> /* for setpriority */
#include <sys/syscall.h>
#endif // _WIN32

int my_sched_set_thread_affinity(unsigned long thread_id, int cpu_id)
{
#ifdef _WIN32
	(void)cpu_id;
	return 0;
#else
	if (cpu_id < 0)
	{
		return 0;
	}
	cpu_set_t mask;
	CPU_ZERO(&mask);
	CPU_SET((size_t)cpu_id, &mask);

	// 0 means current thread
	return sched_setaffinity((pid_t)(thread_id), sizeof(mask), &mask);
#endif // _WIN32
}

bool my_sched_check_thread_priority_is_valid(int priority)
{
#if defined(_WIN32)
	if (priority < MY_SCHED_THREAD_PRIORITY_IDLE || priority > MY_SCHED_THREAD_PRIORITY_TIME_CRITICAL)
	{
		return false;
	}
#elif defined(__linux__) || defined(__ANDROID__)
	if (priority > MY_SCHED_THREAD_PRIORITY_IDLE || priority < MY_SCHED_THREAD_PRIORITY_TIME_CRITICAL)
	{
		return false;
	}
#else
	return false;
#endif // _WIN32
	return true;
}

int my_sched_set_thread_priority(unsigned long thread_id, int priority)
{
	int ret = 0;
	do
	{
		if (!my_sched_check_thread_priority_is_valid(priority))
		{
			ret = -1;
			LOGD_TRACE("priority(%d) is invalid for thread(%lu)", priority, thread_id);
			break;
		}
#if defined(_WIN32) // Windows 平台实现
		ret = -2;
		// 1. 获取线程句柄（需要 THREAD_SET_INFORMATION 权限）
		HANDLE thread_handle = OpenThread(
			THREAD_SET_INFORMATION, // 操作权限
			FALSE,					// 不继承句柄
			thread_id				// 线程 ID
		);
		if (NULL == thread_handle)
		{
			LOGE_TRACE("failed(%lu) on OpenThread(%lu)", GetLastError(), thread_id);
			break;
		}
		if (SetThreadPriority(thread_handle, priority))
		{
			ret = 0; // 设置线程优先级成功
		}
		else
		{
			LOGE_TRACE("Windows: SetThreadPriority(%lu, %d) failed (%lu)", thread_id, priority, GetLastError());
		}
		// 2. 关闭线程句柄
		if (thread_handle)
		{
			CloseHandle(thread_handle);
			thread_handle = NULL;
		}
#elif defined(__linux__) || defined(__ANDROID__) // Linux/Android 平台实现
		ret = setpriority(PRIO_PROCESS, (id_t)thread_id, priority);
		if (0 != ret)
		{
			LOGE_TRACE("Linux: setpriority(%lu, %d) failed: %d", thread_id, priority, ret);
			break;
		}
#else
		ret = -1;
		LOGW("thread_priority setting not supported on this platform");
#endif // _WIN32
	} while (0);
	return ret;
}

int my_sched_transform_thread_priority(int *out_priority_p, const char *priority_type)
{
	if (NULL == out_priority_p || NULL == priority_type || '\0' == priority_type[0])
	{
		return -1;
	}

	if (0 == strncasecmp(priority_type, MY_SCHED_THREAD_PRIORITY_STR_IDLE, sizeof(MY_SCHED_THREAD_PRIORITY_STR_IDLE)))
	{
		*out_priority_p = MY_SCHED_THREAD_PRIORITY_IDLE;
		return 0;
	}
	else if (0 == strncasecmp(priority_type, MY_SCHED_THREAD_PRIORITY_STR_LOWEST, sizeof(MY_SCHED_THREAD_PRIORITY_STR_LOWEST)))
	{
		*out_priority_p = MY_SCHED_THREAD_PRIORITY_LOWEST;
		return 0;
	}
	else if (0 == strncasecmp(priority_type, MY_SCHED_THREAD_PRIORITY_STR_NORMAL, sizeof(MY_SCHED_THREAD_PRIORITY_STR_NORMAL)))
	{
		*out_priority_p = MY_SCHED_THREAD_PRIORITY_NORMAL;
		return 0;
	}
	else if (0 == strncasecmp(priority_type, MY_SCHED_THREAD_PRIORITY_STR_ABOVE_NORMAL, sizeof(MY_SCHED_THREAD_PRIORITY_STR_ABOVE_NORMAL)))
	{
		*out_priority_p = MY_SCHED_THREAD_PRIORITY_ABOVE_NORMAL;
		return 0;
	}
	else if (0 == strncasecmp(priority_type, MY_SCHED_THREAD_PRIORITY_STR_HIGHEST, sizeof(MY_SCHED_THREAD_PRIORITY_STR_HIGHEST)))
	{
		*out_priority_p = MY_SCHED_THREAD_PRIORITY_HIGHEST;
		return 0;
	}
	else if (0 == strncasecmp(priority_type, MY_SCHED_THREAD_PRIORITY_STR_TIME_CRITICAL, sizeof(MY_SCHED_THREAD_PRIORITY_STR_TIME_CRITICAL)))
	{
		*out_priority_p = MY_SCHED_THREAD_PRIORITY_TIME_CRITICAL;
		return 0;
	}
	else
	{
		LOGE_TRACE("unknown thread priority type string: \"%s\"", priority_type);
		return -2;
	}
}

int my_sched_set_thread_priority_by_type(unsigned long thread_id, const char *priority_type)
{
	int priority = 0;
	if (0 != my_sched_transform_thread_priority(&priority, priority_type))
	{
		return -1;
	}
	return my_sched_set_thread_priority(thread_id, priority);
}
