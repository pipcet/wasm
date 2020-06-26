asm (".data\n\t"
     ".p2align 7\n\t"
     ".globl foo\n"
     "foo:\n\t"
     ".byte 0\n\t"
     "text_section");

int main(void)
{
  return 0;
}
