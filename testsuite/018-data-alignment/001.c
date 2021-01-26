#include <stdio.h>

double x __attribute__((aligned(128)));

int main(void)
{
  printf("%p\n", &x);
  return 0;
}
