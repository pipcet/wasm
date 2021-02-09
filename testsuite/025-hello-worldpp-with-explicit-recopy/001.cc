#include <iostream>

extern "C" {
  asm(".include \"wasm32-import-macros.s\"");
  extern void __thinthin_recopy(void) __attribute__((stackcall));
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
