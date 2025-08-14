#pragma once
#ifndef CJSON_WRAPPER_H
#define CJSON_WRAPPER_H

#include "mem/strings.h" /* for strlcpy */
#include <stdlib.h>      /* for atoi */
#include <stdbool.h>

#define USE_CUSTOM_CJSON 1

#if (!defined(USE_CUSTOM_CJSON) || 0 == USE_CUSTOM_CJSON)

#include <cJSON.h>

#else

#ifdef cJSON__h
#error "you have been include cJSON.h before! do not both use cJSON.h and my_cjson.h at the same file!"
#endif // cJSON__h

#include "my_cjson.h"
#define CUSTOM_CJSON_PREFIX my_

#ifndef _BASE_CONCAT
#define _BASE_CONCAT(x, y) x##y
#endif
#define CONCAT1(x, y) _BASE_CONCAT(x, y)

#ifndef cJSON_Invalid
#define cJSON_Invalid CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Invalid) 
#define cJSON_False   CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_False)   
#define cJSON_True    CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_True)    
#define cJSON_NULL    CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_NULL) 
#define cJSON_Number  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Number)  
#define cJSON_String  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_String)  
#define cJSON_Array   CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Array)   
#define cJSON_Object  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Object)  
#define cJSON_Raw     CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Raw)

#define cJSON_IsReference    CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsReference)
#define cJSON_StringIsConst  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_StringIsConst)   

#define _TMP_STRUCT_CJSON_HOOKS struct CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Hooks)
typedef _TMP_STRUCT_CJSON_HOOKS cJSON_Hooks;
#endif // !cJSON_Invalid

#define cJSON_Version()                                                                             CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Version())
#define cJSON_InitHooks(hooks)                                                                      CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_InitHooks(hooks))
#define cJSON_Parse(value)                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Parse(value))
#define cJSON_ParseWithLength(value, buffer_length)                                                 CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_ParseWithLength(value, buffer_length))
#define cJSON_ParseWithOpts(value, return_parse_end, require_null_terminated)                       CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_ParseWithOpts(value, return_parse_end, require_null_terminated))
#define cJSON_ParseWithLengthOpts(value, buffer_length, return_parse_end, require_null_terminated)  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_ParseWithLengthOpts(value, buffer_length, return_parse_end, require_null_terminated))
#define cJSON_Print(item)                                                                           CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Print(item))
#define cJSON_PrintUnformatted(item)                                                                CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_PrintUnformatted(item))
#define cJSON_PrintBuffered(item, prebuffer, fmt)                                                   CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_PrintBuffered(item, prebuffer, fmt))
#define cJSON_PrintPreallocated(item, buffer, length, format)                                       CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_PrintPreallocated(item, buffer, length, format))
#define cJSON_Delete(item)                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Delete(item))
#define cJSON_GetArraySize(array)                                                                   CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_GetArraySize(array))
#define cJSON_GetArrayItem(array, index)                                                            CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_GetArrayItem(array, index))
#define cJSON_GetObjectItem(object, string)                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_GetObjectItem(object, string))
#define cJSON_GetObjectItemCaseSensitive(object, string)                                            CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_GetObjectItemCaseSensitive(object, string))
#define cJSON_HasObjectItem(object, string)                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_HasObjectItem(object, string))
#define cJSON_GetErrorPtr()                                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_GetErrorPtr())
#define cJSON_GetStringValue(item)                                                                  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_GetStringValue(item))
#define cJSON_GetNumberValue(item)                                                                  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_GetNumberValue(item))
#define cJSON_IsInvalid(item)                                                                       CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsInvalid(item))
#define cJSON_IsFalse(item)                                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsFalse(item))
#define cJSON_IsTrue(item)                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsTrue(item))
#define cJSON_IsBool(item)                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsBool(item))
#define cJSON_IsNull(item)                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsNull(item))
#define cJSON_IsNumber(item)                                                                        CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsNumber(item))
#define cJSON_IsString(item)                                                                        CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsString(item))
#define cJSON_IsArray(item)                                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsArray(item))
#define cJSON_IsObject(item)                                                                        CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsObject(item))
#define cJSON_IsRaw(item)                                                                           CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_IsRaw(item))
#define cJSON_CreateNull()                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateNull())
#define cJSON_CreateTrue()                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateTrue())
#define cJSON_CreateFalse()                                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateFalse())
#define cJSON_CreateBool(boolean)                                                                   CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateBool(boolean))
#define cJSON_CreateNumber(num)                                                                     CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateNumber(num))
#define cJSON_CreateString(string)                                                                  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateString(string))
#define cJSON_CreateRaw(raw)                                                                        CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateRaw(raw))
#define cJSON_CreateArray()                                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateArray())
#define cJSON_CreateObject()                                                                        CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateObject())
#define cJSON_CreateStringReference(string)                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateStringReference(string))
#define cJSON_CreateObjectReference(child)                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateObjectReference(child))
#define cJSON_CreateArrayReference(child)                                                           CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateArrayReference(child))
#define cJSON_CreateIntArray(numbers, count)                                                        CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateIntArray(numbers, count))
#define cJSON_CreateFloatArray(numbers, count)                                                      CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateFloatArray(numbers, count))
#define cJSON_CreateDoubleArray(numbers, count)                                                     CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateDoubleArray(numbers, count))
#define cJSON_CreateStringArray(strings, count)                                                     CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_CreateStringArray(strings, count))
#define cJSON_AddItemToArray(array, item)                                                           CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddItemToArray(array, item))
#define cJSON_AddItemToObject(object, string, item)                                                 CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddItemToObject(object, string, item))
#define cJSON_AddItemToObjectCS(object, string, item)                                               CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddItemToObjectCS(object, string, item))
#define cJSON_AddItemReferenceToArray(array, item)                                                  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddItemReferenceToArray(array, item))
#define cJSON_AddItemReferenceToObject(object, string, item)                                        CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddItemReferenceToObject(object, string, item))
#define cJSON_DetachItemViaPointer(parent, item)                                                    CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_DetachItemViaPointer(parent, item))
#define cJSON_DetachItemFromArray(array, which)                                                     CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_DetachItemFromArray(array, which))
#define cJSON_DeleteItemFromArray(array, which)                                                     CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_DeleteItemFromArray(array, which))
#define cJSON_DetachItemFromObject(object, string)                                                  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_DetachItemFromObject(object, string))
#define cJSON_DetachItemFromObjectCaseSensitive(object, string)                                     CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_DetachItemFromObjectCaseSensitive(object, string))
#define cJSON_DeleteItemFromObject(object, string)                                                  CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_DeleteItemFromObject(object, string))
#define cJSON_DeleteItemFromObjectCaseSensitive(object, string)                                     CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_DeleteItemFromObjectCaseSensitive(object, string))
#define cJSON_InsertItemInArray(array, which, newitem)                                              CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_InsertItemInArray(array, which, newitem))
#define cJSON_ReplaceItemViaPointer(parent, item, replacement)                                      CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_ReplaceItemViaPointer(parent, item, replacement))
#define cJSON_ReplaceItemInArray(array, which, newitem)                                             CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_ReplaceItemInArray(array, which, newitem))
#define cJSON_ReplaceItemInObject(object, string, newitem)                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_ReplaceItemInObject(object, string, newitem))
#define cJSON_ReplaceItemInObjectCaseSensitive(object, string, newitem)                             CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_ReplaceItemInObjectCaseSensitive(object, string, newitem))
#define cJSON_Duplicate(item, recurse)                                                              CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Duplicate(item, recurse))
#define cJSON_Compare(a, b, case_sensitive)                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Compare(a, b, case_sensitive))
#define cJSON_Minify(json)                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_Minify(json))
#define cJSON_AddNullToObject(object, name)                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddNullToObject(object, name))
#define cJSON_AddTrueToObject(object, name)                                                         CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddTrueToObject(object, name))
#define cJSON_AddFalseToObject(object, name)                                                        CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddFalseToObject(object, name))
#define cJSON_AddBoolToObject(object, name, boolean)                                                CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddBoolToObject(object, name, boolean))
#define cJSON_AddNumberToObject(object, name, number)                                               CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddNumberToObject(object, name, number))
#define cJSON_AddStringToObject(object, name, string)                                               CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddStringToObject(object, name, string))
#define cJSON_AddRawToObject(object, name, raw)                                                     CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddRawToObject(object, name, raw))
#define cJSON_AddObjectToObject(object, name)                                                       CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddObjectToObject(object, name))
#define cJSON_AddArrayToObject(object, name)                                                        CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_AddArrayToObject(object, name))
#define cJSON_SetNumberHelper(object, number)                                                       CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_SetNumberHelper(object, number))
#define cJSON_SetValuestring(object, valuestring)                                                   CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_SetValuestring(object, valuestring))
#define cJSON_malloc(size)                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_malloc(size))
#define cJSON_free(object)                                                                          CONCAT1(CUSTOM_CJSON_PREFIX, cJSON_free(object))

#endif // !USE_CUSTOM_CJSON

//======================================================================================================================================
// 提取 json item中的数字, 并将解析结果放到 (target_var)
#define _CJSON_EXTRACT_INT(target_var, json_item)                                                                     \
    if (cJSON_Number == (json_item)->type)                                                                            \
    {                                                                                                                 \
        (target_var) = (json_item)->valueint;                                                                         \
    }                                                                                                                 \
    else if ((cJSON_String == (json_item)->type) && ('\0' != (json_item)->valuestring[0]))                            \
    {                                                                                                                 \
        (target_var) = atoi((json_item)->valuestring);                                                                \
    }                                                                                                                 \
    else                                                                                                              \
    {                                                                                                                 \
        LOGE_TRACE("\"" #json_item "\" is not number or string, unsupported json value type: %d", (json_item)->type); \
    }

// =========== START: 从 JSON节点 中找出指定 "key" 字段, 并获取该字段值 ===========
#define _INTERNAL_2_CJSON_EXTRACT_INT_BY_KEY(LINE_NUM, target_var, json_node, key) \
    cJSON *_item_##key_##LINE_NUM = cJSON_GetObjectItem((json_node), #key);        \
    if (NULL == _item_##key_##LINE_NUM)                                            \
    {                                                                              \
        LOGD_TRACE("no key \"%s\" in json", #key);                                 \
    }                                                                              \
    else                                                                           \
    {                                                                              \
        _CJSON_EXTRACT_INT(target_var, _item_##key_##LINE_NUM);                    \
    }

#define _INTERNAL_1_CJSON_EXTRACT_INT_BY_KEY(LINE_NUM, target_var, json_node, key) \
    _INTERNAL_2_CJSON_EXTRACT_INT_BY_KEY(LINE_NUM, target_var, json_node, key)

// 提取 json node中指定 key 的数字. 注意: 这个 key 参数不要加双引号, 比如直接传 key 而不是 "key"
#define _CJSON_EXTRACT_INT_BY_KEY(target_var, json_node, key) \
    _INTERNAL_1_CJSON_EXTRACT_INT_BY_KEY(__LINE__, target_var, json_node, key)
// =========== END: 从 JSON节点 中找出指定 "key" 字段, 并获取该字段值 ===========

//================================
#define _INTERNAL_2_CJSON_EXTRACT_INT_BY_KEY_OR_BREAK(LINE_NUM, target_var, json_node, key) \
    _INTERNAL_1_CJSON_EXTRACT_INT_BY_KEY(LINE_NUM, target_var, json_node, key);             \
    if (NULL == _item_##key_##LINE_NUM)                                                     \
    {                                                                                       \
        break;                                                                              \
    }

#define _INTERNAL_1_CJSON_EXTRACT_INT_BY_KEY_OR_BREAK(LINE_NUM, target_var, json_node, key) \
    _INTERNAL_2_CJSON_EXTRACT_INT_BY_KEY_OR_BREAK(LINE_NUM, target_var, json_node, key)

// 提取 json node中指定 key 的数字, 找不到指定的 key 则 break, 适合在 循环体 或 do_while 中使用.
// 注意: 这个 key 参数不要加双引号, 比如直接传 key 而不是 "key"
#define _CJSON_EXTRACT_INT_BY_KEY_OR_BREAK(target_var, json_node, key) \
    _INTERNAL_1_CJSON_EXTRACT_INT_BY_KEY_OR_BREAK(__LINE__, target_var, json_node, key)
//================================
//======================================================================================================================================

//======================================================================================================================================
//================================
// 提取 json node中指定 key 的 value 字符串
#define _INTERNAL_2_CJSON_EXTRACT_STR_BY_KEY(LINE_NUM, target_var, target_var_size, json_node, key)                                \
    cJSON *_item_##key_##LINE_NUM = cJSON_GetObjectItem((json_node), #key);                                                        \
    const bool _##key##_##LINE_NUM##_not_exists = (NULL == _item_##key_##LINE_NUM || NULL == _item_##key_##LINE_NUM->valuestring); \
    if (_##key##_##LINE_NUM##_not_exists)                                                                                          \
    {                                                                                                                              \
        LOGD_TRACE("no key \"%s\" in json", #key);                                                                                 \
    }                                                                                                                              \
    else                                                                                                                           \
    {                                                                                                                              \
        if (strlcpy(target_var, _item_##key_##LINE_NUM->valuestring, target_var_size) >= (target_var_size))                        \
        {                                                                                                                          \
            LOGE_TRACE(" truncation occurred during copy \"%s\":\"%s\" <-- value too long, target_var_size = %d",                  \
                       #key, _item_##key_##LINE_NUM->valuestring, (int)target_var_size);                                           \
        }                                                                                                                          \
    }

// 展开 LINE_NUM
#define _INTERNAL_1_CJSON_EXTRACT_STR_BY_KEY(LINE_NUM, target_var, target_var_size, json_node, key) \
    _INTERNAL_2_CJSON_EXTRACT_STR_BY_KEY(LINE_NUM, target_var, target_var_size, json_node, key)

// 提取 json node中指定 key 的 value 字符串
// 注意: 这个 key 参数不要加双引号, 比如直接传 key 而不是 "key"
#define _CJSON_EXTRACT_STR_BY_KEY(target_var, target_var_size, json_node, key) \
    _INTERNAL_1_CJSON_EXTRACT_STR_BY_KEY(__LINE__, target_var, target_var_size, json_node, key)
//================================

//================================
#define _INTERNAL_2_CJSON_EXTRACT_STR_BY_KEY_OR_BREAK(LINE_NUM, target_var, target_var_size, json_node, key) \
    _INTERNAL_1_CJSON_EXTRACT_STR_BY_KEY(LINE_NUM, target_var, target_var_size, json_node, key)              \
    if (_##key##_##LINE_NUM##_not_exists)                                                                    \
    {                                                                                                        \
        break;                                                                                               \
    }

#define _INTERNAL_1_CJSON_EXTRACT_STR_BY_KEY_OR_BREAK(LINE_NUM, target_var, target_var_size, json_node, key) \
    _INTERNAL_2_CJSON_EXTRACT_STR_BY_KEY_OR_BREAK(LINE_NUM, target_var, target_var_size, json_node, key)

// 提取 json node中指定 key 的value字符串, 找不到指定的 key 则 break
// 注意: 这个 key 参数不要加双引号, 比如直接传 key 而不是 "key"
#define _CJSON_EXTRACT_STR_BY_KEY_OR_BREAK(target_var, target_var_size, json_node, key) \
    _INTERNAL_1_CJSON_EXTRACT_STR_BY_KEY_OR_BREAK(__LINE__, target_var, target_var_size, json_node, key)
//================================

//======================================================================================================================================

// 清理 cjson node_root(根节点)
#define _CJSON_CLEANUP(node_root) \
    if (NULL != (node_root))      \
    {                             \
        cJSON_Delete(node_root);  \
        (node_root) = NULL;       \
    }

//======================================================================================================================================

#endif // ！CJSON_WRAPPER_H
