
#include "jni_my_api.h"
#include "my_api.h"
#define LOG_TAG "API_JNI"
#include "my_logger.h"
#include "common_macro.h"


jint jni_my_api_OnLoad(JavaVM *vm, void *reserved)
{
	UNUSED(vm);
    UNUSED(reserved);

	LOGI_TRACE("OnLoad");
    return JNI_USE_VERSION;
}

void jni_my_api_OnUnload(JavaVM *vm, void *reserved)
{
	UNUSED(vm);
    UNUSED(reserved);
	LOGI_TRACE("OnUnload");
}

JNIEXPORT jstring JNICALL
Java_com_my_jni_MyApiJni_version(JNIEnv *env, jclass clazz)
{
    UNUSED(clazz);
    const char *version = my_api_get_version();
    return (*env)->NewStringUTF(env, version);
}
