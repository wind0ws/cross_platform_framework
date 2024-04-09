
#include "common.h"
#define LOG_TAG "COMMON_TEST"
#include "my_logger.h"
#include <stdio.h>

int main(int argc, char *argv[])
{
	COMMON_GLOBAL_INIT();
	for (int i = 0; i < argc; ++i)
	{
		printf("argv[%d]=%s\n", i, argv[i]);
	}
	LOGD_TRACE("hello...");

	LOG_SET_MIN_LEVEL(LOG_LEVEL_DEBUG);
    LOGV("you won't see this line.");
    LOG_SET_MIN_LEVEL(LOG_LEVEL_VERBOSE);

	LOGD_TRACE("bye bye...");
	COMMON_GLOBAL_CLEANUP();
	return 0;
}
