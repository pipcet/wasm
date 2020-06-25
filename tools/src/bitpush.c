#define _GNU_SOURCE

#include <stdio.h>
#include <poll.h>
#include <signal.h>
#include <sys/sendfile.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char **argv)
{
  char *outname;
  asprintf (&outname, "%s/in", argv[1]);
  char *inname;
  asprintf (&inname, "%s/out", argv[1]);
  int ofd = open (inname, O_RDONLY | O_NONBLOCK);

  while (1) {
    struct pollfd pfd[2] = {
      { 0, POLLIN, 0 },
      { ofd, POLLIN, 0 },
    };

    poll (pfd, 2, -1);
    if (pfd[0].revents & POLLIN) {
      char buf[512];
      ssize_t n = read (0, buf, sizeof buf);
      fprintf (stderr, "read %.*s\n", n, buf);
      int fd = open (outname, O_CREAT|O_EXCL|O_RDWR, 0660);
      if (fd > 0) {
	write (fd, buf, n);
	close (fd);
      }
    }
    if (pfd[1].revents & POLLIN) {
      char buf[512];
      ssize_t n = read (ofd, buf, sizeof buf);
      fprintf (stderr, "write %.*s\n", n, buf);
      write (1, buf, n);
    }
  }
}
