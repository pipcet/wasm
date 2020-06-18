asm(".include \"wasm32-import-macros.s\"");
asm(".include \"syscall.S\"");
asm(".import3 thinthin,write,__thinthin_write");
asm(".import3 thinthin,exit,__thinthin_exit");
extern void __thinthin_write(int, char *, int) __attribute__((stackcall));
extern void __thinthin_exit(int);

void _start(void)
{
  __thinthin_write(1, "hi!\n", 4);
  __thinthin_exit(0);
}
