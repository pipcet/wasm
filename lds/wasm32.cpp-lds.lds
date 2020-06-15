ENTRY(_start)
SECTIONS
{
  .output : {
    LONG(0x6d736100)
    LONG(1)
    KEEP(*(.wasm.header_id.type)) BYTE((((__wasm_type_payload_end - __wasm_type_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_type_payload_end - __wasm_type_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_type_payload_end - __wasm_type_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_type_payload_end - __wasm_type_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_type_payload_end - __wasm_type_payload)>>4*7)&0x7f)); __wasm_type_payload = .; *(.wasm.header.type); BYTE((((__wasm_space_type_end - __wasm_space_type)>>0*7)&0x7f)|0x80); BYTE((((__wasm_space_type_end - __wasm_space_type)>>1*7)&0x7f)|0x80); BYTE((((__wasm_space_type_end - __wasm_space_type)>>2*7)&0x7f)|0x80); BYTE((((__wasm_space_type_end - __wasm_space_type)>>3*7)&0x7f)|0x80); BYTE((((__wasm_space_type_end - __wasm_space_type)>>4*7)&0x7f)); *(.wasm.type); __wasm_type_payload_end = .;
    KEEP(*(.wasm.header_id.import)) BYTE((((__wasm_import_payload_end - __wasm_import_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_import_payload_end - __wasm_import_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_import_payload_end - __wasm_import_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_import_payload_end - __wasm_import_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_import_payload_end - __wasm_import_payload)>>4*7)&0x7f)); __wasm_import_payload = .; *(.wasm.header.import); BYTE((((__wasm_space_import_end - __wasm_space_import)>>0*7)&0x7f)|0x80); BYTE((((__wasm_space_import_end - __wasm_space_import)>>1*7)&0x7f)|0x80); BYTE((((__wasm_space_import_end - __wasm_space_import)>>2*7)&0x7f)|0x80); BYTE((((__wasm_space_import_end - __wasm_space_import)>>3*7)&0x7f)|0x80); BYTE((((__wasm_space_import_end - __wasm_space_import)>>4*7)&0x7f)); *(.wasm.import); __wasm_import_payload_end = .;
    KEEP(*(.wasm.header_id.function)) BYTE((((__wasm_function_payload_end - __wasm_function_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_function_payload_end - __wasm_function_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_function_payload_end - __wasm_function_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_function_payload_end - __wasm_function_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_function_payload_end - __wasm_function_payload)>>4*7)&0x7f)); __wasm_function_payload = .; *(.wasm.header.function); BYTE((((__wasm_space_function_end - __wasm_space_function)>>0*7)&0x7f)|0x80); BYTE((((__wasm_space_function_end - __wasm_space_function)>>1*7)&0x7f)|0x80); BYTE((((__wasm_space_function_end - __wasm_space_function)>>2*7)&0x7f)|0x80); BYTE((((__wasm_space_function_end - __wasm_space_function)>>3*7)&0x7f)|0x80); BYTE((((__wasm_space_function_end - __wasm_space_function)>>4*7)&0x7f)); *(.wasm.function); __wasm_function_payload_end = .;


    KEEP(*(.wasm.header_id.global)) BYTE((((__wasm_global_payload_end - __wasm_global_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_global_payload_end - __wasm_global_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_global_payload_end - __wasm_global_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_global_payload_end - __wasm_global_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_global_payload_end - __wasm_global_payload)>>4*7)&0x7f)); __wasm_global_payload = .; *(.wasm.header.global); BYTE((((__wasm_space_global_end - __wasm_space_global)>>0*7)&0x7f)|0x80); BYTE((((__wasm_space_global_end - __wasm_space_global)>>1*7)&0x7f)|0x80); BYTE((((__wasm_space_global_end - __wasm_space_global)>>2*7)&0x7f)|0x80); BYTE((((__wasm_space_global_end - __wasm_space_global)>>3*7)&0x7f)|0x80); BYTE((((__wasm_space_global_end - __wasm_space_global)>>4*7)&0x7f)); *(.wasm.global); __wasm_global_payload_end = .;
    KEEP(*(.wasm.header_id.export)) BYTE((((__wasm_export_payload_end - __wasm_export_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_export_payload_end - __wasm_export_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_export_payload_end - __wasm_export_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_export_payload_end - __wasm_export_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_export_payload_end - __wasm_export_payload)>>4*7)&0x7f)); __wasm_export_payload = .; *(.wasm.header.export); BYTE((((__wasm_space_export_end - __wasm_space_export)>>0*7)&0x7f)|0x80); BYTE((((__wasm_space_export_end - __wasm_space_export)>>1*7)&0x7f)|0x80); BYTE((((__wasm_space_export_end - __wasm_space_export)>>2*7)&0x7f)|0x80); BYTE((((__wasm_space_export_end - __wasm_space_export)>>3*7)&0x7f)|0x80); BYTE((((__wasm_space_export_end - __wasm_space_export)>>4*7)&0x7f)); *(.wasm.export); __wasm_export_payload_end = .;

    *(.wasm.header_id.element) BYTE((((__wasm_element_payload_end - __wasm_element_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_element_payload_end - __wasm_element_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_element_payload_end - __wasm_element_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_element_payload_end - __wasm_element_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_element_payload_end - __wasm_element_payload)>>4*7)&0x7f)); __wasm_element_payload = .; *(.wasm.header.element); BYTE(1); BYTE(0); BYTE(0x23); BYTE(0x01); BYTE(0x0b); BYTE((((__wasm_space_element_end - __wasm_space_element)>>0*7)&0x7f)|0x80); BYTE((((__wasm_space_element_end - __wasm_space_element)>>1*7)&0x7f)|0x80); BYTE((((__wasm_space_element_end - __wasm_space_element)>>2*7)&0x7f)|0x80); BYTE((((__wasm_space_element_end - __wasm_space_element)>>3*7)&0x7f)|0x80); BYTE((((__wasm_space_element_end - __wasm_space_element)>>4*7)&0x7f)); *(.wasm.element); __wasm_element_payload_end = .;
    KEEP(*(.wasm.header_id.code)) BYTE((((__wasm_code_payload_end - __wasm_code_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_code_payload_end - __wasm_code_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_code_payload_end - __wasm_code_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_code_payload_end - __wasm_code_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_code_payload_end - __wasm_code_payload)>>4*7)&0x7f)); __wasm_code_payload = .; *(.wasm.header.code); BYTE((((__wasm_space_code_end - __wasm_space_code)>>0*7)&0x7f)|0x80); BYTE((((__wasm_space_code_end - __wasm_space_code)>>1*7)&0x7f)|0x80); BYTE((((__wasm_space_code_end - __wasm_space_code)>>2*7)&0x7f)|0x80); BYTE((((__wasm_space_code_end - __wasm_space_code)>>3*7)&0x7f)|0x80); BYTE((((__wasm_space_code_end - __wasm_space_code)>>4*7)&0x7f)); *(.wasm.code); __wasm_code_payload_end = .;
    *(.wasm.header_id.data); BYTE((((__wasm_data_header_end - __wasm_data_header + __wasm_data_segment_end - __wasm_data_segment)>>0*7)&0x7f)|0x80); BYTE((((__wasm_data_header_end - __wasm_data_header + __wasm_data_segment_end - __wasm_data_segment)>>1*7)&0x7f)|0x80); BYTE((((__wasm_data_header_end - __wasm_data_header + __wasm_data_segment_end - __wasm_data_segment)>>2*7)&0x7f)|0x80); BYTE((((__wasm_data_header_end - __wasm_data_header + __wasm_data_segment_end - __wasm_data_segment)>>3*7)&0x7f)|0x80); BYTE((((__wasm_data_header_end - __wasm_data_header + __wasm_data_segment_end - __wasm_data_segment)>>4*7)&0x7f)); *(.wasm.header.data); __wasm_data_header = .; BYTE(1); BYTE(0); BYTE(0x23); BYTE(0x00); BYTE(0x0b); BYTE((((__wasm_data_segment_end - __wasm_data_segment)>>0*7)&0x7f)|0x80); BYTE((((__wasm_data_segment_end - __wasm_data_segment)>>1*7)&0x7f)|0x80); BYTE((((__wasm_data_segment_end - __wasm_data_segment)>>2*7)&0x7f)|0x80); BYTE((((__wasm_data_segment_end - __wasm_data_segment)>>3*7)&0x7f)|0x80); BYTE((((__wasm_data_segment_end - __wasm_data_segment)>>4*7)&0x7f)); __wasm_data_header_end = .;
  }
  . = 16384;
  .asmjs.header :
  {
    __wasm_data_segment = .;
    *(.asmjs.header);
  }
  .data : ALIGN(1) SUBALIGN(1)
  {
     *(.got)
     __data_start = .;
     *(.data*)
     *(.tm_clone_table)
     *(.gnu.linkonce.d.*)
     *(.rodata*)
     *(.jcr*)
     *(.dynbss)
     *(.bss* .gnu.linkonce.b.*)
     *(.gcc_except_table*)
     *(.eh_frame*)
     __start___libc_atexit = .;
     *(__libc_atexit)
     __stop___libc_atexit = .;
     __start___libc_subfreeres = .;
     *(__libc_subfreeres)
     __stop___libc_subfreeres = .;
     *(__libc_thread_subfreeres)
     *(__libc_freeres_ptrs)
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP (*(.init_array EXCLUDE_FILE (*crtend.o *crtend?.o) .ctors))
    PROVIDE_HIDDEN (__init_array_end = .);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
    KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
    PROVIDE_HIDDEN (__fini_array_end = .);
  }
  .bss :
  {
     *(COMMON)
     *(.tbss*)
  }
  .preinit_array :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  }
  .ctors :
  {
    KEEP (*crtbegin.o(.ctors))
    KEEP (*crtbegin?.o(.ctors))




    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
  }
  .dtors :
  {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*crtbegin?.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
    __wasm_data_segment_end = .;
    __wasm_data_payload_end = .;
  }
  .output.named (INFO) : {
    *(.wasm.header_id.name) BYTE((((__wasm_name_payload_end - __wasm_name_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_name_payload_end - __wasm_name_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_name_payload_end - __wasm_name_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_name_payload_end - __wasm_name_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_name_payload_end - __wasm_name_payload)>>4*7)&0x7f)); __wasm_name_payload = .; *(.wasm.header.name); BYTE(1) BYTE((((__wasm_name_function_payload_end - __wasm_name_function_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_name_function_payload_end - __wasm_name_function_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_name_function_payload_end - __wasm_name_function_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_name_function_payload_end - __wasm_name_function_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_name_function_payload_end - __wasm_name_function_payload)>>4*7)&0x7f)) __wasm_name_function_payload = .; BYTE((((__wasm_space_name_function_end - __wasm_space_name_function)>>0*7)&0x7f)|0x80); BYTE((((__wasm_space_name_function_end - __wasm_space_name_function)>>1*7)&0x7f)|0x80); BYTE((((__wasm_space_name_function_end - __wasm_space_name_function)>>2*7)&0x7f)|0x80); BYTE((((__wasm_space_name_function_end - __wasm_space_name_function)>>3*7)&0x7f)|0x80); BYTE((((__wasm_space_name_function_end - __wasm_space_name_function)>>4*7)&0x7f)); *(.wasm.name.function) *(.wasm.name.function.plt) __wasm_name_function_payload_end = .; BYTE(2) BYTE((((__wasm_name_local_payload_end - __wasm_name_local_payload)>>0*7)&0x7f)|0x80); BYTE((((__wasm_name_local_payload_end - __wasm_name_local_payload)>>1*7)&0x7f)|0x80); BYTE((((__wasm_name_local_payload_end - __wasm_name_local_payload)>>2*7)&0x7f)|0x80); BYTE((((__wasm_name_local_payload_end - __wasm_name_local_payload)>>3*7)&0x7f)|0x80); BYTE((((__wasm_name_local_payload_end - __wasm_name_local_payload)>>4*7)&0x7f)) __wasm_name_local_payload = .; BYTE((((__wasm_space_name_local_end - __wasm_space_name_local)>>0*7)&0x7f)|0x80); BYTE((((__wasm_space_name_local_end - __wasm_space_name_local)>>1*7)&0x7f)|0x80); BYTE((((__wasm_space_name_local_end - __wasm_space_name_local)>>2*7)&0x7f)|0x80); BYTE((((__wasm_space_name_local_end - __wasm_space_name_local)>>3*7)&0x7f)|0x80); BYTE((((__wasm_space_name_local_end - __wasm_space_name_local)>>4*7)&0x7f)); *(.wasm.name.local) __wasm_name_local_payload_end = .; __wasm_name_payload_end = .;
  }
  .discard.space.function_index : { __wasm_space_function_index = .; *(.space.function_index.import); *(.space.function_index.*); *(.space.function_index*); *(.space.function_index_.plt); __wasm_space_function_index_end = .; __wasm_space_function_index_size = . - __wasm_space_function_index; }
  .discard.space.global_index : { __wasm_space_global_index = .; *(.space.global_index.import); *(.space.global_index.*); *(.space.global_index*); *(.space.global_index_.plt); __wasm_space_global_index_end = .; __wasm_space_global_index_size = . - __wasm_space_global_index; }
  .discard.space.type : { __wasm_space_type = .; *(.space.type.import); *(.space.type.*); *(.space.type*); *(.space.type_.plt); __wasm_space_type_end = .; __wasm_space_type_size = . - __wasm_space_type; }
  .discard.space.import : { __wasm_space_import = .; *(.space.import.import); *(.space.import.*); *(.space.import*); *(.space.import_.plt); __wasm_space_import_end = .; __wasm_space_import_size = . - __wasm_space_import; }
  .discard.space.function : { __wasm_space_function = .; *(.space.function.import); *(.space.function.*); *(.space.function*); *(.space.function_.plt); __wasm_space_function_end = .; __wasm_space_function_size = . - __wasm_space_function; }


  .discard.space.global : { __wasm_space_global = .; *(.space.global.import); *(.space.global.*); *(.space.global*); *(.space.global_.plt); __wasm_space_global_end = .; __wasm_space_global_size = . - __wasm_space_global; }
  .discard.space.export : { __wasm_space_export = .; *(.space.export.import); *(.space.export.*); *(.space.export*); *(.space.export_.plt); __wasm_space_export_end = .; __wasm_space_export_size = . - __wasm_space_export; }
  .discard.space.element : { __wasm_space_element = .; *(.space.element.import); *(.space.element.*); *(.space.element*); *(.space.element_.plt); __wasm_space_element_end = .; __wasm_space_element_size = . - __wasm_space_element; }
  .discard.space.code : { __wasm_space_code = .; *(.space.code.import); *(.space.code.*); *(.space.code*); *(.space.code_.plt); __wasm_space_code_end = .; __wasm_space_code_size = . - __wasm_space_code; }
  .discard.space.data : { __wasm_space_data = .; *(.space.data.import); *(.space.data.*); *(.space.data*); *(.space.data_.plt); __wasm_space_data_end = .; __wasm_space_data_size = . - __wasm_space_data; }
  .discard.space.name : { __wasm_space_name = .; __wasm_space_name_function = .; *(.space.name.function.import); *(.space.name.function.*); *(.space.name.function*); *(.space.name.function_.plt); __wasm_space_name_function_end = .; __wasm_space_name_local = .; *(.space.name.local.import); *(.space.name.local.*); *(.space.name.local*); *(.space.name.local_.plt); __wasm_space_name_local_end = .; __wasm_space_name_size = . - __wasm_space_name; }
  /DISCARD/ : { *(.asmjs.term) *(.dynamic) *(.rela.dyn) *(.rela.plt) *(.plt) }
}
