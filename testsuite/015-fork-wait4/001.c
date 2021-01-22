#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>

int main(void)
{
  pid_t pid = fork();

  if (pid) {
    printf("here1 %d %d\n", pid, wait4(pid, 0, 0, 0));
  } else {
    printf("here0\n");
  }

  return 0;
}
