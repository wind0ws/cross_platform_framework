
#include "common.h"
#define LOG_TAG "DEMO"
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

	// do your business here

	LOGD_TRACE("bye bye...");
	COMMON_GLOBAL_CLEANUP();
	return 0;
}
