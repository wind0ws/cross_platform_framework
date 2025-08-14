#define LOG_TAG "MODULES"
#include "my_logger.h"
#ifdef __ANDROID__
#include <android/log.h>
#include <jni.h>
#else
#include "my_api.h"
#endif

int __dummy_modules_state()
{
	LOGD_TRACE("hello on %s:%d", __FILE__, __LINE__);

#ifdef __ANDROID__
	__android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, "%s", "hello");
	extern jint JNI_OnLoad(JavaVM *vm, void *reserved);
	// dummy invoke. for link libraries
	JNI_OnLoad(NULL, NULL);
#else
	LOGI("ver: %s", my_api_get_version());
#endif
	return 0;
}
