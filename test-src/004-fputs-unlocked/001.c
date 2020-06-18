#define _GNU_SOURCE
#include <stdio.h>

int main(void)
{
  fprintf (stderr, "stdout %p\n", stdout);
  fputs_unlocked ("hello world\n", stdout);
}
