#include <pthread.h>

int main(void)
{
  pthread_t thread;
  pthread_create(&thread, NULL, NULL, NULL);
}
