#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
  jmp_buf buf;
  if (setjmp(buf)) {
    printf("2nd\n");
    exit(0);
  } else {
    printf("1st\n");
    longjmp(buf, 1);
  }
}
