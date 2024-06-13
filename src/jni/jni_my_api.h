#pragma once
#ifndef JNI_MY_API_H
#define JNI_MY_API_H

#include <jni.h>

#define JNI_USE_VERSION JNI_VERSION_1_6
// #define JNI_USE_VERSION  JNI_VERSION_1_8

#ifdef __cplusplus
extern "C"
{
#endif

    jint jni_my_api_OnLoad(JavaVM *vm, void *reserved);

    void jni_my_api_OnUnload(JavaVM *vm, void *reserved);

#ifdef __cplusplus
}
#endif

#endif // !JNI_MY_API_H
