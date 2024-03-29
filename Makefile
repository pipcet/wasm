# wasm32/cross: build=host=x86_64-pc-linux-gnu target=wasm32-unknown-none
# wasm32/native: build=x86_64-pc-linux-gnu host=target=wasm32-unknown-none
# wasm32/wasm: wasm versions of wasm32/native
# wasm32/pure: build=host=target=wasm32-unknown-none

native-triplet = x86_64-pc-linux-gnu

# $(MKDIR) command
MKDIR ?= mkdir -p
LN ?= ln -sf
# $(PWD) is the top-level directory. No recursion here (except for subrepos).
PWD ?= $(shell pwd)
OPT_NATIVE ?= "-Os"
OPT_WASM ?= "-O2"
WASMDIR ?= $(PWD)
JS ?= $$JS

ARTIFACTS ?= all

.SECONDEXPANSION:

# This has to be the first rule: build everything, currently scattered over too many directories.

all!: wasm/libc.wasm wasm/ld.wasm wasm/libm.wasm wasm/libstdc++.wasm wasm/libdl.wasm wasm/libanl.wasm wasm/libncurses.wasm wasm/bash.wasm

start-over!:
	rm -rf artifacts daily extracted github/assets github/release github/install install js ship src stamp test wasm wasm32-unknown-none wasm32

clean!: start-over!

clean: clean!

%/:
	$(MKDIR) $@

# the build-or-install generic rule

define do-build =
stamp/wasm32/$(1)/$(2)/install: stamp/wasm32/$(1)/$(2)/build
	touch $$@
endef

define do-download =
stamp/wasm32/$(1)/$(2)/install: stamp/wasm32/$(1)/$(2)/download
	touch $$@
endef

define build-or-install =
stamp/wasm32/$(1)/$(2)/install: stamp/wasm32/$(1)/$(2)/
$(if $(filter all $(2),$(ARTIFACTS)),$(call do-build,$(1),$(2)),$(call do-download,$(1),$(2)))
endef

# environment for bash shells
env:
	@echo "export WASMDIR=$(PWD)"
	@echo "export LANG=C"
	@echo "export JS=\"$(JS)\""

wasm32:
	$(MKDIR) $@

wasm32/native: | wasm32/
	$(MKDIR) $@
	$(MKDIR) $(patsubst %,$@/%,bin include lib libexec share stamp wasm32-unknown-none)
	$(MKDIR) $@/lib

stamp/wasm32/native: | wasm32/native
	$(MKDIR) $@

wasm32/native/build: | wasm32/cross
	$(MKDIR) $@

wasm32/cross: | wasm32 wasm32/native
	$(MKDIR) $@
	$(MKDIR) $(patsubst %,$@/%,bin include lib libexec share stamp wasm32-unknown-none)
	$(LN) ../../native/include $@/wasm32-unknown-none/include
	$(LN) ../../native/lib $@/wasm32-unknown-none/lib

wasm32/cross/bin: | wasm32/cross
	$(MKDIR) $@

wasm32/cross/src: | wasm32/cross
	$(MKDIR) $@

stamp/wasm32/cross: | wasm32/cross
	$(MKDIR) $@

# Binutils/GDB

# binutils-gdb requires source tree modification, so we copy the source.
wasm32/cross/src/binutils-gdb: | wasm32/cross/src
	$(MKDIR) $@T
	cp -as $(PWD)/subrepos/binutils-gdb/* $@T/
	mv $@T $@

stamp/wasm32/cross/binutils-gdb/configure: | wasm32/cross/src/binutils-gdb wasm32/cross/build/binutils-gdb stamp/wasm32/cross/binutils-gdb/
	(cd wasm32/cross/src/binutils-gdb/gas; aclocal)
	(cd wasm32/cross/src/binutils-gdb/gas; automake || true)
	(cd wasm32/cross/src/binutils-gdb/gas; autoreconf2.69 || autoreconf || true)
	(cd wasm32/cross/build/binutils-gdb; ../../src/binutils-gdb/configure --target=wasm32-unknown-none --enable-debug --disable-werror --prefix=$(PWD)/wasm32/cross CFLAGS=$(OPT_NATIVE))
	touch $@

stamp/wasm32/cross/binutils-gdb/build: stamp/wasm32/cross/binutils-gdb/configure | stamp/wasm32/cross/binutils-gdb/
	$(MAKE) -C wasm32/cross/build/binutils-gdb
	$(MAKE) -C wasm32/cross/build/binutils-gdb install
	touch $@

$(eval $(call build-or-install,cross,binutils-gdb))

# GCC (preliminary compilation, C only)

wasm32/cross/src/gcc-preliminary: | wasm32/cross/src
	test -L $@ || $(LN) ../../../subrepos/gcc $@

stamp/wasm32/cross/gcc-preliminary/configure: | stamp/wasm32/cross/binutils-gdb/install wasm32/cross/build/gcc-preliminary wasm32/cross/src/gcc stamp/wasm32/cross/gcc-preliminary/ install/gcc-dependencies
	(cd wasm32/cross/build/gcc-preliminary; CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) ../../src/gcc/configure --enable-optimize=$(OPT_NATIVE) --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --enable-languages=c --disable-libssp --prefix=$(PWD)/wasm32/cross)
	touch $@

stamp/wasm32/cross/gcc-preliminary/build: stamp/wasm32/cross/gcc-preliminary/configure | stamp/wasm32/cross
	PATH=$(PWD)/wasm32/cross/bin:$$PATH CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) $(MAKE) -C wasm32/cross/build/gcc-preliminary
	PATH=$(PWD)/wasm32/cross/bin:$$PATH CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) $(MAKE) -C wasm32/cross/build/gcc-preliminary install
	cp wasm32/cross/lib/gcc/wasm32-unknown-none/12.0.0/libgcc.a wasm32/cross/lib/gcc/wasm32-unknown-none/12.0.0/libgcc_eh.a
	cp wasm32/cross/lib/gcc/wasm32-unknown-none/12.0.0/libgcc.a wasm32/cross/lib/gcc/wasm32-unknown-none/12.0.0/libgcc_s.a
	touch $@

$(eval $(call build-or-install,cross,gcc-preliminary))

# Glibc

wasm32/native/src: | wasm32/native
	$(MKDIR) $@

# These repos do not require source tree modification.
$(patsubst %,wasm32/native/src/%,gcc glibc ncurses bash wabt binaryen python gmp mpc zlib): wasm32/native/src/%: | wasm32/native/src
	test -L $@ || $(LN) ../../../subrepos/$* $@

$(patsubst %,wasm32/cross/src/%,gcc wabt binaryen): wasm32/cross/src/%: | wasm32/cross/src
	test -L $@ || $(LN) ../../../subrepos/$* $@

$(patsubst %,wasm32/cross/build/%,binutils-gdb gcc-preliminary gcc wabt binaryen): wasm32/cross/build/%: | wasm32/cross/src
	$(MKDIR) $@

$(patsubst %,wasm32/native/build/%,binutils-gdb gcc glibc ncurses bash wabt binaryen python gmp mpc zlib): wasm32/native/build/%: | wasm32/native/build
	$(MKDIR) $@

stamp/wasm32/native/glibc/configure: | stamp/wasm32/cross/gcc-preliminary/install wasm32/native/build/glibc wasm32/native/src/glibc stamp/wasm32/native/glibc/
	(cd wasm32/native/build/glibc; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/glibc/configure CFLAGS="-fPIC -O2 -Wno-error=missing-attributes" --enable-optimize=$(OPT_NATIVE) --host=wasm32-unknown-none --target=wasm32-unknown-none --enable-hacker-mode --prefix=$(PWD)/wasm32/native --disable-werror)
	touch $@

stamp/wasm32/native/glibc/build: stamp/wasm32/native/glibc/configure | stamp/wasm32/native/glibc/
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/glibc
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/glibc install
	touch $@

$(eval $(call build-or-install,native,glibc))

ifneq (${GITHUB},1)
wasm32/native/lib/libc.so: stamp/wasm32/native/glibc/
wasm32/native/lib/libm.so: stamp/wasm32/native/glibc/
wasm32/native/lib/ld.so.1: stamp/wasm32/native/glibc/
wasm32/native/lib/libcrypt.so: stamp/wasm32/native/glibc/
wasm32/native/lib/libutil.so: stamp/wasm32/native/glibc/
wasm32/native/lib/libdl.so: stamp/wasm32/native/glibc/
wasm32/native/lib/libanl.so: stamp/wasm32/native/glibc/
endif

# GCC (final build, C/C++/LTO, no libgccjit)

stamp/wasm32/cross/gcc/configure: | stamp/wasm32/native/glibc/build stamp/wasm32/cross/gcc-preliminary/install wasm32/cross/build/gcc wasm32/cross/src/gcc stamp/wasm32/cross/gcc/ install/gcc-dependencies
	(cd wasm32/cross/build/gcc; ../../src/gcc/configure CFLAGS="-O2" CXXFLAGS="-O2" --target=wasm32-unknown-none --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --disable-libssp --prefix=$(PWD)/wasm32/cross --enable-optimize="-O2" --enable-shared --enable-symvers=gnu)
	touch $@

stamp/wasm32/cross/gcc/build: stamp/wasm32/cross/gcc/configure | stamp/wasm32/cross/gcc/ wasm32/cross/src/gcc
	$(MKDIR) wasm32/cross/build/gcc/gcc
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/cross/build/gcc
	cp wasm32/cross/build/gcc/gcc/libgcc.a wasm32/cross/build/gcc/gcc/libgcc_eh.a
	cp wasm32/cross/build/gcc/gcc/libgcc.a wasm32/cross/build/gcc/gcc/libgcc_s.a
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/cross/build/gcc install
	touch $@

$(eval $(call build-or-install,cross,gcc))

wasm32/cross/lib/libstdc++.so: stamp/wasm32/cross/glibc/install

# ncurses

stamp/wasm32/native/ncurses/configure: | stamp/wasm32/cross/gcc/install wasm32/native/src/ncurses wasm32/native/build/ncurses stamp/wasm32/native/ncurses/
	(cd wasm32/native/build/ncurses; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/ncurses/configure MAKE_TERMINFO=1 --enable-optimize=$(OPT_WASM) --build=$(native-triplet) --host=wasm32-unknown-none --prefix=$(PWD)/wasm32/native --disable-stripping --with-shared --without-cxx-binding)
	touch $@

stamp/wasm32/native/ncurses/build: stamp/wasm32/native/ncurses/configure | stamp/wasm32/native/ncurses/
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/ncurses
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/ncurses install
	touch $@

$(eval $(call build-or-install,native,ncurses))

wasm32/native/lib/libncurses.so: stamp/wasm32/native/ncurses/install

# bash

stamp/wasm32/native/bash/configure: | stamp/wasm32/native/ncurses/install wasm32/native/src/bash wasm32/native/build/bash stamp/wasm32/native/bash/
	(cd wasm32/native/build/bash; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/bash/configure --build=$(native-triplet) --host=wasm32-unknown-none --prefix=$(PWD)/wasm32/native --without-bash-malloc)
	touch $@

stamp/wasm32/native/bash/build: stamp/wasm32/native/bash/configure | stamp/wasm32/native/bash/
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/bash
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/bash install
	touch $@

$(eval $(call build-or-install,native,bash))

wasm32/native/bin/bash: stamp/wasm32/native/bash/install

# zsh

# Zsh is spe-shell.
wasm32/native/build/zsh: | wasm32/native/build
	$(MKDIR) $@T
	cp -as $(PWD)/subrepos/zsh/* $@T/
	mv $@T $@

stamp/wasm32/native/zsh/configure: | stamp/wasm32/native/ncurses/build wasm32/native/build/zsh stamp/wasm32/native/zsh/
	(cd wasm32/native/build/zsh; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH autoreconf -vif; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ./configure --build=$(native-triplet) --host=wasm32-unknown-none --prefix=$(PWD)/wasm32/native)
	touch $@

stamp/wasm32/native/zsh/build: stamp/wasm32/native/zsh/configure | stamp/wasm32/native/zsh/
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/zsh
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/zsh install
	touch $@

$(eval $(call build-or-install,native,zsh))

wasm32/native/bin/zsh: stamp/wasm32/native/zsh/install

# coreutils

# Coreutils requires its own destructive bootstrap script
wasm32/native/build/coreutils: | wasm32/native/build
	$(MKDIR) $@T
	cp -as $(PWD)/subrepos/coreutils/* $@T/
	mv $@T $@

stamp/wasm32/native/coreutils/configure: | stamp/wasm32/native/ncurses/build wasm32/native/build/coreutils stamp/wasm32/native/coreutils/ wasm32/cross/lib/js/wasm32.js
	(cd wasm32/native/build/coreutils; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ./bootstrap --skip-po --no-git --gnulib-srcdir=$(PWD)/wasm32/native/build/coreutils/gnulib; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ./configure  --build=$(native-triplet) --host=wasm32-unknown-none --prefix=$(PWD)/wasm32/native)
	touch $@

stamp/wasm32/native/coreutils/build: stamp/wasm32/native/coreutils/configure | stamp/wasm32/native/coreutils/
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) --trace -C wasm32/native/build/coreutils
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) --trace -C wasm32/native/build/coreutils install
	touch $@

$(eval $(call build-or-install,native,coreutils))

wasm32/native/bin/true wasm32/native/bin/false wasm32/native/bin/echo: stamp/wasm32/native/coreutils/install

# Python

stamp/wasm32/native/python/configure: | stamp/wasm32/cross/gcc/install wasm32/native/src/python wasm32/native/build/python stamp/wasm32/native/python/
	(cd wasm32/native/build/python; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/python/configure --build=$(native-triplet) --host=wasm32-unknown-none --prefix=$(PWD)/wasm32/native --disable-ipv6 --with-ensurepip=no)
	touch $@

stamp/wasm32/native/python/build: stamp/wasm32/native/python/configure | stamp/wasm32/native/python/
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/python
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/python install
	touch $@

$(eval $(call build-or-install,native,python))

ifneq (${GITHUB},1)
wasm32/native/bin/python3: stamp/wasm32/native/python/build
endif

# Perl

wasm32/native/src/perl: | subrepos/perl wasm32/native/src
	$(LN) ../../../subrepos/perl $@

wasm32/native/build/perl: | wasm32/native/src/perl wasm/libcrypt.wasm wasm/libutil.wasm wasm32/native/build
	$(MKDIR) $@T
	cp -as $(PWD)/subrepos/perl/* $(addprefix $(PWD)/subrepos/perl/.,dir-locals.el editorconfig lgtm.yml metaconf-exclusions.txt travis.yml) $@T/
	mv $@T $@

stamp/wasm32/native/perl/configure: | wasm32/native/build/perl stamp/wasm32/cross/gcc/build wasm/libc.wasm wasm/libcrypt.wasm wasm/ld.wasm wasm/libutil.wasm wasm/libanl.wasm wasm/libdl.wasm wasm/libm.wasm wasm32/cross/bin/dotdir stamp/wasm32/native/perl/
	test -f wasm32/native/build/perl/config.sh && mv wasm32/native/build/perl/config.sh wasm32/native/build/perl/config.sh.old || true
	touch wasm32/native/build/perl/config.sh
	find wasm32/native/build/perl -type d | while read REPLY; do (cd $$REPLY; $(PWD)/wasm32/cross/bin/dotdir > .dir); done
	(cd wasm32/native/build/perl; PATH=$(PWD)/wasm32/cross/bin:$$PATH sh ./Configure -der -Uversiononly -Uusemymalloc -Dar=wasm32-unknown-none-ar -Dcc=wasm32-unknown-none-gcc -Doptimize="-O3 -fno-strict-aliasing" -Dincpth='' -Dcccdlflags='-fPIC -Wl,--shared -shared' -Dlddlflags='-Wl,--shared -shared' -Dccdlflags='-Wl,-E'  -Dloclibpth=' ' -Dglibpth=' ' -Dplibpth=' ' -Dusedl -Dlibs='-ldl -lm -lcrypt -lutil' -Dd_u32align=define -Dusedevel -Darchname='wasm32' -Dprefix='$(PWD)/wasm32/native')
	touch $@

stamp/wasm32/native/miniperl/build: stamp/wasm32/native/perl/configure | install/binfmt_misc/elf32-wasm32 stamp/wasm32/native/miniperl/
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/perl miniperl
	cp wasm32/native/build/perl/miniperl wasm32/native/bin/miniperl
	touch $@

$(eval $(call build-or-install,native,miniperl))

wasm32/native/bin/miniperl: stamp/wasm32/native/miniperl/install

stamp/wasm32/native/perl/build: stamp/wasm32/native/miniperl/build stamp/wasm32/native/perl/configure | install/binfmt_misc/elf32-wasm32 wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/dotdir stamp/wasm32/native/perl/
	find wasm32/native/build/perl -type d | while read REPLY; do (cd $$REPLY; $(PWD)/wasm32/cross/bin/dotdir > .dir); done
	PERL_CORE=1 PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/perl < /dev/null
	PERL_CORE=1 PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/perl install < /dev/null
	touch $@

$(eval $(call build-or-install,native,perl))

wasm32/native/bin/perl: stamp/wasm32/native/perl/install

# zlib

stamp/wasm32/native/zlib/configure: | wasm32/native/build/zlib wasm32/native/src/zlib stamp/wasm32/cross/gcc/build stamp/wasm32/native/zlib/
	(cd wasm32/native/build/zlib; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/zlib/configure --prefix=$(PWD)/wasm32/native)
	touch $@

stamp/wasm32/native/zlib/build: stamp/wasm32/native/zlib/configure | stamp/wasm32/native/zlib/
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/zlib
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/zlib install
	touch $@

$(eval $(call build-or-install,native,zlib))

wasm32/native/lib/libz.so: stamp/wasm32/native/zlib/install

# GMP

stamp/wasm32/native/gmp/configure: | wasm32/native/build/gmp wasm32/native/src/gmp stamp/wasm32/cross/gcc/build stamp/wasm32/native/gmp/
	(cd wasm32/native/build/gmp; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/gmp/configure --host=wasm32-unknown-none --build=$(native-triplet) --prefix=$(PWD)/wasm32/native)
	touch $@

stamp/wasm32/native/gmp/build: stamp/wasm32/native/gmp/configure | stamp/wasm32/native stamp/wasm32/native/gmp/
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/gmp
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/gmp install
	touch $@

$(eval $(call build-or-install,native,gmp))

# MPC

stamp/wasm32/native/mpc/configure: | wasm32/native/src/mpc wasm32/native/build/mpc stamp/wasm32/cross/gcc/build stamp/wasm32/native/mpc/ stamp/wasm32/native/mpfr/install stamp/wasm32/native/gmp/install
	(cd wasm32/native/build/mpc; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/mpc/configure --host=wasm32-unknown-none --build=$(native-triplet) --prefix=$(PWD)/wasm32/native)
	touch $@

stamp/wasm32/native/mpc/build: stamp/wasm32/native/mpc/configure | stamp/wasm32/native/mpc/
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/mpc
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/mpc install
	touch $@

$(eval $(call build-or-install,native,mpc))

# MPFR

wasm32/native/src/mpfr: | wasm32/native/src
	$(MKDIR) $@T
	cp -as $(PWD)/subrepos/mpfr/* $@T/
	mv $@T $@

wasm32/native/build/mpfr: | wasm32/native/build
	$(MKDIR) $@

stamp/wasm32/native/mpfr/configure: | wasm32/native/src/mpfr wasm32/native/build/mpfr stamp/wasm32/cross/gcc/build stamp/wasm32/native/mpfr/
	(cd wasm32/native/src/mpfr; libtoolize && sh autogen.sh)
	(cd wasm32/native/build/mpfr; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/mpfr/configure --host=wasm32-unknown-none --build=$(native-triplet) --prefix=$(PWD)/wasm32/native)
	touch $@

stamp/wasm32/native/mpfr/build: stamp/wasm32/native/mpfr/configure | stamp/wasm32/native/mpfr/
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/mpfr
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/mpfr install
	touch $@

$(eval $(call build-or-install,native,mpfr))

# Binutils (native)

wasm32/native/src/binutils-gdb: | wasm32/cross/src
	$(MKDIR) $@T
	cp -as $(PWD)/subrepos/binutils-gdb/* $@T/
	mv $@T $@

stamp/wasm32/native/binutils-gdb/configure: | wasm32/native/src/binutils-gdb wasm32/native/build/binutils-gdb stamp/wasm32/native/binutils-gdb/
	(cd wasm32/native/src/binutils-gdb/gas; aclocal; automake; autoreconf)
	(cd wasm32/native/build/binutils-gdb; PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/binutils-gdb/configure --build=$(native-triplet) --target=wasm32-unknown-none --host=wasm32-unknown-none --enable-debug --prefix=$(PWD)/wasm32/native CFLAGS=$(OPT_WASM) --disable-werror)
	touch $@

stamp/wasm32/native/binutils-gdb/build: stamp/wasm32/native/binutils-gdb/configure | stamp/wasm32/native/binutils-gdb/
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/binutils-gdb
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/binutils-gdb install
	touch $@

$(eval $(call build-or-install,native,binutils-gdb))

# GCC (native)

stamp/wasm32/native/gcc/configure: | stamp/wasm32/native/glibc/build stamp/wasm32/cross/gcc/build wasm32/native/build/gcc wasm32/native/src/gcc stamp/wasm32/native/gcc/ stamp/wasm32/native/gmp/install stamp/wasm32/native/mpc/install stamp/wasm32/native/mpfr/install
	(cd wasm32/native/build/gcc; PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/gcc/configure CFLAGS="-Os" CXXFLAGS="-Os" --enable-languages=c,c++,fortran,lto,jit --enable-host-shared --host=wasm32-unknown-none --build=$(native-triplet) --target=wasm32-unknown-none --disable-libffi --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --disable-libssp --prefix=$(PWD)/wasm32/native)
	touch $@

stamp/wasm32/native/gcc/build: stamp/wasm32/native/gcc/configure | stamp/wasm32/native/gcc/ wasm32/native/src/gcc
	$(MKDIR) wasm32/native/build/gcc/gcc
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/gcc
	cp wasm32/native/build/gcc/gcc/libgcc.a wasm32/native/build/gcc/gcc/libgcc_eh.a
	cp wasm32/native/build/gcc/gcc/libgcc.a wasm32/native/build/gcc/gcc/libgcc_s.a
	PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/gcc install
	touch $@

$(eval $(call build-or-install,native,gcc))

wasm32/native/lib/libgccjit.so: stamp/wasm32/native/gcc/install

# Emacs

wasm32/cross/build/emacs/: | wasm32/cross/build
	$(MKDIR) $@T
	cp -as $(PWD)/subrepos/emacs/* $@T/
	mv $@T $@

stamp/wasm32/cross/emacs/configure: | wasm32/cross/emacs/ stamp/wasm32/cross/emacs/
	(cd wasm32/native/build/emacs; sh autogen.sh; ./configure --build=$(native-triplet) --host=$(native-triplet) --prefix=$(PWD)/wasm32/cross --without-x --without-gnutls --without-modules --without-threads --without-x --without-libgmp --without-json --without-xft --without-all)
	touch $@

stamp/wasm32/cross/emacs/build: stamp/wasm32/cross/emacs/configure
	$(MAKE) -C wasm32/cross/build/emacs
	(cd wasm32/cross/build/emacs; tar cvf elc.tar $$(find lisp/leim/quail -name '*.el') lisp/leim/ja-dic/ja-dic.el lisp/cedet/semantic/bovine/make-by.el lisp/cedet/semantic/wisent/python-wy.el $$(find -name '*.elc'))
	touch $@

# Emacs is _built_ in the source directory, so copy that.
stamp/wasm32/native/emacs/copy: | stamp/wasm32/native/emacs/
	$(MKDIR) wasm32/native/build/emacsT
	cp -as $(PWD)/subrepos/emacs/* wasm32/native/build/emacsT/
	mv wasm32/native/build/emacsT wasm32/native/build/emacs
	test -e wasm32/cross/build/emacs/elc.tar && (cd wasm32/native/build/emacs; tar xv) < wasm32/cross/build/emacs/elc.tar || true

stamp/wasm32/native/emacs/configure: stamp/wasm32/native/emacs/copy | wasm32/cross/bin/dotdir stamp/wasm32/native/emacs/
	(cd wasm32/native/build/emacs; sh autogen.sh; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ./configure --with-dumping=none --build=$(native-triplet) --host=wasm32-unknown-none --prefix=$(PWD)/wasm32/native --without-x --without-gnutls --without-modules --without-threads --without-x --without-libgmp --without-json --without-xft --without-all)
	find wasm32/native/build/emacs -type d | while read REPLY; do (cd $$REPLY; $(PWD)/wasm32/cross/bin/dotdir > .dir); done
	touch $@

stamp/wasm32/native/emacs/build: stamp/wasm32/native/emacs/configure | stamp/wasm32/native/ncurses/build stamp/wasm32/native/emacs/
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/emacs
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH $(MAKE) -C wasm32/native/build/emacs install
	touch $@

wasm32/native/bin/emacs: stamp/wasm32/native/emacs/build
wasm32/native/bin/temacs: stamp/wasm32/native/emacs/build

# Needs runtime
stamp/wasm32/native/emacs/build: wasm/ld.wasm wasm/libc.wasm wasm/libncurses.wasm

# Temporary rule
%.eln.wasm: %.eln
	wasm32/cross/bin/elf-to-wasm --library --dynamic $< > $@

# wabt

stamp/wasm32/cross/wabt/configure: | wasm32/cross/build/wabt wasm32/cross/src/wabt stamp/wasm32/cross/wabt/
	(cd wasm32/cross/build/wabt; cmake ../../src/wabt -DBUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$(PWD)/wasm32/cross -DCMAKE_BUILD_TYPE=Debug)
	touch $@

stamp/wasm32/cross/wabt/build: stamp/wasm32/cross/wabt/configure | stamp/wasm32/cross
	$(MAKE) -C wasm32/cross/build/wabt
	$(MAKE) -C wasm32/cross/build/wabt install
	touch $@

# Binaryen

stamp/wasm32/cross/binaryen/configure: | wasm32/cross/build/binaryen wasm32/cross/src/binaryen stamp/wasm32/cross/binaryen/
	(cd wasm32/cross/build/binaryen; cmake ../../src/binaryen -DCMAKE_INSTALL_PREFIX=$(PWD)/wasm32/cross -DCMAKE_BUILD_TYPE=Debug)
	touch $@

stamp/wasm32/cross/binaryen/build: stamp/wasm32/cross/binaryen/configure | stamp/wasm32/cross
	$(MAKE) -C wasm32/cross/build/binaryen
	$(MAKE) -C wasm32/cross/build/binaryen install
	touch $@

########################################

wasm32/cross/test/binutils-gdb: | wasm32/cross/test/
	$(MKDIR) $@

wasm32/native/test/bash: | wasm32/native/test/
	$(MKDIR) $@

wasm32/native/test/glibc: | wasm32/native/test/
	$(MKDIR) $@

# Copying wasm32-headers.o is unfortunate, but required by our linker script.
wasm32/cross/test/binutils-gdb/summary: stamp/wasm32/cross/binutils-gdb/build | stamp/wasm32/cross/gcc-preliminary/build wasm32/cross/test/binutils-gdb
	cp wasm32/cross/lib/gcc/wasm32-unknown-none/11.0.1/wasm32-headers.o wasm32/cross/build/binutils-gdb/ld/
	(cd wasm32/cross/build/binutils-gdb; $(MAKE) check)
	cat $(patsubst %,wasm32/cross/build/binutils-gdb/%,binutils/binutils.sum gas/testsuite/gas.sum libctf/libctf.sum ld/ld.sum sim/testsuite/testrun.sum) > $@

wasm32/cross/test/gcc-preliminary/summary: stamp/wasm32/cross/gcc-preliminary/build | | wasm32/cross/test/gcc-preliminary
	(cd wasm32/cross/build/gcc-preliminary; $(MAKE) check)

wasm32/native/test/glibc/summary: stamp/wasm32/native/glibc/build | wasm32/native/test/glibc
	(cd wasm32/native/build/glibc; $(MAKE) check)










wasm32/native/test/bash/summary: stamp/wasm32/native/bash | wasm32/native/test/bash
	(cd wasm32/native/build/bash; $(MAKE) check)

wasm32/cross/test/gcc/site.exp: | wasm32/cross/test/gcc/tmp/
	$(MKDIR) $(dir $@)
	> $@
	echo 'set rootme "$(PWD)/wasm32/cross/test/gcc"' >> $@
	echo 'set srcdir "$(PWD)/wasm32/cross/src/gcc/gcc"' >> $@
	echo 'set host_triplet $(native-triplet)' >> $@
	echo 'set build_triplet $(native-triplet)' >> $@
	echo 'set target_triplet wasm32-unknown-none' >> $@
	echo 'set target_alias wasm32-unknown-none' >> $@
	echo 'set libiconv ""' >> $@
	echo 'set CFLAGS ""' >> $@
	echo 'set CXXFLAGS ""' >> $@
	echo 'set HOSTCC "gcc"' >> $@
	echo 'set HOSTCXX "g++"' >> $@
	echo 'set HOSTCFLAGS "-g "' >> $@
	echo 'set HOSTCXXFLAGS "-g  "' >> $@
	echo 'set TEST_ALWAYS_FLAGS ""' >> $@
	echo 'set TEST_GCC_EXEC_PREFIX "$(PWD)/wasm32/cross/lib/gcc/"' >> $@
	echo 'set TESTING_IN_BUILD_TREE 0' >> $@
	echo 'set HAVE_LIBSTDCXX_V3 1' >> $@
	echo 'set ENABLE_PLUGIN 1' >> $@
	echo 'set PLUGINCC "g++"' >> $@
	echo 'set PLUGINCFLAGS "-g  "' >> $@
	echo 'set GMPINC ""' >> $@
	echo 'set tmpdir $(PWD)/wasm32/cross/test/gcc/tmp' >> $@
	echo 'set srcdir "$${srcdir}/testsuite"' >> $@

wasm32/cross/test/gcc/make/%.{dejagnu}.mk: | wasm32/cross/test/gcc/site.exp
	$(MKDIR) $(dir $@)
	> $@
	for file in $$(cd wasm32/cross/src/gcc/gcc/testsuite/$(dir $*); find -type f | egrep '\.([cSi])$$' | sed -e 's/^\.\///g'); do \
	    echo "wasm32/cross/test/gcc/results/$(dir $*)$$file.{dejagnu}/okay:" >> $@; \
	    echo "\t(mkdir -p wasm32/cross/test/gcc/results/$(dir $*)$$file.{dejagnu}/; cp wasm32/cross/src/gcc/gcc/testsuite/$(dir $*)$$file wasm32/cross/test/gcc/results/$(dir $*)$$file.{dejagnu}/; cd wasm32/cross/test/gcc/results; testtotest=../../../../../subrepos/gcc/gcc/testsuite/$(dir $*)$$file PATH=$(PWD)/wasm32/cross/bin:$$PATH runtest --outdir $(dir $*)$$file.{dejagnu}/ --tool gcc $* > /dev/null 2> /dev/null) || true" >> $@; \
	    echo "\t! egrep -q '^# of unexpected|RuntimeError' wasm32/cross/test/gcc/results/$(dir $*)$$file.{dejagnu}/gcc.log && touch wasm32/cross/test/gcc/results/$(dir $*)$$file.{dejagnu}/okay || (echo wasm32/cross/test/gcc/results/testsuite/$(dir $*)$$file; false)" >> $@; \
	    echo >> $@; \
	    all="$$all wasm32/cross/test/gcc/results/$(dir $*)$$file.{dejagnu}/okay"; \
	done; \
        echo "wasm32/gcc-testsuite/$*.all: $$all" >> $@

wasm32/cross/test/gcc/results/gcc.c-torture/compile/%: wasm32/cross/test/gcc/make/gcc.c-torture/compile/compile.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)/gcc.log > /dev/stderr; false)

wasm32/cross/test/gcc/results/gcc.c-torture/execute/%: wasm32/cross/test/gcc/make/gcc.c-torture/execute/execute.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)/gcc.log > /dev/stderr; false)

wasm32/cross/test/gcc/results/gcc.c-torture/execute/ieee/%: wasm32/cross/test/gcc/make/gcc.c-torture/execute/ieee/ieee.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)/gcc.log > /dev/stderr; false)

wasm32/cross/test/gcc/results/gcc.dg/%: wasm32/cross/test/gcc/make/gcc.dg/dg.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)/gcc.log > /dev/stderr; false)

wasm32/cross/test/gcc/results/gcc.dg/debug/dwarf2/%: wasm32/cross/test/gcc/make/gcc.dg/debug/dwarf2/dwarf2.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)/gcc.log > /dev/stderr; false)

wasm32/cross/test/gcc/results/gcc.dg/tls/%: wasm32/cross/test/gcc/make/gcc.dg/tls/tls.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)/gcc.log > /dev/stderr; false)

GCC_PROBLEM_TESTS = \
	gcc.c-torture/compile/20080625-1.c \
	gcc.c-torture/execute/920428-2.c \
	gcc.c-torture/execute/920501-7.c \
	gcc.c-torture/execute/comp-goto-2.c \
	gcc.c-torture/execute/ieee/copysign2.c \
	gcc.c-torture/execute/ieee/copysign2.c \
	gcc.c-torture/execute/nestfunc-5.c \
	gcc.c-torture/execute/nestfunc-6.c \
	gcc.dg/Warray-bounds-56.c \
	gcc.dg/Warray-bounds-68.c \
	gcc.dg/Wstringop-overflow-11.c \
	gcc.dg/Wstringop-overflow-25.c \
	gcc.dg/Wstringop-overflow-28.c \
	gcc.dg/Wstringop-overflow-37.c \
	gcc.dg/Wstringop-overflow-43.c \
	gcc.dg/array-quals-1.c \
	gcc.dg/atomic-lockfree.c \
	gcc.dg/attr-alwaysinline.c \
	gcc.dg/attr-externally-visible-1.c \
	gcc.dg/attr-nonstring-2.c \
	gcc.dg/attr-nonstring-3.c \
	gcc.dg/attr-nonstring-4.c \
	gcc.dg/builtins-1.c \
	gcc.dg/builtins-12.c \
	gcc.dg/builtins-16.c \
	gcc.dg/builtins-61.c \
	gcc.dg/builtins-68.c \
	gcc.dg/builtins-85.c \
	gcc.dg/c99-predef-1.c \
	gcc.dg/c99-stdint-5.c \
	gcc.dg/c99-stdint-6.c \
	gcc.dg/cdce1.c \
	gcc.dg/cdce2.c \
	gcc.dg/cdce3.c \
	gcc.dg/cleanup-6.c \
	gcc.dg/debug/dwarf2/align-1.c \
	gcc.dg/debug/dwarf2/align-2.c \
	gcc.dg/debug/dwarf2/align-3.c \
	gcc.dg/debug/dwarf2/align-4.c \
	gcc.dg/debug/dwarf2/align-5.c \
	gcc.dg/debug/dwarf2/align-6.c \
	gcc.dg/debug/dwarf2/align-as-1.c \
	gcc.dg/debug/dwarf2/aranges-fnsec-1.c \
	gcc.dg/debug/dwarf2/array-0.c \
	gcc.dg/debug/dwarf2/array-1.c \
	gcc.dg/debug/dwarf2/array-2.c \
	gcc.dg/debug/dwarf2/array-3.c \
	gcc.dg/debug/dwarf2/asm-line1.c \
	gcc.dg/debug/dwarf2/atomic.c \
	gcc.dg/debug/dwarf2/c99-typedef1.c \
	gcc.dg/debug/dwarf2/const-2.c \
	gcc.dg/debug/dwarf2/const-2b.c \
	gcc.dg/debug/dwarf2/discriminator.c \
	gcc.dg/debug/dwarf2/dwarf-char1.c \
	gcc.dg/debug/dwarf2/dwarf-char2.c \
	gcc.dg/debug/dwarf2/dwarf-char3.c \
	gcc.dg/debug/dwarf2/dwarf-dfp.c \
	gcc.dg/debug/dwarf2/dwarf-die1.c \
	gcc.dg/debug/dwarf2/dwarf-die2.c \
	gcc.dg/debug/dwarf2/dwarf-die3.c \
	gcc.dg/debug/dwarf2/dwarf-die5.c \
	gcc.dg/debug/dwarf2/dwarf-die5.c \
	gcc.dg/debug/dwarf2/dwarf-die6.c \
	gcc.dg/debug/dwarf2/dwarf-die6.c \
	gcc.dg/debug/dwarf2/dwarf-die7.c \
	gcc.dg/debug/dwarf2/dwarf-die7.c \
	gcc.dg/debug/dwarf2/dwarf-file1.c \
	gcc.dg/debug/dwarf2/dwarf-file1.c \
	gcc.dg/debug/dwarf2/dwarf-float.c \
	gcc.dg/debug/dwarf2/dwarf-float.c \
	gcc.dg/debug/dwarf2/dwarf-merge.c \
	gcc.dg/debug/dwarf2/dwarf-merge.c \
	gcc.dg/debug/dwarf2/dwarf-uninit.c \
	gcc.dg/debug/dwarf2/dwarf-uninit.c \
	gcc.dg/debug/dwarf2/dwarf2-3.c \
	gcc.dg/debug/dwarf2/dwarf2-3.c \
	gcc.dg/debug/dwarf2/dwarf2-macro.c \
	gcc.dg/debug/dwarf2/dwarf2-macro.c \
	gcc.dg/debug/dwarf2/dwarf2-macro2.c \
	gcc.dg/debug/dwarf2/dwarf2-macro2.c \
	gcc.dg/debug/dwarf2/enum-loc1.c \
	gcc.dg/debug/dwarf2/enum-loc1.c \
	gcc.dg/debug/dwarf2/fesd-any.c \
	gcc.dg/debug/dwarf2/fesd-any.c \
	gcc.dg/debug/dwarf2/fesd-baseonly.c \
	gcc.dg/debug/dwarf2/fesd-baseonly.c \
	gcc.dg/debug/dwarf2/fesd-none.c \
	gcc.dg/debug/dwarf2/fesd-none.c \
	gcc.dg/debug/dwarf2/fesd-reduced.c \
	gcc.dg/debug/dwarf2/fesd-reduced.c \
	gcc.dg/debug/dwarf2/fesd-sys.c \
	gcc.dg/debug/dwarf2/fesd-sys.c \
	gcc.dg/debug/dwarf2/global-used-types.c \
	gcc.dg/debug/dwarf2/global-used-types.c \
	gcc.dg/debug/dwarf2/inline1.c \
	gcc.dg/debug/dwarf2/inline1.c \
	gcc.dg/debug/dwarf2/inline2.c \
	gcc.dg/debug/dwarf2/inline2.c \
	gcc.dg/debug/dwarf2/inline3.c \
	gcc.dg/debug/dwarf2/inline3.c \
	gcc.dg/debug/dwarf2/inline4.c \
	gcc.dg/debug/dwarf2/inline4.c \
	gcc.dg/debug/dwarf2/inline5.c \
	gcc.dg/debug/dwarf2/inline5.c \
	gcc.dg/debug/dwarf2/inline6.c \
	gcc.dg/debug/dwarf2/inline6.c \
	gcc.dg/debug/dwarf2/ipa-cp1.c \
	gcc.dg/debug/dwarf2/ipa-cp1.c \
	gcc.dg/debug/dwarf2/lang-c11-d4-strict.c \
	gcc.dg/debug/dwarf2/lang-c11-d4-strict.c \
	gcc.dg/debug/dwarf2/lang-c11.c \
	gcc.dg/debug/dwarf2/lang-c11.c \
	gcc.dg/debug/dwarf2/lang-c89.c \
	gcc.dg/debug/dwarf2/lang-c89.c \
	gcc.dg/debug/dwarf2/lang-c99.c \
	gcc.dg/debug/dwarf2/lang-c99.c \
	gcc.dg/debug/dwarf2/nested_fun.c \
	gcc.dg/debug/dwarf2/nested_fun.c \
	gcc.dg/debug/dwarf2/noreturn-function-attribute.c \
	gcc.dg/debug/dwarf2/noreturn-function-attribute.c \
	gcc.dg/debug/dwarf2/noreturn-function-keyword.c \
	gcc.dg/debug/dwarf2/noreturn-function-keyword.c \
	gcc.dg/debug/dwarf2/omp-fesdr.c \
	gcc.dg/debug/dwarf2/omp-fesdr.c \
	gcc.dg/debug/dwarf2/pr29609-1.c \
	gcc.dg/debug/dwarf2/pr29609-1.c \
	gcc.dg/debug/dwarf2/pr29609-2.c \
	gcc.dg/debug/dwarf2/pr29609-2.c \
	gcc.dg/debug/dwarf2/pr31230.c \
	gcc.dg/debug/dwarf2/pr31230.c \
	gcc.dg/debug/dwarf2/pr36690-1.c \
	gcc.dg/debug/dwarf2/pr36690-1.c \
	gcc.dg/debug/dwarf2/pr36690-2.c \
	gcc.dg/debug/dwarf2/pr36690-2.c \
	gcc.dg/debug/dwarf2/pr36690-3.c \
	gcc.dg/debug/dwarf2/pr36690-3.c \
	gcc.dg/debug/dwarf2/pr37616.c \
	gcc.dg/debug/dwarf2/pr37616.c \
	gcc.dg/debug/dwarf2/pr41445-1.c \
	gcc.dg/debug/dwarf2/pr41445-1.c \
	gcc.dg/debug/dwarf2/pr41445-2.c \
	gcc.dg/debug/dwarf2/pr41445-2.c \
	gcc.dg/debug/dwarf2/pr41445-3.c \
	gcc.dg/debug/dwarf2/pr41445-3.c \
	gcc.dg/debug/dwarf2/pr41445-4.c \
	gcc.dg/debug/dwarf2/pr41445-4.c \
	gcc.dg/debug/dwarf2/pr41445-5.c \
	gcc.dg/debug/dwarf2/pr41445-5.c \
	gcc.dg/debug/dwarf2/pr41445-6.c \
	gcc.dg/debug/dwarf2/pr41445-6.c \
	gcc.dg/debug/dwarf2/pr41445-7.c \
	gcc.dg/debug/dwarf2/pr41445-7.c \
	gcc.dg/debug/dwarf2/pr41445-8.c \
	gcc.dg/debug/dwarf2/pr41445-8.c \
	gcc.dg/debug/dwarf2/pr41543.c \
	gcc.dg/debug/dwarf2/pr41543.c \
	gcc.dg/debug/dwarf2/pr41695.c \
	gcc.dg/debug/dwarf2/pr41695.c \
	gcc.dg/debug/dwarf2/pr43237.c \
	gcc.dg/debug/dwarf2/pr43237.c \
	gcc.dg/debug/dwarf2/pr47939-1.c \
	gcc.dg/debug/dwarf2/pr47939-1.c \
	gcc.dg/debug/dwarf2/pr47939-2.c \
	gcc.dg/debug/dwarf2/pr47939-2.c \
	gcc.dg/debug/dwarf2/pr47939-3.c \
	gcc.dg/debug/dwarf2/pr47939-3.c \
	gcc.dg/debug/dwarf2/pr47939-4.c \
	gcc.dg/debug/dwarf2/pr47939-4.c \
	gcc.dg/debug/dwarf2/pr49871.c \
	gcc.dg/debug/dwarf2/pr49871.c \
	gcc.dg/debug/dwarf2/pr51410.c \
	gcc.dg/debug/dwarf2/pr51410.c \
	gcc.dg/debug/dwarf2/pr53948.c \
	gcc.dg/debug/dwarf2/pr53948.c \
	gcc.dg/debug/dwarf2/pr66482.c \
	gcc.dg/debug/dwarf2/pr66482.c \
	gcc.dg/debug/dwarf2/pr71855.c \
	gcc.dg/debug/dwarf2/pr71855.c \
	gcc.dg/debug/dwarf2/pr80263.c \
	gcc.dg/debug/dwarf2/pr80263.c \
	gcc.dg/debug/dwarf2/pr82718-1.c \
	gcc.dg/debug/dwarf2/pr82718-1.c \
	gcc.dg/debug/dwarf2/pr82718-2.c \
	gcc.dg/debug/dwarf2/pr82718-2.c \
	gcc.dg/debug/dwarf2/pr82837.c \
	gcc.dg/debug/dwarf2/pr82837.c \
	gcc.dg/debug/dwarf2/pr86964.c \
	gcc.dg/debug/dwarf2/pr86964.c \
	gcc.dg/debug/dwarf2/pr88635.c \
	gcc.dg/debug/dwarf2/pr88635.c \
	gcc.dg/debug/dwarf2/pr88644.c \
	gcc.dg/debug/dwarf2/pr88644.c \
	gcc.dg/debug/dwarf2/pr93751-1.c \
	gcc.dg/debug/dwarf2/pr93751-1.c \
	gcc.dg/debug/dwarf2/pr93751-2.c \
	gcc.dg/debug/dwarf2/pr93751-2.c \
	gcc.dg/debug/dwarf2/pr96383-1.c \
	gcc.dg/debug/dwarf2/pr96383-1.c \
	gcc.dg/debug/dwarf2/pr96383-2.c \
	gcc.dg/debug/dwarf2/pr96383-2.c \
	gcc.dg/debug/dwarf2/pr97060.c \
	gcc.dg/debug/dwarf2/pr97060.c \
	gcc.dg/debug/dwarf2/prod-options.c \
	gcc.dg/debug/dwarf2/prod-options.c \
	gcc.dg/debug/dwarf2/short-circuit.c \
	gcc.dg/debug/dwarf2/short-circuit.c \
	gcc.dg/debug/dwarf2/sso-1.c \
	gcc.dg/debug/dwarf2/sso-1.c \
	gcc.dg/debug/dwarf2/sso-2.c \
	gcc.dg/debug/dwarf2/sso-2.c \
	gcc.dg/debug/dwarf2/sso-3.c \
	gcc.dg/debug/dwarf2/sso-3.c \
	gcc.dg/debug/dwarf2/stacked-qualified-types-1.c \
	gcc.dg/debug/dwarf2/stacked-qualified-types-1.c \
	gcc.dg/debug/dwarf2/stacked-qualified-types-2.c \
	gcc.dg/debug/dwarf2/stacked-qualified-types-2.c \
	gcc.dg/debug/dwarf2/stacked-qualified-types-3.c \
	gcc.dg/debug/dwarf2/stacked-qualified-types-3.c \
	gcc.dg/debug/dwarf2/static1.c \
	gcc.dg/debug/dwarf2/static1.c \
	gcc.dg/debug/dwarf2/struct-loc1.c \
	gcc.dg/debug/dwarf2/struct-loc1.c \
	gcc.dg/debug/dwarf2/var1.c \
	gcc.dg/debug/dwarf2/var1.c \
	gcc.dg/debug/dwarf2/var2.c \
	gcc.dg/debug/dwarf2/var2.c \
	gcc.dg/fold-and-1.c \
	gcc.dg/fold-and-2.c \
	gcc.dg/fold-ior-1.c \
	gcc.dg/fold-minus-2.c \
	gcc.dg/fold-minus-3.c \
	gcc.dg/fold-minus-4.c \
	gcc.dg/fold-minus-5.c \
	gcc.dg/fold-plus-1.c \
	gcc.dg/fold-plus-2.c \
	gcc.dg/fold-xor-3.c \
	gcc.dg/fold-xor-4.c \
	gcc.dg/fold-xor-5.c \
	gcc.dg/funcorder.c \
	gcc.dg/gimplefe-18.c \
	gcc.dg/gimplefe-18.c \
	gcc.dg/gimplefe-21.c \
	gcc.dg/gimplefe-21.c \
	gcc.dg/gimplefe-30.c \
	gcc.dg/ifcvt-4.c \
	gcc.dg/ifcvt-4.c \
	gcc.dg/inline-1.c \
	gcc.dg/inline-3.c \
	gcc.dg/loop-9.c \
	gcc.dg/loop-9.c \
	gcc.dg/noreorder3.c \
	gcc.dg/old-style-asm-1.c \
	gcc.dg/opts-2.c \
	gcc.dg/opts-2.c \
	gcc.dg/param-type-mismatch.c \
	gcc.dg/param-type-mismatch.c \
	gcc.dg/pr16107.c \
	gcc.dg/pr25376.c \
	gcc.dg/pr25376.c \
	gcc.dg/pr25795-1.c \
	gcc.dg/pr27528.c \
	gcc.dg/pr27528.c \
	gcc.dg/pr28685-1.c \
	gcc.dg/pr30643.c \
	gcc.dg/pr30957-1.c \
	gcc.dg/pr30957-1.c \
	gcc.dg/pr33645-2.c \
	gcc.dg/pr39443.c \
	gcc.dg/pr52171.c \
	gcc.dg/pr57134.c \
	gcc.dg/pr57134.c \
	gcc.dg/pr60087.c \
	gcc.dg/pr60087.c \
	gcc.dg/pr63387-2.c \
	gcc.dg/pr63387.c \
	gcc.dg/pr64295.c \
	gcc.dg/pr64295.c \
	gcc.dg/pr66299-2.c \
	gcc.dg/pr70017.c \
	gcc.dg/pr70017.c \
	gcc.dg/pr78902.c \
	gcc.dg/pr78902.c \
	gcc.dg/pr81281-1.c \
	gcc.dg/pr81281-2.c \
	gcc.dg/pr82404.c \
	gcc.dg/pr82404.c \
	gcc.dg/pr87811-3.c \
	gcc.dg/pr87811-3.c \
	gcc.dg/pr93210.c \
	gcc.dg/pr93210.c \
	gcc.dg/pr93399.c \
	gcc.dg/pr94600-3.c \
	gcc.dg/pr94600-5.c \
	gcc.dg/pr94600-7.c \
	gcc.dg/pr98721-2.c \
	gcc.dg/pr98721-2.c \
	gcc.dg/pragma-re-1.c \
	gcc.dg/pragma-re-4.c \
	gcc.dg/profile-info-section.c \
	gcc.dg/profile-info-section.c \
	gcc.dg/pthread-init-1.c \
	gcc.dg/pthread-init-2.c \
	gcc.dg/recip_sqrt_mult_2.c \
	gcc.dg/sibcall-10.c \
	gcc.dg/sibcall-10.c \
	gcc.dg/sibcall-9.c \
	gcc.dg/sibcall-9.c \
	gcc.dg/stack-usage-1.c \
	gcc.dg/stack-usage-1.c \
	gcc.dg/strlenopt-40.c \
	gcc.dg/strlenopt-44.c \
	gcc.dg/strlenopt-70.c \
	gcc.dg/type-convert-var.c \
	gcc.dg/typeof-1.c \
	gcc.dg/uninit-1-O0.c \
	gcc.dg/uninit-11-O0.c \
	gcc.dg/uninit-11-O0.c \
	gcc.dg/uninit-13-O0.c \
	gcc.dg/uninit-13-O0.c \
	gcc.dg/uninit-15-O0.c \
	gcc.dg/uninit-15-O0.c \
	gcc.dg/uninit-17-O0.c \
	gcc.dg/uninit-17-O0.c \
	gcc.dg/uninit-3-O0.c \
	gcc.dg/uninit-6-O0.c \
	gcc.dg/uninit-6-O0.c \
	gcc.dg/unroll-8.c \
	gcc.dg/unwind-1.c \
	gcc.dg/unwind-1.c \
	gcc.dg/var-expand1.c \
	gcc.dg/var-expand1.c \
	gcc.dg/varpool-1.c

# This rule isn't perfect, it tars up data it might not have written.
wasm32/cross/test/gcc/problem.tar:
	$(MAKE) -k $(GCC_PROBLEM_TESTS:%=wasm32/cross/test/gcc/results/%.{dejagnu}/okay) || true
	tar cf $@ wasm32/cross/test/gcc/results

# No sibcalls yet
GCC_BAD_TESTS = \
	gcc.dg/lto/20091216-1_0.c \
	gcc.dg/pr78902.c \
	gcc.dg/sibcall-9.c \
	gcc.dg/sibcall-10.c \
	gcc.dg/unwind-1.c \
	gcc.c-torture/execute/920428-2.c \
	gcc.c-torture/execute/920501-7.c \
	gcc.c-torture/execute/comp-goto-2.c \
	gcc.c-torture/execute/nestfunc-5.c \
	gcc.c-torture/execute/nestfunc-6.c \

GCC_BAD_TESTSUITES = \
	gcc.c-torture/execute/builtins/builtins.exp \
	gcc.dg/compat/compat.exp \
	gcc.dg/dfp/dfp.exp \
	gcc.dg/fixed-point/fixed-point.exp \
	gcc.dg/ipa/ipa.exp \
	gcc.dg/special/mips-abi.exp \
	gcc.dg/vect/costmodel/i386/i386-costmodel-vect.exp \
	gcc.dg/vect/costmodel/ppc/ppc-costmodel-vect.exp \
	gcc.dg/vect/costmodel/x86_64/x86_64-costmodel-vect.exp \
	gcc.dg/vmx/vmx.exp \
	gcc.dg/vxworks/vxworks.exp \

GCC_TESTSUITES = \
	gcc.c-torture/compile/compile.exp \
	gcc.c-torture/execute/execute.exp \
	gcc.c-torture/execute/ieee/ieee.exp \
	gcc.c-torture/unsorted/unsorted.exp \
	gcc.dg/asan/asan.exp \
	gcc.dg/atomic/atomic.exp \
	gcc.dg/autopar/autopar.exp \
	gcc.dg/charset/charset.exp \
	gcc.dg/cpp/cpp.exp \
	gcc.dg/debug/debug.exp \
	gcc.dg/debug/dwarf2/dwarf2.exp \
	gcc.dg/dg.exp \
	gcc.dg/format/format.exp \
	gcc.dg/goacc-gomp/goacc-gomp.exp \
	gcc.dg/goacc/goacc.exp \
	gcc.dg/gomp/gomp.exp \
	gcc.dg/graphite/graphite.exp \
	gcc.dg/guality/guality.exp \
	gcc.dg/hwasan/hwasan.exp \
	gcc.dg/lto/lto.exp \
	gcc.dg/noncompile/noncompile.exp \
	gcc.dg/params/params.exp \
	gcc.dg/pch/pch.exp \
	gcc.dg/plugin/plugin.exp \
	gcc.dg/rtl/rtl.exp \
	gcc.dg/sancov/sancov.exp \
	gcc.dg/simulate-thread/simulate-thread.exp \
	gcc.dg/special/special.exp \
	gcc.dg/sso/sso.exp \
	gcc.dg/tls/tls.exp \
	gcc.dg/tm/tm.exp \
	gcc.dg/torture/dg-torture.exp \
	gcc.dg/torture/stackalign/stackalign.exp \
	gcc.dg/torture/tls/tls.exp \
	gcc.dg/tree-prof/tree-prof.exp \
	gcc.dg/tree-ssa/tree-ssa.exp \
	gcc.dg/tsan/tsan.exp \
	gcc.dg/ubsan/ubsan.exp \
	gcc.dg/vect/complex/complex.exp \
	gcc.dg/vect/vect.exp \
	gcc.dg/weak/weak.exp

TOOLS_c = bitpush wasmextract wasmrewrite wasmsect
TOOLS_cc =
TOOLS_script = cflags dotdir dyninfo elf32-wasm32 elf-to-wasm jsc locked run-elf-wasm32 testsuite-make-fragment wasm

$(patsubst %,wasm32/cross/bin/%,$(TOOLS_c)): wasm32/cross/bin/%: tools/src/%.c | wasm32/cross/bin
	gcc -Wall -g3 $< -o $@

$(patsubst %,wasm32/cross/bin/%,$(TOOLS_cc)): wasm32/cross/bin/%: tools/src/%.cc | wasm32/cross/bin
	g++ -Wall -g3 $< -o $@

$(patsubst %,wasm32/cross/bin/%,$(TOOLS_script)): wasm32/cross/bin/%: tools/bin/% | wasm32/cross/bin
	cp -a $< $@ && chmod u+x $@

wasm32/wasm/bin/%: wasm32/native/bin/%
	$(MKDIR) $(dir wasm32/wasm/bin/$*)
	wasm32/cross/bin/elf-to-wasm --executable --dynamic --output $@ $<

wasm32/wasm/%.so: wasm32/native/%.so | wasm32/cross/bin/elf-to-wasm wasm32/cross/bin/wasmrewrite wasm32/cross/bin/wasmsect wasm32/cross/bin/dyninfo wasm32/cross/lib/wasm32-lds/wasm32.lds wasm32/cross/lib/wasm32-lds/wasm32-wasmify.lds wasm32/cross/bin/wasm wasm32/cross/bin/elf32-wasm32
	$(MKDIR) $(dir wasm32/wasm/$*)
	wasm32/cross/bin/elf-to-wasm --library --dynamic --output $@ $<

wasm32/wasm/%.so.1: wasm32/native/%.so.1 | wasm32/cross/bin/elf-to-wasm wasm32/cross/bin/wasmrewrite wasm32/cross/bin/wasmsect wasm32/cross/bin/dyninfo wasm32/cross/lib/wasm32-lds/wasm32.lds wasm32/cross/lib/wasm32-lds/wasm32-wasmify.lds wasm32/cross/bin/wasm wasm32/cross/bin/elf32-wasm32
	$(MKDIR) $(dir wasm32/wasm/$*)
	wasm32/cross/bin/elf-to-wasm --library --dynamic --output $@ $<

wasm32/wasm/%.so.2: wasm32/native/%.so.2 | wasm32/cross/bin/elf-to-wasm wasm32/cross/bin/wasmrewrite wasm32/cross/bin/wasmsect wasm32/cross/bin/dyninfo wasm32/cross/lib/wasm32-lds/wasm32.lds wasm32/cross/lib/wasm32-lds/wasm32-wasmify.lds wasm32/cross/bin/wasm wasm32/cross/bin/elf32-wasm32
	$(MKDIR) $(dir wasm32/wasm/$*)
	wasm32/cross/bin/elf-to-wasm --library --dynamic --output $@ $<


# wasm/ targets. These should go away at some point.

wasm32/native/lib/stub.so:
	./wasm32/cross/bin/wasm32-unknown-none-g++ -fPIC -shared -o $@ ./subrepos/binutils-gdb/gdb/stubs/wasm32-stub-cpp.cc

wasm/stub.wasm: wasm32/wasm/lib/stub.so | wasm/
	$(LN) ../$< $@

wasm/ld.wasm: wasm32/wasm/lib/ld.so.1 | wasm/
	$(LN) ../$< $@

wasm/libc.wasm: wasm32/wasm/lib/libc.so | wasm/
	$(LN) ../$< $@

wasm/libm.wasm: wasm32/wasm/lib/libm.so | wasm/
	$(LN) ../$< $@

wasm/libcrypt.wasm: wasm32/wasm/lib/libcrypt.so | wasm/
	$(LN) ../$< $@

wasm/libutil.wasm: wasm32/wasm/lib/libutil.so.1 | wasm/
	$(LN) ../$< $@

wasm/libstdc++.wasm: wasm32/wasm/lib/libstdc++.so | wasm/
	$(LN) ../$< $@

wasm/libncurses.wasm: wasm32/wasm/lib/libncurses.so | wasm/
	$(LN) ../$< $@

wasm/libdl.wasm: wasm32/wasm/lib/libdl.so.2 | wasm/
	$(LN) ../$< $@

wasm/libanl.wasm: wasm32/wasm/lib/libanl.so | wasm/
	$(LN) ../$< $@

wasm/bash.wasm: wasm32/wasm/bin/bash | wasm/
	$(LN) ../$< $@

wasm/emacs.wasm: wasm32/wasm/bin/emacs | wasm/
	$(LN) ../$< $@

wasm/temacs.wasm: wasm32/wasm/bin/temacs | wasm/
	$(LN) ../$< $@

wasm/libz.wasm: wasm32/wasm/lib/libz.so | wasm/
	$(LN) ../$< $@

wasm/libgccjit.wasm: wasm32/wasm/lib/libgccjit.so | wasm/
	$(LN) ../$< $@

wasm/zsh.wasm: wasm32/wasm/bin/zsh | wasm/
	$(LN) ../$< $@

wasm/miniperl.wasm: wasm32/wasm/bin/miniperl | wasm/
	$(LN) ../$< $@

wasm/perl.wasm: wasm32/wasm/bin/perl | wasm/
	$(LN) ../$< $@

wasm/python.wasm: wasm32/wasm/bin/python3 | wasm/
	$(LN) ../$< $@

COREUTILS = echo true false ls cat seq od printf printenv
$(patsubst %,wasm/%.wasm,$(COREUTILS)): wasm/%.wasm: wasm32/wasm/bin/% wasm32/cross/bin/wasmrewrite wasm32/cross/bin/wasmsect stamp/wasm32/native/coreutils/build | wasm/
	$(LN) ../$< $@

# The ThinThin wrapper
wasm32/cross/lib/js/wasm32.js: jsc/wasm32/wasm32.jsc | wasm32/cross/lib/js/ wasm32/cross/bin/jsc install/file-slurp
	(echo "//autogenerated from $<, do not edit"; echo '"use strict";'; wasm32/cross/bin/jsc wasm32-unknown-none) < $< > $@.new
	mv $@.new $@

stamp/wasm32/native/all/build: stamp/wasm32/native/binutils-gdb/build stamp/wasm32/native/gcc-preliminary/build stamp/wasm32/native/glibc/build stamp/wasm32/native/gcc/build stamp/wasm32/native/ncurses/build stamp/wasm32/native/bash/build stamp/wasm32/native/gdb/build
	touch $@

wasm32/cross/lib/wasm32-lds/wasm32.lds: lds/wasm32.cpp-lds
	$(MKDIR) $(dir $@)
	cpp < $< | egrep -v '^#' > $@

wasm32/cross/lib/wasm32-lds/wasm32-wasmify.lds: lds/wasm32-wasmify.lds
	$(MKDIR) $(dir $@)
	cat $< > $@

.SECONDARY:
.PRECIOUS: test/wasm32/%

# Test framework
testsuite-dirs = $(wildcard testsuite/*)
test-dirs = $(patsubst testsuite/%,test/wasm32/%,$(testsuite-dirs))

$(test-dirs): test/wasm32/%: | testsuite/% test/wasm32 stamp/wasm32/native/glibc/build
	$(MKDIR) test/wasm32/$*
	cp -r testsuite/$*/* test/wasm32/$*/
	$(LN) ../../../testsuite/$* test/wasm32/$*/src

test/wasm32/%/test.mk: testsuite/% wasm32/cross/bin/testsuite-make-fragment
	$(MKDIR) test/wasm32/$*
	wasm32/cross/bin/testsuite-make-fragment testsuite/$*/ test/wasm32/$*/ $(patsubst testsuite/$*/%,%,$(wildcard testsuite/$*/*)) > $@

include $(patsubst %,%/test.mk,$(test-dirs))

run-all-tests!: | install/binfmt_misc/elf32-wasm32
run-all-tests!: | install/binfmt_misc/wasm
run-all-tests!: | wasm32/cross/bin/elf-to-wasm wasm32/cross/lib/wasm32-lds/wasm32.lds wasm32/cross/lib/wasm32-lds/wasm32-wasmify.lds
run-all-tests!: $(patsubst testsuite/%,test/wasm32/%/status,$(wildcard testsuite/*)) wasm/libc.wasm wasm/libm.wasm wasm/ld.wasm wasm/libdl.wasm wasm/libanl.wasm

test/wasm32!: run-all-tests!

test!: test/wasm32!

github/install/binfmt_misc/elf32-wasm32: | github/install/ github/install/binfmt_misc/
	sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc || true
	echo ':elf32-wasm32:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x57\x41:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:'"$(PWD)/wasm32/cross/bin/elf32-wasm32"':' | sudo tee /proc/sys/fs/binfmt_misc/register
	touch $@

github/install/binfmt_misc/wasm: | github/install/ github/install/binfmt_misc/
	sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc || true
	echo ':wasm:M::\x00asm\x01\x00\x00\x00:\xff\xff\xff\xff\xff\xff\xff\xff:'"$(PWD)/wasm32/cross/bin/wasm"':' | sudo tee /proc/sys/fs/binfmt_misc/register
	touch $@
ifeq (${GITHUB},1)
# GitHub support
# Check out a subrepo
subrepos/%/checkout!:
	git submodule update --depth=1 --single-branch --init --recursive subrepos/$*

# install various packages on the GitHub VM:
github/install/file-slurp: | github/install/ wasm32/cross/bin/locked
	wasm32/cross/bin/locked --lockfile apt.lock sudo apt-get install cpanminus
	sudo cpanm File::Slurp
	touch $@

github/install/nroff: | github/install/ wasm32/cross/bin/locked
	wasm32/cross/bin/locked --lockfile apt.lock sudo apt-get install groff-base
	touch $@

github/install/texinfo-bison-flex: | github/install/ wasm32/cross/bin/locked
	wasm32/cross/bin/locked --lockfile apt.lock sudo apt-get install texinfo bison flex
	touch $@

github/install/gcc-dependencies: | github/install/ wasm32/cross/bin/locked
	wasm32/cross/bin/locked --lockfile apt.lock sudo apt-get install libgmp-dev libmpfr-dev libmpc-dev gcc g++
	touch $@

github/install/dejagnu: | github/install/ wasm32/cross/bin/locked
	wasm32/cross/bin/locked --lockfile apt.lock sudo apt-get install dejagnu
	touch $@

github/install/gettext: | github/install/ wasm32/cross/bin/locked
	wasm32/cross/bin/locked --lockfile apt.lock sudo apt-get install gettext
	touch $@

github/install/sysctl/overcommit_memory: | github/install/sysctl/
	echo 1 | sudo tee /proc/sys/vm/overcommit_memory
	touch $@

github/install/wasm32-environment: | github/install/sysctl/overcommit_memory github/install/binfmt_misc/elf32-wasm32 github/install/binfmt_misc/wasm github/install/file-slurp wasm32/cross/bin/elf-to-wasm wasm32/cross/bin/elf32-wasm32 wasm32/cross/bin/wasm
	touch $@

artifact-miniperl!: | install/gettext
artifact-perl!: | install/gettext
artifact-python!: | install/gettext
github/install/autopoint: | github/install/ wasm32/cross/bin/locked
	wasm32/cross/bin/locked --lockfile apt.lock sudo apt-get install autopoint

github/install/gperf: | github/install/ wasm32/cross/bin/locked
	wasm32/cross/bin/locked --lockfile apt.lock sudo apt-get install gperf

install/%: github/install/%
	$(MKDIR) install/$(dir $*)
	touch $@
else
install/%:
	$(MKDIR) install/$(dir $*)
	touch $@
endif

# objdump debug rule
%.wasm.wasm-objdump: %.wasm stamp/wasm32/cross/wabt/build
	wasm32/cross/bin/wasm-objdump -dhx $< > $@

# wasm-to-wasm optimization rules
%.wasm.{O}.wasm: %.wasm stamp/wasm32/cross/binaryen/build
	wasm32/cross/bin/wasm-opt $< -o $@
%.wasm.{O4}.wasm: %.wasm stamp/wasm32/cross/binaryen/build
	wasm32/cross/bin/wasm-opt -O4 $< -o $@
%.wasm.{Oz}.wasm: %.wasm stamp/wasm32/cross/binaryen/build
	wasm32/cross/bin/wasm-opt -Oz $< -o $@

# C -> exe/o/s rules. These take special flags as part of the filename:
#  foo.{nostdlib}.c: a C file to be compiled without stdlibs
#  foo.c.{static}.exe: an executable compiled statically, from foo.c
cflags = $(shell wasm32/cross/bin/cflags $(1) $(2))

test/wasm32/%.c.exe: test/wasm32/%.c | wasm32/cross/bin/cflags
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-gcc $(call cflags,$*.c,$(dir testsuite/$*)) -DSHARED $< -o $@

test/wasm32/%.c.{static}.exe: test/wasm32/%.c | wasm32/cross/bin/cflags
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-gcc $(call cflags,$*.c,$(dir testsuite/$*)) -Wl,-Map,test/wasm32/$*.c.{static}.map -static $< -o $@

test/wasm32/%.c.{debug}.exe: test/wasm32/%.c | wasm32/cross/bin/cflags
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-gcc $(call cflags,$*.c.{debug},$(dir testsuite/$*)) -Wl,-Map,test/wasm32/$*.c.{static}.map $< -o $@ -lstdc++ -lm

test/wasm32/%.c.{static}.exe.wasm.out.exp: test/wasm32/%.c.exe.wasm.out.exp
	cat $< > $@

test/wasm32/%.c.{static}.exe.wasm.out.exp.pl: test/wasm32/%.c.exe.wasm.out.exp.pl
	cat $< > $@

test/wasm32/%.cc.{static}.exe: test/wasm32/%.cc | wasm32/cross/bin/cflags
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-g++ $(call cflags,$*.c,$(dir testsuite/$*)) -Wl,-Map,test/wasm32/$*.cc.{static}.map $< -lstdc++ -o $@

test/wasm32/%.cc.{static}.exe.wasm.out.exp: test/wasm32/%.cc.exe.wasm.out.exp
	cat $< > $@

test/wasm32/%.cc.{static}.exe.wasm.out.exp.pl: test/wasm32/%.cc.exe.wasm.out.exp.pl
	cat $< > $@

# exe -> wasm rule
test/wasm32/%.exe.wasm: test/wasm32/%.exe wasm32/cross/bin/elf-to-wasm
	wasm32/cross/bin/elf-to-wasm --executable --output $@ $<

# wasm output rule
test/wasm32/%.wasm.out: test/wasm32/%.wasm
	JS="$(JS)" WASMDIR=$(PWD) EXECUTABLE=$< $(JS) $(PWD)/wasm32/cross/lib/js/wasm32.js $< > $@ 2> test/wasm32/$*.wasm.err || true
	@echo "STDOUT"
	@cat $@
	@echo "STDERR"
	@cat test/wasm32/$*.wasm.err

test/wasm32/%.gdb.out: test/wasm32/%.gdb
	JS="$(JS)" WASMDIR=$(PWD) $(PWD)/wasm32/cross/bin/wasm32-unknown-none-gdb --command=$< --batch > $@

comma = ,
car = $(firstword $(1))
cdr = $(wordlist 2,$(words $(1)),$(1))
multideps = $(addprefix $(2)$(call car,$(1)),$(subst $(comma), ,$(call cdr,$(1))))

test/wasm32/%].exe: $$(subst ./,,$$(call multideps,$$(subst [, ,./$$*),test/wasm32/))
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-$(if $(filter %.cc.o %.cc.s.o,$^),g++,gcc) -DSHARED $^ -o $@

test/wasm32/%].{static}.exe: $$(subst ./,,$$(call multideps,$$(subst [, ,./$$*),test/wasm32/))
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-$(if $(filter %.cc.o %.cc.s.o,$^),g++,gcc) -static $^ -o $@

test/wasm32/%.o.exe: test/wasm32/%.o
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-gcc $< -o $@

test/wasm32/%.cc.exe: test/wasm32/%.cc
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-g++ -DSHARED $< -o $@

test/wasm32/%.c.s: test/wasm32/%.c
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-gcc -S $< -o $@

test/wasm32/%.S.o: test/wasm32/%.S | wasm32/cross/bin/cflags
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-gcc $(call cflags,$*,$(dir testsuite/$*)) -c $< -o $@

test/wasm32/%.c.o: test/wasm32/%.c | wasm32/cross/bin/cflags
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-gcc $(call cflags,$*,$(dir testsuite/$*)) -c $< -o $@

test/wasm32/%.c.i: test/wasm32/%.c | wasm32/cross/bin/cflags
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-gcc $(call cflags,$*,$(dir testsuite/$*)) -E $< -o $@

test/wasm32/%.cc.i: test/wasm32/%.cc | wasm32/cross/bin/cflags
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-g++ $(call cflags,$*,$(dir testsuite/$*)) -E $< -o $@

test/wasm32/%.cc.s: test/wasm32/%.cc
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-g++ -S $< -o $@

test/wasm32/%.cc.o: test/wasm32/%.cc
	$(PWD)/wasm32/cross/bin/wasm32-unknown-none-g++ -c $< -o $@

test/wasm32/%.exp.cmp: test/wasm32/%.exp.pl test/wasm32/%
	perl $^ > $@

test/wasm32/%.c.{static}.exe.wasm.out.exp: test/wasm32/%.c.exe.wasm.out.exp
	cat $< > $@

test/wasm32/%.c.{static}.exe.wasm.out.exp.pl: test/wasm32/%.c.exe.wasm.out.exp.pl
	cat $< > $@

test/%.exp.cmp: test/%.exp test/%
	diff -u $^ > $@ || (cat $@; false)


%.{dejagnu}!: wasm32/cross/lib/js/wasm32.js install/texinfo-bison-flex install/gcc-dependencies install/dejagnu build | extracted/artifacts/down/wasm32-cross-toolchain.tar wasm32/cross/bin/wasmrewrite wasm32/cross/bin/wasmsect install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 artifacts/down/libc.wasm artifacts/down/ld.wasm artifacts/down/libm.wasm artifacts/up/ artifacts/down/ wasm
	cp artifacts/down/*.wasm wasm
	$(MAKE) artifact-timestamp
	$(MKDIR) build/wasm32/gcc/gcc/testsuite/gcc
	(cd build/wasm32/gcc/gcc; make site.exp && cp site.exp testsuite && cp site.exp testsuite/gcc)
#	(cd src/gcc/gcc/testsuite/; find -type d | while read DIR; do cd $DIR; ls * | shuf | head -n +128 | egrep -v '*.dg' | while read; do rm $REPLY; done; done) || true
	(cd src/gcc/gcc/testsuite; find -type f | egrep '\.([cisSxX]|x0|X0)$$' | xargs md5sum | egrep -v "^$$PREFIX" | while read shasum path; do rm -f $$path; done)
	(cd build/wasm32/gcc/gcc/testsuite/gcc; WASMDIR=$(PWD) JS=$(PWD)/wasm32/cross/bin/js srcdir=$(PWD)/src/gcc/gcc runtest -a --tool gcc $*) | tee $(notdir $*).out || true
	cp $(notdir $*).out artifacts/up/$(notdir $*)-$$PREFIX.out
	cp build/wasm32/gcc/gcc/testsuite/gcc/gcc.log artifacts/up/$(notdir $*)-$$PREFIX.log
	grep FAIL build/wasm32/gcc/gcc/testsuite/gcc/gcc.log > artifacts/up/$(notdir $*)-$$PREFIX-short.log || true
	$(MAKE) artifact-push!

%.{daily-dejanew}!: wasm32/cross/lib/js/wasm32.js install/texinfo-bison-flex install/gcc-dependencies install/dejagnu | wasm32/cross/bin/wasmrewrite wasm32/cross/bin/wasmsect install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 subrepos/gcc/checkout! daily/ src/gcc/
	$(MAKE) extracted/daily/binutils.tar.gz
	$(MAKE) extracted/daily/glibc.tar.gz
	$(MAKE) extracted/daily/gcc-preliminary.tar.gz
	$(MAKE) extracted/daily/gcc.tar.gz
	$(MAKE) wasm32/cross/bin/js
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libanl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) wasm/libstdc++.wasm
	$(MAKE) artifacts/up/ artifact-timestamp
	JS=$(PWD)/wasm32/cross/bin/js WASMDIR=$(PWD) $(MAKE) build/wasm32/gcc-testsuite-tar/$*.{dejagnu}.tar
	cp build/wasm32/gcc-testsuite-tar/$*.{dejagnu}.tar artifacts/up/

%.{dejanew}!: wasm32/cross/lib/js/wasm32.js install/texinfo-bison-flex install/gcc-dependencies install/dejagnu | extracted/artifacts/down/wasm32-cross-toolchain.tar wasm32/cross/bin/wasmrewrite wasm32/cross/bin/wasmsect install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 artifacts/down/libc.wasm artifacts/down/ld.wasm artifacts/down/libm.wasm subrepos/gcc/checkout! artifacts/up/ artifacts/down/ src/gcc/
	$(MKDIR) wasm
	cp artifacts/down/*.wasm wasm
	$(MAKE) artifact-timestamp
	$(MAKE) build/wasm32/gcc-testsuite/$*.{dejagnu}.tar
	cp build/wasm32/gcc-testsuite/$*.{dejagnu}.tar artifacts/up/

binutils-test!: install/dejagnu
	$(MAKE) subrepos/binutils-gdb/checkout!
	$(MAKE) stamp/wasm32/binutils-gdb/build
	$(MAKE) artifacts/up/
	$(MAKE) artifact-timestamp
	$(MAKE) -k -C build/wasm32/binutils-gdb check || true
	find build/wasm32/binutils-gdb -name '*.log' | egrep -v 'config\.log$$' | while read REPLY; do cp $$REPLY artifacts/up/; done
	$(MAKE) artifact-push!

gcc-testsuite!: build/wasm32/gcc-testsuite/gcc.c-torture/compile/compile.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.c-torture/execute/execute.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.dg/dg.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.dg/weak/weak.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.c-torture/execute/ieee/ieee.exp.{dejagnu}.tar


gcc-testsuites-pack!: | artifacts/down/atomic.exp.{dejagnu}.tar artifacts/down/builtins.exp.{dejagnu}.tar artifacts/down/charset.exp.{dejagnu}.tar artifacts/down/compile.exp.{dejagnu}.tar artifacts/down/debug.exp.{dejagnu}.tar artifacts/down/dg.exp.{dejagnu}.tar artifacts/down/dwarf2.exp.{dejagnu}.tar artifacts/down/execute.exp.{dejagnu}.tar artifacts/down/format.exp.{dejagnu}.tar artifacts/down/ieee.exp.{dejagnu}.tar artifacts/down/lto.exp.{dejagnu}.tar artifacts/down/tls.exp.{dejagnu}.tar artifacts/down/tm.exp.{dejagnu}.tar artifacts/down/weak.exp.{dejagnu}.tar
	$(MAKE) artifact-timestamp
	mkdir tmp
	cd tmp; for a in artifacts/down/atomic.exp.{dejagnu}.tar artifacts/down/builtins.exp.{dejagnu}.tar artifacts/down/charset.exp.{dejagnu}.tar artifacts/down/compile.exp.{dejagnu}.tar artifacts/down/debug.exp.{dejagnu}.tar artifacts/down/dg.exp.{dejagnu}.tar artifacts/down/dwarf2.exp.{dejagnu}.tar artifacts/down/execute.exp.{dejagnu}.tar artifacts/down/format.exp.{dejagnu}.tar artifacts/down/ieee.exp.{dejagnu}.tar artifacts/down/lto.exp.{dejagnu}.tar artifacts/down/tls.exp.{dejagnu}.tar artifacts/down/tm.exp.{dejagnu}.tar artifacts/down/weak.exp.{dejagnu}.tar; do tar xvf ../$$a; done
	cd tmp; tar cvf ../artifacts/up/dejagnu.tar .

sequence: \
	stamp/wasm32/cross/binutils-gdb/build \
	stamp/wasm32/cross/gcc-preliminary/build \
	stamp/wasm32/native/glibc/build \
	stamp/wasm32/cross/gcc/build \
	stamp/wasm32/native/ncurses/build \
	stamp/wasm32/native/bash/build \
	stamp/wasm32/native/zsh/build \
	stamp/wasm32/native/coreutils/build \
	stamp/wasm32/native/python/build \
	stamp/wasm32/native/miniperl/build \
	stamp/wasm32/native/zlib/build \
	stamp/wasm32/native/gmp/build \
	stamp/wasm32/native/mpc/build \
	stamp/wasm32/native/mpfr/build \
	stamp/wasm32/native/binutils-gdb/build \
	stamp/wasm32/native/gcc/build \
	stamp/wasm32/cross/emacs/build \
	stamp/wasm32/native/emacs/build \
	stamp/wasm32/cross/wabt/build \
	stamp/wasm32/cross/binaryen/build

all: sequence

.PHONY: %! clean all
.SUFFIXES:

stamp/wasm32/cross/python/configure: | stamp/wasm32/cross/gcc/build wasm32/native/src/python wasm32/native/build/python stamp/wasm32/native/python/
	(cd wasm32/native/build/python; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32/cross/bin:$$PATH ../../src/python/configure --build=$(native-triplet) --host=wasm32-unknown-none --prefix=$(PWD)/wasm32/native --disable-ipv6 --with-ensurepip=no)
	touch $@

stamp/wasm32/cross/python/build: stamp/wasm32/cross/python/configure | stamp/wasm32/cross
	$(MAKE) -C wasm32/cross/build/python
	$(MAKE) -C wasm32/cross/build/python install
	touch $@

ifeq (${DAILY},1)
wasm32/cross/bin/js: extracted/daily/wasm32-environment.tar.gz
else
wasm32/cross/bin/js:
	ln -sf $$(which node) $@
endif

ifeq (${GITHUB},1)
problem!: | subrepos/gcc/checkout! extracted/daily/wasm32-cross-toolchain.tar.gz wasm32/cross/bin/js install/dejagnu install/gcc-dependencies install/texinfo-bison-flex install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp install/wasm32-environment wasm32/cross/src/gcc
	$(MAKE) wasm wasm/ld.wasm wasm/libc.wasm wasm/libdl.wasm wasm/libanl.wasm wasm/libcrypt.wasm wasm/libutil.wasm wasm/libm.wasm wasm/libstdc++.wasm wasm32/cross/lib/js/wasm32.js
	$(MAKE) artifacts/up/ artifact-timestamp
	JS=$(PWD)/wasm32/cross/bin/js WASMDIR=$(PWD) $(MAKE) wasm32/cross/test/gcc/problem.tar
	cp wasm32/cross/test/gcc/problem.tar artifacts/up
	$(MAKE) artifact-push!

gcc-testsuites!: $(patsubst %,build/wasm32/gcc-testsuite/%.{dejagnu}.tar,$(GCC_TESTSUITES)) | all

daily/binutils-gdb!: | subrepos/binutils-gdb/checkout!
	$(MAKE) stamp/wasm32/cross/binutils-gdb/build

daily/gcc-preliminary!: | subrepos/gcc/checkout! extracted/daily/wasm32-cross-toolchain.tar.gz
	rm -rf stamp/wasm32/cross/*/gcc-preliminary
	$(MAKE) stamp/wasm32/cross/gcc-preliminary/build

daily/glibc!: | subrepos/glibc/checkout! extracted/daily/wasm32-cross-toolchain.tar.gz
	rm -rf stamp/wasm32/native/*/glibc
	$(MAKE) stamp/wasm32/native/glibc/build

daily/gcc!: | subrepos/gcc/checkout! extracted/daily/wasm32-cross-toolchain.tar.gz
	rm -rf stamp/wasm32/cross/*/gcc
	$(MAKE) stamp/wasm32/cross/gcc/build
	$(MAKE) wasm/libstdc++.wasm

daily/ncurses!: | subrepos/ncurses/checkout! extracted/daily/wasm32-cross-toolchain.tar.gz
	$(MAKE) stamp/wasm32/native/ncurses/build
	$(MAKE) wasm/libncurses.wasm

daily/miniperl!: | subrepos/perl/checkout! extracted/daily/wasm32-cross-toolchain.tar.gz
	$(MAKE) stamp/wasm32/native/miniperl/build
	$(MAKE) wasm/miniperl.wasm

daily/bash!: | install/file-slurp
daily/coreutils!: | install/file-slurp
daily/emacs!: | install/file-slurp
daily/miniperl!: | install/file-slurp
daily/perl!: | install/file-slurp
daily/python!: | install/file-slurp
daily/ncurses!: | install/file-slurp
daily/run-all-tests!: | install/file-slurp
daily/run-all-tests!: | wasm32/cross/bin/dyninfo
daily/run-all-tests!: | wasm32/cross/lib/js/wasm32.js
daily/run-elf!: | install/file-slurp
daily/run-elf!: | wasm32/cross/bin/dyninfo
daily/run-elf!: | wasm32/cross/lib/js/wasm32.js
daily/run-wasm!: | install/file-slurp
daily/run-wasm!: | wasm32/cross/bin/dyninfo
daily/run-wasm!: | wasm32/cross/lib/js/wasm32.js
daily/zsh!: | install/file-slurp

daily/bash!: | subrepos/bash/checkout! extracted/daily/wasm32-cross-toolchain.tar.gz extracted/daily/wasm32-native-ncurses.tar.gz
	$(MAKE) stamp/wasm32/native/bash/build wasm/bash.wasm

stamp/wasm32/native/zsh/build: | install/nroff

daily-zsh!: | subrepos/zsh/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/ncurses.tar.gz
	$(MAKE) stamp/wasm32/native/zsh/build

daily/coreutils!: | subrepos/coreutils/checkout! extracted/daily/wasm32-cross-toolchain.tar.gz extracted/daily/wasm32-native-ncurses.tar.gz extracted/daily/wasm32-environment.tar.gz install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/js
	$(MAKE) wasm/libc.wasm wasm/libm.wasm wasm/libdl.wasm wasm/libanl.wasm wasm/libutil.wasm wasm/libcrypt.wasm
	JS="$(JS)" WASMDIR=$(PWD) $(MAKE) stamp/wasm32/native/coreutils/build
	JS="$(JS)" WASMDIR=$(PWD) $(MAKE) $(patsubst %,wasm/%.wasm,$(COREUTILS))

daily-emacs!: | subrepos/emacs/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/ncurses.tar.gz install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/js
	$(MAKE) artifacts/down/wasm/ld.wasm
	$(MAKE) artifacts/down/wasm/libc.wasm
	$(MAKE) artifacts/down/wasm/libdl.wasm
	$(MAKE) artifacts/down/wasm/libanl.wasm
	$(MAKE) artifacts/down/wasm/libcrypt.wasm
	$(MAKE) artifacts/down/wasm/libutil.wasm
	$(MAKE) artifacts/down/wasm/libm.wasm
	$(MAKE) artifacts/down/wasm/libncurses.wasm
	JS="$(JS)" WASMDIR=$(PWD) $(MAKE) stamp/wasm32/native/emacs/build
	JS="$(JS)" WASMDIR=$(PWD) $(MAKE) $(patsubst %,wasm/%.wasm,temacs emacs)

daily-gmp!: | subrepos/gmp/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/ncurses.tar.gz install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/js
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libanl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) wasm/libncurses.wasm
	JS="$(JS)" WASMDIR=$(PWD) $(MAKE) stamp/wasm32/native/gmp/build

daily-miniperl!: | subrepos/perl/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/js
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libanl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) stamp/wasm32/native/miniperl/build wasm/miniperl.wasm

daily-perl!: | subrepos/perl/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/sysctl/overcommit_memory wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/js
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libanl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) stamp/wasm32/native/perl/build wasm/perl.wasm

daily-python!: | subrepos/python/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/js
	$(MAKE) stamp/wasm32/cross/python/build
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libanl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) stamp/wasm32/native/python/build wasm/python.wasm
	touch wasm32/native/lib/python3.10/encodings/.dir wasm32/native/lib/python3.10/.dir
	PYTHONHOME=$(PWD)/wasm32/native ./wasm32/native/bin/python3 -c 'print(3+4)' < /dev/null

daily-run-elf!: | extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/js
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libanl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	./wasm32/cross/bin/wasm32-unknown-none-gcc ./testsuite/003-hello-world/hello-world.c -o hello-world.exe
	./hello-world.exe

daily-run-wasm!: | extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/js wasm32/cross/bin/elf-to-wasm
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libanl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	./wasm32/cross/bin/wasm32-unknown-none-gcc ./testsuite/003-hello-world/hello-world.c -o hello-world.exe
	./hello-world.exe
	wasm32/cross/bin/elf-to-wasm --executable --output hello-world.wasm hello-world.exe
	./hello-world.wasm

daily-run-all-tests!: | extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz wasm32/cross/lib/js/wasm32.js wasm32/cross/bin/js wasm32/cross/bin/elf-to-wasm
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libanl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) wasm/libstdc++.wasm
	$(MAKE) run-all-tests!

# Build the various artifacts
artifact-wasm32-environment!: | artifacts/up/ artifacts/down/ install/file-slurp
	$(MAKE) artifact-timestamp
	$(MKDIR) wasm32/cross/bin
	ln -sf $$(which node) wasm32/cross/bin/js
	$(MAKE) github/install/binfmt_misc/wasm
	$(MAKE) github/install/binfmt_misc/elf32-wasm32
	$(MAKE) wasm32/cross/lib/js/wasm32.js
	tar cvf artifacts/up/wasm32-environment.tar wasm32/cross/lib/js/wasm32.js wasm32/cross/bin
	cat wasm32/cross/lib/js/wasm32.js > artifacts/up/wasm32.js
	$(MAKE) artifact-push!

artifact-wasm32-cross-binutils-gdb!: | subrepos/binutils-gdb/checkout! artifacts/up/ artifacts/down/
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/cross/binutils-gdb/build
	tar cf artifacts/up/wasm32-cross-binutils-gdb.tar $(patsubst %,wasm32/cross/%,bin include lib libexec share stamp wasm32-unknown-none) $(patsubst %,wasm32/native/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/cross/binutils-gdb -N ./artifact-timestamp
	$(MAKE) artifact-push!

artifact-wasm32-cross-gcc-preliminary!: | subrepos/gcc/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-binutils-gdb.tar github/install/gcc-dependencies
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/cross/gcc-preliminary/build
	tar cf artifacts/up/wasm32-cross-gcc-preliminary.tar $(patsubst %,wasm32/cross/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/cross/gcc-preliminary -N ./artifact-timestamp
	$(MAKE) artifact-push!

artifact-wasm32-native-gcc!: | subrepos/gcc/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-binutils-gdb.tar extracted/artifacts/down/wasm32-native-glibc.tar artifacts/down/wasm32-cross-gcc.tar github/install/gcc-dependencies extracted/artifacts/down/wasm32-cross-toolchain.tar extracted/artifacts/down/wasm32-native-gmp.tar extracted/artifacts/down/wasm32-native-mpc.tar extracted/artifacts/down/wasm32-native-mpfr.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/gcc/build
	tar cf artifacts/up/wasm32-native-gcc.tar $(patsubst %,wasm32/cross/%,bin include lib libexec share stamp wasm32-unknown-none) $(patsubst %,wasm32/native/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/cross/gcc -N ./artifact-timestamp
	$(MAKE) artifact-push!

artifact-wasm32-native-glibc!: | subrepos/glibc/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-binutils-gdb.tar extracted/artifacts/down/wasm32-cross-gcc-preliminary.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/glibc/build
	tar cf artifacts/up/wasm32-native-glibc.tar $(patsubst %,wasm32/native/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/native/glibc -N ./artifact-timestamp
	$(MAKE) wasm/libc.wasm wasm/ld.wasm wasm/libm.wasm wasm/libutil.wasm wasm/libcrypt.wasm wasm/libdl.wasm wasm/libanl.wasm
	cp wasm/libc.wasm wasm/ld.wasm wasm/libm.wasm wasm/libutil.wasm wasm/libcrypt.wasm wasm/libdl.wasm wasm/libanl.wasm artifacts/up
	$(MAKE) artifact-push!

artifact-wasm32-cross-gcc!: | subrepos/gcc/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-binutils-gdb.tar extracted/artifacts/down/wasm32-cross-gcc-preliminary.tar extracted/artifacts/down/wasm32-native-glibc.tar github/install/gcc-dependencies
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/cross/gcc/build
	$(MAKE) wasm/libstdc++.wasm
	tar cf artifacts/up/wasm32-cross-gcc.tar $(patsubst %,wasm32/cross/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/cross/gcc -N ./artifact-timestamp
	$(MKDIR) stamp/wasm32/cross/download
	touch stamp/wasm32/cross/binutils-gdb/download
	touch stamp/wasm32/cross/gcc-preliminary/download
	touch stamp/wasm32/native/glibc/download
	touch stamp/wasm32/cross/gcc/download
	tar cf artifacts/up/wasm32-cross-toolchain.tar $(patsubst %,wasm32/cross/%,bin include lib libexec share stamp wasm32-unknown-none) $(patsubst %,wasm32/native/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/cross/gcc
	cp wasm/libstdc++.wasm artifacts/up
	$(MAKE) artifact-push!

artifact-wasm32-native-ncurses!: | subrepos/ncurses/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar
	$(MAKE) extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/ncurses/build
	$(MAKE) wasm/libncurses.wasm
	tar cf artifacts/up/wasm32-native-ncurses.tar $(patsubst %,wasm32/native/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/native/ncurses -N ./artifact-timestamp
	cp wasm/libncurses.wasm artifacts/up/
	$(MAKE) artifact-push!

artifact-wasm32-native-binutils-gdb!: | subrepos/binutils-gdb/checkout! extracted/artifacts/down/wasm32-cross-toolchain.tar extracted/artifacts/down/wasm32-native-gmp.tar artifacts/up/ artifacts/down/
	$(MAKE) extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/binutils-gdb/build
	tar cf artifacts/up/wasm32-native-binutils-gdb.tar $(patsubst %,wasm32/cross/%,bin include lib libexec share stamp wasm32-unknown-none) $(patsubst %,wasm32/native/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/native/binutils-gdb -N ./artifact-timestamp
	$(MAKE) artifact-push!

artifact-wasm32-native-bash!: | subrepos/bash/checkout! artifacts/down/ artifacts/up/ extracted/artifacts/down/wasm32-cross-toolchain.tar extracted/artifacts/down/wasm32-native-ncurses.tar
	$(MAKE) extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/bash/build wasm/bash.wasm
	cp wasm/bash.wasm artifacts/up/
	$(MAKE) artifact-push!

artifact-wasm32-native-zsh!: | subrepos/zsh/checkout! artifacts/up/ extracted/artifacts/down/wasm32-cross-toolchain.tar extracted/artifacts/down/wasm32-native-ncurses.tar
	$(MAKE) extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/zsh/build wasm/zsh.wasm
	cp wasm/zsh.wasm artifacts/up/
	$(MAKE) artifact-push!

artifact-wasm32-native-zlib!: | subrepos/zlib/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar
	$(MAKE) extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/zlib/build wasm/libz.wasm
	cp wasm/libz.wasm artifacts/up/
	$(MAKE) artifact-push!

artifact-wasm32-native-gmp!: | subrepos/gmp/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar
	$(MAKE) extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/gmp/build
	tar cf artifacts/up/wasm32-native-gmp.tar $(patsubst %,wasm32/cross/%,bin include lib libexec share stamp wasm32-unknown-none) $(patsubst %,wasm32/native/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/native/gmp -N ./artifact-timestamp
	$(MAKE) artifact-push!

artifact-wasm32-native-mpfr!: | subrepos/mpfr/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar extracted/artifacts/down/wasm32-native-gmp.tar
	$(MAKE) extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) extracted/artifacts/down/wasm32-native-gmp.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/mpfr/build
	tar cf artifacts/up/wasm32-native-mpfr.tar $(patsubst %,wasm32/cross/%,bin include lib libexec share stamp wasm32-unknown-none) $(patsubst %,wasm32/native/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/native/mpfr -N ./artifact-timestamp
	$(MAKE) artifact-push!

artifact-wasm32-native-mpc!: | subrepos/mpc/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar extracted/artifacts/down/wasm32-native-gmp.tar
	$(MAKE) extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) extracted/artifacts/down/wasm32-native-gmp.tar
	$(MAKE) extracted/artifacts/down/wasm32-native-mpfr.tar
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/mpc/build
	tar cf artifacts/up/wasm32-native-mpc.tar $(patsubst %,wasm32/cross/%,bin include lib libexec share stamp wasm32-unknown-none) $(patsubst %,wasm32/native/%,bin include lib libexec share stamp wasm32-unknown-none) stamp/wasm32/native/mpc -N ./artifact-timestamp
	$(MAKE) artifact-push!

artifact-wasm32-native-coreutils!: | subrepos/coreutils/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar extracted/artifacts/down/wasm32-native-ncurses.tar install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp wasm32/cross/lib/js/wasm32.js artifacts/down/libc.wasm artifacts/down/ld.wasm artifacts/down/libm.wasm artifacts/down/libncurses.wasm wasm32/cross/bin/elf-to-wasm wasm32/cross/lib/wasm32-lds/wasm32.lds wasm32/cross/lib/wasm32-lds/wasm32-wasmify.lds wasm32/cross/bin/wasmrewrite wasm32/cross/bin/wasmsect wasm32/cross/bin/dyninfo wasm32/cross/bin/elf-to-wasm extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) install/wasm32-environment
	$(MAKE) artifact-timestamp
	$(MKDIR) wasm
	cp artifacts/down/*.wasm wasm
	$(MAKE) stamp/wasm32/native/coreutils/build
	$(MAKE) $(patsubst %,wasm/%.wasm,$(COREUTILS))
	cp $(patsubst %,wasm/%.wasm,$(COREUTILS)) artifacts/up/
	$(MAKE) artifact-push!

artifact-wasm32-native-python!: | subrepos/python/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar wasm32/cross/lib/js/wasm32.js install/wasm32-environment install/file-slurp
	$(MAKE) stamp/wasm32/cross/python/build
	$(MAKE) artifact-timestamp
	$(MKDIR) wasm
	$(MAKE) artifacts/down/wasm/ld.wasm
	$(MAKE) artifacts/down/wasm/libc.wasm
	$(MAKE) artifacts/down/wasm/libdl.wasm
	$(MAKE) artifacts/down/wasm/libanl.wasm
	$(MAKE) artifacts/down/wasm/libcrypt.wasm
	$(MAKE) artifacts/down/wasm/libutil.wasm
	$(MAKE) artifacts/down/wasm/libm.wasm
	$(MAKE) stamp/wasm32/native/python/build wasm/python.wasm
	touch wasm32/native/lib/python3.10/encodings/.dir wasm32/native/lib/python3.10/.dir
	PYTHONHOME=$(PWD)/wasm32/native ./wasm32/native/bin/python3 -c 'print(3+4)' < /dev/null
	cp wasm/python.wasm artifacts/up/
	$(MAKE) artifact-push!

artifact-emacs!: | subrepos/emacs/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar extracted/artifacts/down/wasm32-native-glibc.tar extracted/artifacts/down/wasm32-native-ncurses.tar install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp wasm32/cross/lib/js/wasm32.js
	$(MAKE) extracted/artifacts/down/wasm32-environment.tar
	$(MAKE) artifact-timestamp
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libanl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	JS=$(PWD)/wasm32/cross/bin/js WASMDIR=$(PWD) $(MAKE) stamp/wasm32/native/emacs/build
	JS=$(PWD)/wasm32/cross/bin/js WASMDIR=$(PWD) $(MAKE) $(patsubst %,wasm/%.wasm,temacs emacs)
	cp $(patsubst %,wasm/%.wasm,temacs emacs) artifacts/up/
	$(MAKE) artifact-push!

artifact-miniperl!: | install/binfmt_misc/elf32-wasm32
artifact-miniperl!: | install/binfmt_misc/wasm
artifact-miniperl!: | install/file-slurp

artifact-perl!: | install/binfmt_misc/elf32-wasm32
artifact-perl!: | install/binfmt_misc/wasm
artifact-perl!: | install/file-slurp

artifact-miniperl!: | subrepos/perl/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar wasm32/cross/lib/js/wasm32.js
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/miniperl/build wasm/miniperl.wasm
	cp wasm/miniperl.wasm artifacts/up/
	$(MAKE) artifact-push!

artifact-perl!: | subrepos/perl/checkout! artifacts/up/ artifacts/down/ extracted/artifacts/down/wasm32-cross-toolchain.tar wasm32/cross/lib/js/wasm32.js
	$(MAKE) artifact-timestamp
	$(MAKE) stamp/wasm32/native/perl/build wasm/perl.wasm
	cp wasm/perl.wasm artifacts/up/
	$(MAKE) artifact-push!

artifact-python!: | install/binfmt_misc/elf32-wasm32
artifact-python!: | install/binfmt_misc/wasm
artifact-python!: | install/file-slurp

# Create a file to be shipped
ship/%.gz: artifacts/down/% | ship/
	gzip < $< > $@

ship/%: artifacts/down/% | ship/
	cat $< > $@

# Retrieve asset list (and cache it)
github/assets/%.json: | github/release/list! github/assets/
	if [ -e "github/release/\"$*\"" ]; then \
	    curl -sSL "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets" > $@; \
	else \
	    echo "[]" > $@; \
	fi

# Ship assets
ship-wasm/%!: ship/libc.wasm ship/ld.wasm ship/libncurses.wasm ship/bash.wasm ship/libutil.wasm ship/libm.wasm ship/libdl.wasm ship/libanl.wasm ship/libcrypt.wasm github/assets/%.json | ship/ github/ github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-binutils/%!: ship/binutils.tar.gz github/assets/%.json | ship/ github/ github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-gcc-preliminary/%!: ship/gcc-preliminary.tar.gz github/assets/%.json | ship/ github/ github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-gcc/%!: ship/gcc.tar.gz github/assets/%.json | ship/ github/ github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship/wasm32-cross-toolchain/%!: ship/wasm32-cross-toolchain.tar.gz github/assets/%.json | ship/ github/ github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship/wasm32-environment/%!: ship/wasm32-environment.tar.gz github/assets/%.json | ship/ github/ github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-glibc/%!: ship/glibc.tar.gz github/assets/%.json | ship/ github/ github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-bash/%!: ship/bash.tar.gz github/assets/%.json | ship/ github/ github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship/wasm32-native-ncurses/%!: ship/wasm32-native-ncurses.tar.gz github/assets/%.json | ship/ github/ github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-problem/%!: ship/problem.tar.gz github/assets/%.json | ship/ github/ github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

github/release/list!: | github/release/
	curl -sSL https://api.github.com/repos/$$GITHUB_REPOSITORY/releases?per_page=100 | jq '.[] | [(.).tag_name,(.).id] | .[]' | while read tag; do read id; echo $$id > github/release/$$tag; done
	curl -sSL https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/tags/latest | jq '.[.tag_name,.id] | .[]' | while read tag; do read id; echo $$id > github/release/$$tag; done
	ls -l github/release/

github/check-release!: | github/
	last_release_date="$$(curl https://api.github.com/repos/$$GITHUB_REPOSITORY/releases | jq "[.[] | .created_at] | sort[-1]" | cut -c 2-11)"; \
	this_release_date="$$(date --iso)"; \
	if [ "$$this_release_date" != "$$last_release_date" ]; then \
	    node ./github/release.js $$this_release_date $$last_release_date > github/release.json; \
	    curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases" --data '@github/release.json'; \
	    sleep 1m; \
	    $(MAKE) ship-wasm/$$this_release_date!; \
	fi; \
	true

artifacts/up/ artifacts/down/: | .github-init

.github-init:
	bash github/artifact-init
	touch $@

# Extract an artifact
extracted/%.tar: %.tar | extracted/
	$(MKDIR) $(dir extracted/$*)
	tar xf $*.tar
	touch $@

extracted/%.tar.gz: %.tar.gz | extracted/
	$(MKDIR) $(dir extracted/$*)
	tar xzf $*.tar.gz
	touch $@

daily/%: | daily/
	bash github/dl-daily $*
	ls -l $@

artifacts/down/%: | artifacts/down/
	bash github/dl-artifact $*
	mv $@.new/$* $@
	rm -rf $@.new
	ls -l $@

artifact-timestamp:
	touch $@
	sleep 1

artifact-push!:
	(cd artifacts/up; for file in *; do if [ "$$file" -nt ../../artifact-timestamp ]; then name=$$(basename "$$file"); (cd ../..; bash github/ul-artifact "$$name" "artifacts/up/$$name"); fi; done)

ifneq ($(DAILY),)
stamp/wasm32/native/%/download: stamp/wasm32/native/%/ extracted/daily/wasm32-native-%.tar.gz
	touch $@

stamp/wasm32/cross/binutils-gdb/download: stamp/wasm32/cross/binutils-gdb/
	touch $@

stamp/wasm32/cross/gcc-preliminary/download: stamp/wasm32/cross/gcc-preliminary/
	touch $@

stamp/wasm32/native/glibc/download: stamp/wasm32/native/glibc/
	touch $@

stamp/wasm32/cross/gcc/download: stamp/wasm32/cross/gcc/
	touch $@
else
stamp/wasm32/native/%/download: stamp/wasm32/native/%/ extracted/artifacts/down/wasm32-native-%.tar
	touch $@
endif
endif
