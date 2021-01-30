#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv, char **envp)
{
  printf("environ %p %p\n", __environ, &__environ);
  while (*envp) {
    printf("%s\n", *envp++);
  }
  return 0;
}
