#include <stdio.h>
#include <stdlib.h>

int main(void)
{
  fprintf (stderr, "hi\n");
  fflush (stderr);
  abort ();
}
