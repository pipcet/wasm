#include <unistd.h>

int main(void)
{
  pid_t pid = fork();

  if (pid) {
    printf("here1 %d\n", pid);
  } else {
    printf("here0\n");
  }

  return 0;
}
