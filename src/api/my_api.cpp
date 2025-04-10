#include "my_api.h"
#include "version.h"

ATTR_PUBLIC(const char *) my_api_get_version()
{
	return PRJ_VERSION;
}
