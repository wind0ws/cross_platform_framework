
#include "common.h"
#include "lcu.h"

int common_init()
{
	lcu_global_init();
	return 0;
}

int common_destroy()
{
	lcu_global_cleanup();
	return 0;
}
