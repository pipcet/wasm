OUTPUT_FORMAT(binary)
SECTIONS
{
  .data : SUBALIGN(1)  {
      *(.output)
      *(.header)
      *(.got*)
      *(.data)
      *(.bss)
      *(.preinit_array)
      *(.ctors)
      *(.dtors)
      *(.output.named)
      *(.output.target_features)
  }
  /DISCARD/ : { *(.discard*) *(*) }
}
