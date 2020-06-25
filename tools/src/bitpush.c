#define _GNU_SOURCE

#include <stdio.h>
#include <poll.h>
#include <signal.h>
#include <sys/sendfile.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
  char *outname;
  asprintf (&outname, "%s/in", argv[1]);
  char *inname;
  asprintf (&inname, "%s/out", argv[1]);
  char *pidname;
  asprintf (&inname, "%s/pid", argv[1]);
  int ofd = open (inname, O_RDONLY | O_NONBLOCK);

  while (1) {
    struct pollfd pfd[2] = {
      { 0, POLLIN, 0 },
      { ofd, POLLIN, 0 },
    };

    poll (pfd, 2, -1);
    if ((pfd[0].revents & POLLERR)
	|| (pfd[1].revents & POLLERR))
      {
	fprintf (stderr, "ouch, dying\n");
	int fd;
	fd = open (pidname, O_RDONLY);
	if (fd >= 0) {
	  char buf[512];
	  ssize_t n = read (fd, buf, 512);
	  buf[n] = 0;
	  pid_t pid = atoi(buf);
	  kill(pid, SIGKILL);
	  exit(1);
	}
      }
    if (pfd[0].revents & POLLIN) {
      char buf[512];
      ssize_t n = read (0, buf, sizeof buf);
      int fd;
      do {
	fd = open (outname, O_CREAT|O_EXCL|O_RDWR, 0660);
	if (fd > 0) {
	  write (fd, buf, n);
	  close (fd);
	}
      } while (fd < 0);
    }
    if (pfd[1].revents & POLLIN) {
      char buf[512];
      ssize_t n = read (ofd, buf, sizeof buf);
      write (1, buf, n);
    }
  }
}
