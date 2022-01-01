$VAR1 = {
          '*(statbufptr + &stat::st_mtim + &timespec::tv_sec) = 1LL' => 'this.HEAP32[statbufptr+88>>2] = 1; this.HEAP32[statbufptr+88+4>>2] = 0;',
          '*intptr = "avail"' => 'this.HEAP32[intptr>>2] = avail;',
          '*intptr = 0' => 'this.HEAP32[intptr>>2] = 0;',
          '0' => '0',
          'AT_EMPTY_PATH' => '4096',
          'AT_FDCWD' => '-100',
          'AT_FDROOTD' => '-101',
          'EBADF' => '9',
          'EEXIST' => '17',
          'EINVAL' => '22',
          'EIO' => '5',
          'EISDIR' => '21',
          'ENAMETOOLONG' => '36',
          'ENOENT' => '2',
          'ENOSYS' => '38',
          'ENOTDIR' => '20',
          'ERANGE' => '34',
          'ETIME' => '62',
          'FIONREAD' => '21531',
          'F_DUPFD' => '0',
          'F_GETFL' => '3',
          'F_SETFD' => '2',
          'F_SETFL' => '4',
          'O_CREAT' => '64',
          'O_DIRECTORY' => '65536',
          'O_RDWR' => '2',
          'O_WRONLY' => '1',
          'POLLIN' => '1',
          'SEEK_CUR' => '1',
          'SEEK_END' => '2',
          'SEEK_SET' => '0',
          'S_IFDIR' => '16384',
          'S_IFDIR + 0777' => '16895',
          'WNOHANG' => '1',
          '__S_IFCHR + 0777' => '8703',
          '__S_IFREG + 0777' => '33279',
          'default_sizes.memsize' => '536870912',
          'default_sizes.stackbottom' => '535822336',
          'default_sizes.stacksize' => '1048576',
          'default_sizes.tablesize' => '65536',
          'direntp + &dirent::d_name' => 'direntp+19',
          'direntp[&dirent::d_ino] = 1' => 'this.HEAP32[direntp>>2] = 1; this.HEAP32[direntp+4>>2] = 0;',
          'direntp[&dirent::d_off] = "0"' => 'this.HEAP32[direntp+8>>2] = 0;',
          'direntp[&dirent::d_reclen] = "s + l"' => 'this.HEAP16[direntp+16>>1] = s + l;',
          'fdsptr[i+&pollfd::events]' => 'this.HEAP16[fdsptr+i*8+4>>1]',
          'fdsptr[i+&pollfd::fd]' => 'this.HEAP32[fdsptr+i*8>>2]',
          'fdsptr[i+&pollfd::revents]' => 'this.HEAP16[fdsptr+i*8+6>>1]',
          'fdsptr[i+&pollfd::revents] = 0' => 'this.HEAP16[fdsptr+i*8+6>>1] = 0;',
          'iov[i+&iovec::iov_base]' => 'this.HEAP32[iov+i*8>>2]',
          'iov[i+&iovec::iov_len]' => 'this.HEAP32[iov+i*8+4>>2]',
          'libinfo[&libinfo->data] = "module.dyninfo.data"' => 'this.HEAP32[libinfo>>2] = module.dyninfo.data;',
          'libinfo[&libinfo->data_end] = "module.dyninfo.data_end"' => 'this.HEAP32[libinfo+8>>2] = module.dyninfo.data_end;',
          'libinfo[&libinfo->modid] = "this.process.modules.length"' => 'this.HEAP32[libinfo+16>>2] = this.process.modules.length;',
          'sizeof(dirent)' => '280',
          'sizeof(struct stat)' => '176',
          'statbufptr[&stat::st_blksize] = "fd.size()"' => 'this.HEAP32[statbufptr+56>>2] = fd.size();',
          'statbufptr[&stat::st_blocks] = "1"' => 'this.HEAP32[statbufptr+64>>2] = 1;',
          'statbufptr[&stat::st_mode] = "fd.mode()"' => 'this.HEAP32[statbufptr+24>>2] = fd.mode();',
          'statbufptr[&stat::st_nlink] = 1LL' => 'this.HEAP32[statbufptr+16>>2] = 1; this.HEAP32[statbufptr+16+4>>2] = 0;',
          'statbufptr[&stat::st_size] = "fd.size()"' => 'this.HEAP32[statbufptr+48>>2] = fd.size();',
          'timespec[&timespec::tv_nsec] = "ns"' => 'this.HEAP32[timespec+8>>2] = ns;',
          'timespec[&timespec::tv_nsec] = 0' => 'this.HEAP32[timespec+8>>2] = 0; this.HEAP32[timespec+8+4>>2] = 0;',
          'timespec[&timespec::tv_nsec] = 0LL' => 'this.HEAP32[timespec+8>>2] = 0; this.HEAP32[timespec+8+4>>2] = 0;',
          'timespec[&timespec::tv_sec] = "s"' => 'this.HEAP32[timespec>>2] = s;',
          'timespec[&timespec::tv_sec] = 0' => 'this.HEAP32[timespec>>2] = 0; this.HEAP32[timespec+4>>2] = 0;',
          'timespec[&timespec::tv_sec] = 0LL' => 'this.HEAP32[timespec>>2] = 0; this.HEAP32[timespec+4>>2] = 0;',
          'tp1' => '8192',
          'tp1[&threadpage::bottom_of_stack] = "module.bottom_of_stack"' => 'HEAP32[8192+24>>2] = module.bottom_of_stack;',
          'tp1[&threadpage::id] = "1"' => 'HEAP32[8192+16>>2] = 1;',
          'tp1[&threadpage::initsp] = -1' => 'HEAP32[8192+64>>2] = -1;',
          'tp1[&threadpage::next]' => 'HEAP32[8192>>2]',
          'tp1[&threadpage::pc] = "process.entry"' => 'HEAP32[8192+48>>2] = process.entry;',
          'tp1[&threadpage::prev]' => 'HEAP32[8192+8>>2]',
          'tp1[&threadpage::sp] = "sp"' => 'HEAP32[8192+56>>2] = sp;',
          'tp1[&threadpage::top_of_stack] = "module.top_of_stack"' => 'HEAP32[8192+32>>2] = module.top_of_stack;',
          'tp1[&tp1->bottom_of_stack] = "module.bottom_of_stack"' => 'HEAP32[8192+24>>2] = module.bottom_of_stack;',
          'tp1[&tp1->id] = "1"' => 'HEAP32[8192+16>>2] = 1;',
          'tp1[&tp1->initsp]' => 'HEAP32[8192+80>>2]',
          'tp1[&tp1->initsp] = "sp"' => 'HEAP32[8192+80>>2] = sp;',
          'tp1[&tp1->initsp] = -1' => 'HEAP32[8192+80>>2] = 4294967295; HEAP32[8192+80+4>>2] = 4294967295;',
          'tp1[&tp1->next]' => 'HEAP32[8192>>2]',
          'tp1[&tp1->pc]' => 'HEAP32[8192+48>>2]',
          'tp1[&tp1->pc] = "pc"' => 'HEAP32[8192+48>>2] = pc;',
          'tp1[&tp1->pc] = "process.entry"' => 'HEAP32[8192+48>>2] = process.entry;',
          'tp1[&tp1->prev]' => 'HEAP32[8192+8>>2]',
          'tp1[&tp1->sp]' => 'HEAP32[8192+72>>2]',
          'tp1[&tp1->sp] = "sp"' => 'HEAP32[8192+72>>2] = sp;',
          'tp1[&tp1->top_of_stack] = "module.top_of_stack"' => 'HEAP32[8192+32>>2] = module.top_of_stack;',
          'tp[&tp->initsp]' => 'this.HEAP32[this.threadpage+80>>2]',
          'tp[&tp->pc]' => 'this.HEAP32[this.threadpage+48>>2]',
          'tp[&tp->sp]' => 'this.HEAP32[this.threadpage+72>>2]',
          'tp[&tp->stop_reason]' => 'this.HEAP32[this.threadpage+40>>2]',
          'tvptr[&timeval::tv_sec]' => 'this.HEAP32[tvptr>>2]',
          'tvptr[&timeval::tv_sec] = "s"' => 'this.HEAP32[tvptr>>2] = s;',
          'tvptr[&timeval::tv_usec]' => 'this.HEAP32[tvptr+8>>2]',
          'tvptr[&timeval::tv_usec] = "us"' => 'this.HEAP32[tvptr+8>>2] = us;',
          'zp[&zeropage::bottom_of_sbrk] = "module.start_of_sbrk"' => 'HEAP32[4096+24>>2] = module.start_of_sbrk;',
          'zp[&zeropage::thread_list]' => 'HEAP32[4096+16>>2]',
          'zp[&zeropage::top_of_memory]' => 'HEAP32[4096>>2]',
          'zp[&zeropage::top_of_memory] = "module.top_of_memory"' => 'HEAP32[4096>>2] = module.top_of_memory;',
          'zp[&zeropage::top_of_sbrk]' => 'HEAP32[4096+8>>2]',
          'zp[&zeropage::top_of_sbrk] = "tos"' => 'HEAP32[4096+8>>2] = tos;',
          'zp[&zp->bottom_of_sbrk] = "module.start_of_sbrk"' => 'HEAP32[4096+24>>2] = module.start_of_sbrk;',
          'zp[&zp->thread_list]' => 'HEAP32[4096+16>>2]',
          'zp[&zp->top_of_memory]' => 'HEAP32[4096>>2]',
          'zp[&zp->top_of_memory] = "module.top_of_memory"' => 'HEAP32[4096>>2] = module.top_of_memory;',
          'zp[&zp->top_of_memory] = 512 * 1024 * 1024LL' => 'HEAP32[4096>>2] = 536870912; HEAP32[4096+4>>2] = 0;',
          'zp[&zp->top_of_sbrk]' => 'HEAP32[4096+8>>2]',
          'zp[&zp->top_of_sbrk] = "32 * 1024 * 1024"' => 'HEAP32[4096+8>>2] = 32 * 1024 * 1024;',
          'zp[&zp->top_of_sbrk] = "tom"' => 'HEAP32[4096+8>>2] = tom;',
          'zp[&zp->top_of_sbrk] = "tos"' => 'HEAP32[4096+8>>2] = tos;'
        };
