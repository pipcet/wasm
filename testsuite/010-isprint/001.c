#include <stdio.h>
#include <ctype.h>
#include <locale.h>

int main(void)
{
  uselocale (LC_GLOBAL_LOCALE);
  printf ("%p\n", uselocale (LC_GLOBAL_LOCALE)->__ctype_b);
  printf ("%d\n", isprint_l('a', uselocale (LC_GLOBAL_LOCALE)));
}
