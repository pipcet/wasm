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
    int status;
    printf("here1 %d %d\n", pid, wait4(pid, &status, 0, 0));
    printf("status %d\n", status);
  } else {
    printf("here0\n");
  }

  return 1;
}
