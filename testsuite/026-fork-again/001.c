#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>

int main(void)
{
  pid_t pid;
  int pipes[2];
  pipe(pipes);

  if ((pid = fork())) {
    int status;
    char c;
    close(pipes[1]);
    while (read(pipes[0], &c, 1)) {
      write(1, &c, 1);
      write(1, &c, 1);
    }
    printf("here1 %d %d\n", pid, wait4(pid, &status, 0, 0));
    printf("status %d\n", status);
  } else {
    close(pipes[0]);
    dup2(pipes[1], 1);
    execl("/bin/echo", "echo", "hi there", NULL);
    execl("/bin/echo", "echo", "notreached", NULL);
    return 1;
  }

  return 0;
}
