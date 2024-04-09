#include "common.h"
#include "lcu.h"

#define LOG_TAG "COMMON"
#include "my_logger.h"

static volatile unsigned int g_init_times = 0;

int common_global_init()
{
	if (g_init_times++ > 0)
	{
		return 0;
	}
	lcu_global_init();
	LOGI("hello: %s, build on (%s %s)", lcu_get_version(), __DATE__, __TIME__);
	return 0;
}

int common_global_cleanup()
{
	if (0 == g_init_times || --g_init_times > 0)
	{
		return 0;
	}
	LOGI("bye, cleanup...");
	lcu_global_cleanup();
	return 0;
}
