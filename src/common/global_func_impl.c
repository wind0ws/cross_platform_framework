#include "global_func_impl.h"

void global_func_impl_dummy_invoke()
{
    return;
}

#if (defined(__ANDROID__))

/* copy from "sysroot/usr/include/android/legacy_stdlib_inlines.h"
   notice: 低于 android-21 的版本没有全局 atof 等一系列函数，在 stdlib.h 里是内联的，
           但是有些第三方库用到了非内联版本，所以这里实现全局函数.
*/
#if (ANDROID_PLATFORM_LEVEL < 21)
#include <sys/cdefs.h>
#include <errno.h>
#include <float.h>

#ifndef NULL
#define NULL (void *)0
#endif // !NULL

extern double strtod(const char *nptr, char **endptr);
extern float strtof(const char *nptr, char **endptr);
extern long double strtold(const char *nptr, char **endptr);
extern long int lrand48(void);
extern void srand48(long int seedval);

float strtof(const char *nptr, char **endptr)
{
    double d = strtod(nptr, endptr);
    if (d > (double)(FLT_MAX))
    {
        errno = ERANGE;
        return __builtin_huge_valf();
    }
    else if (d < (double)(-FLT_MAX))
    {
        errno = ERANGE;
        return -__builtin_huge_valf();
    }
    return __BIONIC_CAST(static_cast, float, d);
}

double atof(const char *nptr) { return (strtod(nptr, NULL)); }

int abs(int __n) { return (__n < 0) ? -__n : __n; }

long labs(long __n) { return (__n < 0L) ? -__n : __n; }

long long llabs(long long __n) { return (__n < 0LL) ? -__n : __n; }

int rand(void) { return (int)lrand48(); }

void srand(unsigned int __s) { srand48((long)(__s)); }

long random(void) { return lrand48(); }

void srandom(unsigned int __s) { srand48((long)(__s)); }

int grantpt(int __fd __attribute((unused)))
{
    return 0; /* devpts does this all for us! */
}

#endif // ANDROID_PLATFORM_LEVEL < 21

#endif // __ANDROID__
