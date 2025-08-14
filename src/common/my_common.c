#include "mem/mem_debug.h"
#include "my_common.h"
#include "lcu.h"
#define LOG_TAG "COMMON"
#include "my_logger.h"
#include "global_func_impl.h"
#include <string.h>
#include <stdio.h>

#ifdef _WIN32
#pragma warning(push)
#pragma warning(disable : 4996)
#include <direct.h>
#include <windows.h>

#define _GETCWD(buf, size) _getcwd(buf, size)
#define _CHDIR(dir) _chdir(dir)
#define _SETENV(name, value, overwrite) (TRUE == SetEnvironmentVariableA(name, value) ? 0 : 1)
#else
#include <unistd.h>

#define _GETCWD(buf, size) getcwd(buf, size)
#define _CHDIR(dir) chdir(dir)
#define _SETENV(name, value, overwrite) setenv(name, value, overwrite)
#endif // _WIN32

#define ENV_KEY_OMP_NUM_THREADS "OMP_NUM_THREADS"
#define ENV_VALUE_OMP_NUM_THREADS "2" //"4"

// setenv("KMP_DUPLICATE_LIB_OK", "true", 1);
#define ENV_KEY_KMP_DUPLICATE_LIB_OK "KMP_DUPLICATE_LIB_OK"
#define ENV_VALUE_KMP_DUPLICATE_LIB_OK "true"

static volatile unsigned int g_initialized_times = 0;

int common_global_init()
{
	if (g_initialized_times++ > 0)
	{
		return 0;
	}
	global_func_impl_dummy_invoke();
#ifdef _WIN32
	// on stdlib.h
	extern int system(const char *command);
	// let windows console print utf8 characters.
	system("chcp 65001");
#endif // _WIN32
	lcu_global_init();
	
	LOGI("hello: build on (%s %s), lcu_ver=%s", __DATE__, __TIME__, lcu_get_version());
	LOGI("your env: PLATFORM=%s, PLATFORM_ABI=%s", _PLATFORM, _PLATFORM_ABI);

#define _SETUP_AND_SHOW_ENV(KEY, VALUE)                      \
	do                                                       \
	{                                                        \
		if (0 != common_setenv(KEY, VALUE, 1))               \
		{                                                    \
			LOGE("failed on setenv(%s, %s)", KEY, VALUE);    \
		}                                                    \
		LOGI("getenv(%s) = %s ", KEY, common_getenv(VALUE)); \
	} while (0)

	_SETUP_AND_SHOW_ENV(ENV_KEY_OMP_NUM_THREADS, ENV_VALUE_OMP_NUM_THREADS);
	_SETUP_AND_SHOW_ENV(ENV_KEY_KMP_DUPLICATE_LIB_OK, ENV_VALUE_KMP_DUPLICATE_LIB_OK);
	return 0;
}

int common_setenv(const char *name, const char *value, int overwrite)
{
	return _SETENV(name, value, overwrite);
}

char *common_getenv(const char *name)
{
	return getenv(name);
}

int common_chdir(const char *dir)
{
	return _CHDIR(dir);
}

int common_getcwd(char *buffer, size_t size)
{
	return (NULL == _GETCWD(buffer, size)) ? 1 : 0;
}

bool common_find_last_slash(char *file_path, size_t file_path_len, size_t *last_slash_index_p)
{
	bool find_slash = false;
	*last_slash_index_p = 0;
	if (NULL == file_path || '\0' == file_path[0] ||
		(0 == file_path_len && 0 == (file_path_len = strlen(file_path))))
	{
		return false;
	}

	for (size_t slash_index = file_path_len - 1U; slash_index > 0; --slash_index)
	{
		if ('/' == file_path[slash_index] || '\\' == file_path[slash_index])
		{
			*last_slash_index_p = slash_index;
			find_slash = true;
			break;
		}
	}
	return find_slash;
}

int common_aligned32_read_file(const char *file_path,
							   void **out_mem_origin_pp, long *file_size_p, void **out_mem_aligned_pp)
{
	if (!file_path || '\0' == file_path[0] ||
		!out_mem_origin_pp || !file_size_p || !out_mem_aligned_pp)
	{
		return -1;
	}

	int ret = -1;
	FILE *fp = fopen(file_path, "rb");
	if (!fp)
	{
		LOGE("failed on fopen \"%s\"", file_path);
		return -2;
	}
	fseek(fp, 0, SEEK_END);
	const long file_size = ftell(fp);
	*file_size_p = file_size;
	LOGD("\"%s\" size=%d", file_path, (int)file_size);
	do
	{
		if (file_size < 1)
		{
			ret = -3;
			break;
		}
		fseek(fp, 0, SEEK_SET);
		const size_t file_alloc_size = (size_t)file_size + 64U;
		void *mem_origin_p = malloc(file_alloc_size);
		if (NULL == mem_origin_p)
		{
			ret = -4;
			break;
		}
		void *mem_aligned_p = MEM_ALIGN_PTR_32(mem_origin_p);

		char *writable_mem = (char *)mem_aligned_p;
		writable_mem[file_size] = '\0'; // place '\0' for string file
		if ((size_t)file_size != fread(writable_mem, 1, (size_t)file_size, fp))
		{
			free(mem_origin_p);
			ret = -5;
			break;
		}
		*out_mem_origin_pp = mem_origin_p;
		*out_mem_aligned_pp = mem_aligned_p;

		ret = 0;
	} while (0);

	fclose(fp);
	return ret;
}

int common_global_cleanup()
{
	if (0 == g_initialized_times || --g_initialized_times > 0)
	{
		return 0;
	}
	LOGI("bye, cleanup...");
	lcu_global_cleanup();
	return 0;
}

#ifdef _WIN32
#pragma warning(pop)
#endif // _WIN32
