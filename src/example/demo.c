
#include <stdio.h>


int main(int argc, char *argv[])
{
	for (int i=0;i < argc; ++i)
	{
		printf("argv[%d]=%s\n", i, argv[i]);
	}
	extern int modules_state();
	return modules_state();
}
