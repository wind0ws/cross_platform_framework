# ---------------------------------------------------------------------------------------
# IDE support for headers
# ---------------------------------------------------------------------------------------
set(PRJ_HEADERS_DIR "${CMAKE_CURRENT_LIST_DIR}/../include")

file(GLOB PRJ_TOP_HEADERS "${PRJ_HEADERS_DIR}/turbo/*.h")
file(GLOB PRJ_DETAIL_HEADERS "${PRJ_HEADERS_DIR}/turbo/detail/*.h")
file(GLOB PRJ_FILESYSTEM_HEADERS "${PRJ_HEADERS_DIR}/turbo/filesystem/*.h")
file(GLOB PRJ_LOG_HEADERS "${PRJ_HEADERS_DIR}/turbo/log/*.h")
file(GLOB PRJ_STREAM_HEADERS "${PRJ_HEADERS_DIR}/turbo/stream/*.h")
file(GLOB PRJ_STRING_HEADERS "${PRJ_HEADERS_DIR}/turbo/string/*.h")
file(GLOB PRJ_THREAD_HEADERS "${PRJ_HEADERS_DIR}/turbo/thread/*.h")
set(PRJ_ALL_HEADERS ${PRJ_TOP_HEADERS} ${PRJ_DETAIL_HEADERS} ${PRJ_FILESYSTEM_HEADERS} ${PRJ_LOG_HEADERS}
    ${PRJ_STREAM_HEADERS} ${PRJ_STRING_HEADERS} ${PRJ_THREAD_HEADERS})

source_group("Header Files\\turbo" FILES ${PRJ_TOP_HEADERS})
source_group("Header Files\\turbo\\detail" FILES ${PRJ_DETAIL_HEADERS})
source_group("Header Files\\turbo\\filesystem" FILES ${PRJ_FILESYSTEM_HEADERS})
source_group("Header Files\\turbo\\log" FILES ${PRJ_LOG_HEADERS})
source_group("Header Files\\turbo\\stream" FILES ${PRJ_STREAM_HEADERS})
source_group("Header Files\\turbo\\string" FILES ${PRJ_STRING_HEADERS})
source_group("Header Files\\turbo\\thread" FILES ${PRJ_THREAD_HEADERS})
