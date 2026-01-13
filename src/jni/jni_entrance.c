#define LOG_TAG "API_JNI"
#include "my_logger.h"
#include "lcu.h"
#include "jni_my_api.h"

static volatile unsigned char g_load_times = 0;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved)
{
	if (g_load_times++ > 0)
	{
		return JNI_USE_VERSION;
	}
    int ret = lcu_global_init();
    LOGI("JNI_OnLoad called. lcu_init=%d, ver=\"%s\"", ret, lcu_get_version());
    ret = (int)jni_my_api_OnLoad(vm, reserved);
    return (jint)ret;
}

JNIEXPORT void JNICALL JNI_OnUnload(JavaVM *vm, void *reserved)
{
	if (0 == g_load_times || --g_load_times > 0)
	{
		return;
	}
    jni_my_api_OnUnload(vm, reserved);

    LOGI("JNI_OnUnload called. bye...");
    lcu_global_cleanup();
}
