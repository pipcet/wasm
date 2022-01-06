#include <stdio.h>

void f(int (*main)(void))
{
  printf("%d\n", main == __builtin_return_address(0));
}

int main(void)
{
  f(main);
}
