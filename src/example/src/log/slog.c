#include "log/slog.h"
#include <stddef.h>
#include <stdio.h>  /* for snprintf */
#include <string.h>  

//extern 
LogLevel _g_slog_min_level = LOG_LEVEL_VERBOSE;

#if(!defined(_LCU_LOGGER_UNSUPPORT_STDOUT_REDIRECT) || 0 == _LCU_LOGGER_UNSUPPORT_STDOUT_REDIRECT)
typedef struct slog_config
{
	/* the file pointer after redirect stdout */
	FILE* fp_out;
} slog_config_t;

static slog_config_t g_slog = { NULL };
#endif // !_LCU_LOGGER_UNSUPPORT_STDOUT_REDIRECT

void slog_set_min_level(LogLevel min_level)
{
	if (min_level < LOG_LEVEL_OFF || min_level > LOG_LEVEL_ERROR)
	{
		fprintf(stderr, "[slog] (%s:%d) invalid min_level:%d\n", __func__, __LINE__, min_level);
		return; // invalid min_level
	}
	fprintf(stderr, "[slog] (%s:%d) set new log_min_level:%d\n", __func__, __LINE__, min_level);
	_g_slog_min_level = min_level;
}

LogLevel slog_get_min_level()
{
	return _g_slog_min_level;
}

#if(!defined(_LCU_LOGGER_UNSUPPORT_STDOUT_REDIRECT) || 0 == _LCU_LOGGER_UNSUPPORT_STDOUT_REDIRECT)
#ifdef _WIN32
#pragma warning(push)
#pragma warning(disable:4996) //for disable freopen warning
#endif // _WIN32

void slog_stdout2file(char* file_path)
{
	if (NULL == file_path || '\0' == file_path[0])
	{
		return;
	}
	if (g_slog.fp_out && (g_slog.fp_out != stdout))
	{
		fprintf(stderr, "[slog] (%s:%d) WARN: did you forgot to close the redirect stdout file stream!\n", __func__, __LINE__);
		fflush(g_slog.fp_out);
		fclose(g_slog.fp_out);
	}
	fflush(stdout);
	g_slog.fp_out = freopen(file_path, "w", stdout);
	if (!g_slog.fp_out)
	{
		fprintf(stderr, "[slog] (%s:%d) Error: failed on freopen to file(%s)\n", __func__, __LINE__, file_path);
	}
}

void slog_back2stdout()
{
	if (!g_slog.fp_out)
	{
		return;
	}
	// must close current stream first, and then reopen it
	fflush(g_slog.fp_out);
	fclose(g_slog.fp_out);
	g_slog.fp_out = NULL;
	if (!freopen(_STDOUT_NODE, "w", stdout))
	{
		fprintf(stderr, "[slog] (%s:%d) Error: failed on freopen to stdout\n", __func__, __LINE__);
	}
}

#ifdef _WIN32
#pragma warning(pop)
#endif // _WIN32

#endif // !_LCU_LOGGER_UNSUPPORT_STDOUT_REDIRECT

static size_t slog_str_char2hex(char* out_hex_str, size_t out_hex_str_capacity,
	const char* chars, size_t chars_count)
{
#define ONE_HEX_STR_SIZE (3U)
	size_t len_hex_str = 0U;
	out_hex_str[0] = '\0';

	if (chars_count * ONE_HEX_STR_SIZE >= out_hex_str_capacity)
	{
		len_hex_str = (size_t)snprintf(out_hex_str, out_hex_str_capacity - 1U, "hex truncated(%zu):", chars_count);
		chars_count = out_hex_str_capacity / ONE_HEX_STR_SIZE - 1U;
	}
	for (size_t chars_index = 0U; chars_index < chars_count; ++chars_index)
	{
		int ret_sn = snprintf(out_hex_str + len_hex_str,
			out_hex_str_capacity - len_hex_str - 1,
			" %02x", (unsigned char)chars[chars_index]);
		if (ONE_HEX_STR_SIZE != ret_sn /*ret_sn < 0*/) /* should be ONE_HEX_STR_SIZE */
		{
			break; // oops, error occurred
		}
		len_hex_str += (size_t)ret_sn;
	}
	return len_hex_str;
}

void __slog_internal_hex_print(int level, const char* tag, const char* chars, size_t chars_count)
{
	char buf[256];// use small stack size
	slog_str_char2hex(buf, sizeof(buf), chars, chars_count);
	switch (level)
	{
	case LOG_LEVEL_VERBOSE:
		SLOGV(tag, "%s", buf);
		break;
	case LOG_LEVEL_DEBUG:
		SLOGD(tag, "%s", buf);
		break;
	case LOG_LEVEL_INFO:
		SLOGI(tag, "%s", buf);
		break;
	case LOG_LEVEL_WARN:
		SLOGW(tag, "%s", buf);
		break;
	case LOG_LEVEL_ERROR:
	default:
		SLOGE(tag, "%s", buf);
		break;
	}
}
