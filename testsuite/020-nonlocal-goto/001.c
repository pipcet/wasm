#include <stdio.h>

int main(void)
{
  __label__ out;
  volatile int x0 = 7;
  printf("x0 at %p\n", &x0);
  int f(int x)
  {
    volatile int y0 = 3;
    printf("before non-local jump\n");
    if (x && x0)
      goto out;
    printf("after non-local jump\n");
    return x0 + x;
  }
  if (f(8))
    return 0;

  printf("falling through\n");
 out:
  printf("received non-local jump\n");
  printf("x0 at %p\n", &x0);
  printf("x0 = %d\n", x0);
  return 1;
}
