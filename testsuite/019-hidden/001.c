int f(void) __attribute__((visibility("hidden")));

int f(void)
{
  return 7;
}

int main(void)
{
  return f();
}
