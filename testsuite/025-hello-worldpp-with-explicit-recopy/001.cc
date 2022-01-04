#include <iostream>

#ifndef SHARED
#define SHARED /* currently, the static libstdc++ isn't being built. */
#endif

extern "C" {
  asm(".include \"wasm32-import-macros.s\"");
  extern void __thinthin_recopy(void) __attribute__((stackcall));
#ifdef SHARED
  asm(".import3 thinthin,recopy,__thinthin_recopy");
#endif
};

int main()
{
  __thinthin_recopy();
  __thinthin_recopy();
  __thinthin_recopy();
  __thinthin_recopy();
  __thinthin_recopy();
  __thinthin_recopy();
  __thinthin_recopy();
  __thinthin_recopy();
  std::cout << "hello world++\n";
}
