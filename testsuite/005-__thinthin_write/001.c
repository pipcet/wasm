asm(".include \"wasm32-import-macros.s\"");
#ifdef SHARED
asm(".import3 thinthin,write,__thinthin_write");
#endif
extern void __thinthin_write(int, char *, int) __attribute__((stackcall));

int main(void)
{
  __thinthin_write(1, "hi!\n", 4);
}
