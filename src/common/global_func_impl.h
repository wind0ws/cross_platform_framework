#pragma once
#ifndef _GLOBAL_FUNC_IMPL_H
#define _GLOBAL_FUNC_IMPL_H

#ifdef __cplusplus
extern "C" {
#endif

  // 这个方法里并不实现什么，主要是为了让别的.o调用依赖他，从而把此源文件编译的.o打到静态库中
  void global_func_impl_dummy_invoke();

#ifdef __cplusplus
}
#endif

#endif // !_GLOBAL_FUNC_IMPL_H
