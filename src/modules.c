#include "common.h"

#ifdef __ANDROID__
#include <android/log.h>
#endif
#define LOG_TAG "MODULES"
#include "log/logger.h"

int modules_state()
{
	#ifdef __ANDROID__
	 __android_log_print(ANDROID_LOG_VERBOSE, "TAG", "%s", "hello");
	#endif 
	LOGD_TRACE("hello, %d", __LINE__);
	return common_init();
	//return 0;
}
