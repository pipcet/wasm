#include <stdio.h>
#include <ctype.h>
#include <locale.h>

int main(void)
{
  printf ("%d\n", !!isprint('a'));
}
