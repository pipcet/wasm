#define _GNU_SOURCE
#include <stdio.h>

int main(void)
{
  fputs_unlocked (stdout, "hello world\n");
}
