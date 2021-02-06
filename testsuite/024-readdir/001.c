#include <stdio.h>
#include <unistd.h>
#include <dirent.h>

int main(void)
{
  DIR *dir = opendir (".");

  if (!dir)
    {
      printf("failed\n");
      return 1;
    }

  struct dirent *dirent;
  while (dirent = readdir (dir))
    {
      printf("name %s\n", dirent->d_name);
    }

  printf("done\n");

  return 0;
}
