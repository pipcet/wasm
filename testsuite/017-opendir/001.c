#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>

int main(void)
{
  printf ("%p\n", opendir("."));
  return 0;
}
