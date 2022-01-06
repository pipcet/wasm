#include <pthread.h>
#include <stdio.h>

int main(void)
{
  pthread_t thread;
#if 0
  fprintf(stderr, "creating...\n");
  pthread_create(&thread, NULL, NULL, NULL);
  fprintf(stderr, "created.\n");
#endif
}
