int main(void)
{
  __label__ out;
  volatile int x0 = 7;
  int f(int x)
  {
    if (x && x0)
      return x0 + x;
    goto out;
  }
  if (f(8))
    return 0;

 out:
  return 1;
}
