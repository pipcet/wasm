#NO_APP
	.include "wasm32-macros.s"
	text_section
	.section .rodata
	.LC0:
	.ascii "hello world\0"
	.section	.text.startup,"ax",@progbits
	.pushsection .wasm.code.%S,2*__wasm_counter+1,"ax"
	.global main
	defun main, FiiiiiiiE
	.labeldef_debug .LFB11
	local.get $sp
	i32.const -64
	i32.add
	local.set $sp
	local.get $sp
	local.set $fp
	.labeldef_debug .LCFI0
	i32.const .LC0
	local.set $r0
	i32.const -1
	local.get $sp
	local.get $r0
	local.get $r1
	i32.const 0
	i32.const 0
	call puts@plt{__sigchar_FiiiiiiiE}
	local.tee $rp
	i32.const 3
	i32.and
	if[]
	.dpc .LI12
	local.set $dpc
	throw1
	end
	.wasmtextlabeldpcdef .LI12
	i32.const 8288
	i32.const 0
	i32.store a=2 0
	i32.const 64
	local.get $fp
	i32.add
	return
	.set __wasm32_fallthrough, 0
	.labeldef_debug .LFE11
	nextcase
	local.get $sp
	local.set $rp
	i32.const 16
	local.get $rp
	i32.add
	i32.load a=2 0
	local.set $dpc
	i32.const 32
	local.get $rp
	i32.add
	i32.load a=2 0
	local.set $sp
	i32.const 48
	local.get $rp
	i32.add
	i32.load a=2 0
	local.set $r0
	i32.const 56
	local.get $rp
	i32.add
	i32.load a=2 0
	local.set $r1
	local.get $rp
	local.set $fp
	jump2
	nextcase
	end
	i32.const 3
	local.get $rp
	i32.and
	i32.const 1
	i32.ne
	if[]
	local.get $rp
	return
	end
	local.get $sp
	i32.const -16
	i32.add
	local.get $fp
	i32.store a=2 0
	local.get $sp
	i32.const -8
	i32.add
	global.get $gpo
	local.get $dpc
	i32.const __wasm_pc_base_main
	i32.add
	i32.add
	i32.store a=2 0
	i32.const 0
	local.get $fp
	i32.add
	local.get $fp
	i32.const 64
	i32.add
	i32.store a=2 0
	i32.const 8
	local.get $fp
	i32.add
	global.get $plt
	i32.const main
	i32.add
	i32.store a=2 0
	i32.const 16
	local.get $fp
	i32.add
	local.get $dpc
	i32.store a=2 0
	i32.const 24
	local.get $fp
	i32.add
	global.get $gpo
	local.get $dpc
	i32.const __wasm_pc_base_main
	i32.add
	i32.add
	i32.store a=2 0
	i32.const 28
	local.get $fp
	i32.add
	global.get $gpo
	i32.const __wasm_pc_base_main
	i32.add
	i32.store a=2 0
	i32.const 32
	local.get $fp
	i32.add
	local.get $sp
	i32.store a=2 0
	i32.const 40
	local.get $fp
	i32.add
	i32.const 48
	i32.store a=2 0
	i32.const 48
	local.get $fp
	i32.add
	local.get $r0
	i32.store a=2 0
	i32.const 56
	local.get $fp
	i32.add
	local.get $r1
	i32.store a=2 0
	local.get $rp
	return
	end
	endefun main
	.section	.debug_frame,"",@progbits
	.Lframe0:
	.4byte	.LECIE0-.LSCIE0
	.LSCIE0:
	.4byte	0xffffffff
	.byte	0x3
	.ascii "\0"
	.uleb128 0x1
	.sleb128 -4
	.uleb128 0x24
	.byte	0xc
	.uleb128 0x2
	.uleb128 0
	.byte	0x11
	.uleb128 0x24
	.sleb128 -2
	.p2align 2
	.LECIE0:
.LSFDE0:
	.4byte	.LEFDE0-.LASFDE0
	.LASFDE0:
	.4byte	.Lframe0
	.4byte	.LFB11
	.4byte	.LFE11-.LFB11
	.byte	0x4
	.4byte	.LCFI0-.LFB11
	.byte	0x11
	.uleb128 0x24
	.sleb128 -6
	.byte	0x10
	.byte	0
	.uleb128 0x9
	.byte	0x72
	.sleb128 0
	.byte	0x72
	.sleb128 0
	.byte	0x6
	.byte	0x72
	.sleb128 0
	.byte	0x1c
	.byte	0x22
	.byte	0xd
	.uleb128 0
	.p2align 2
	.LEFDE0:
	.section	.eh_frame,"aw",@progbits
	.Lframe1:
	.4byte	.LECIE1-.LSCIE1
	.LSCIE1:
	.4byte	0
	.byte	0x3
	.ascii "\0"
	.uleb128 0x1
	.sleb128 -4
	.uleb128 0x24
	.byte	0xc
	.uleb128 0x2
	.uleb128 0
	.byte	0x11
	.uleb128 0x24
	.sleb128 -2
	.p2align 2
	.LECIE1:
.LSFDE3:
	.4byte	.LEFDE3-.LASFDE3
	.LASFDE3:
	.4byte	.LASFDE3-.Lframe1
	.4byte	.LFB11
	.4byte	.LFE11-.LFB11
	.byte	0x4
	.4byte	.LCFI0-.LFB11
	.byte	0x11
	.uleb128 0x24
	.sleb128 -6
	.byte	0x10
	.byte	0
	.uleb128 0x9
	.byte	0x72
	.sleb128 0
	.byte	0x72
	.sleb128 0
	.byte	0x6
	.byte	0x72
	.sleb128 0
	.byte	0x1c
	.byte	0x22
	.byte	0xd
	.uleb128 0
	.p2align 2
	.LEFDE3:
