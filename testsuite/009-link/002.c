#define _GNU_SOURCE
#include <stdio.h>

extern int x;

int main(void)
{
  const char *s;
  asprintf(&s, "x: %d\n", x);
  puts(s);
  return 0;
}
