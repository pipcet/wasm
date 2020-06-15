all: error

MKDIR ?= mkdir
PWD ?= $(shell pwd)
OPT_NATIVE ?= "-O0 -g3"
OPT_WASM ?= "-O2"

env:
	@echo "export WASMDIR=$(PWD)"
	@echo "export LANG=C"

bin/.dir:
	test -d bin || $(MKDIR) bin
	touch $@

src/.dir:
	test -d src || $(MKDIR) src
	touch $@

src/wasm32/.dir: src/.dir
	test -d src/wasm32 || $(MKDIR) src/wasm32
	touch $@

src/wasm32/binutils-gdb.dir: src/wasm32/.dir
	test -d src/wasm32/binutils-gdb || mkdir src/wasm32/binutils-gdb
	(cd subrepos/binutils-gdb; tar c --exclude .git .) | (cd src/wasm32/binutils-gdb; tar x)
	touch $@

src/gcc.dir: src/.dir
	test -L src/gcc || ln -sf ../subrepos/gcc src/gcc
	touch $@

src/glibc.dir: src/.dir
	test -L src/glibc || ln -sf ../subrepos/glibc src/glibc
	touch $@

src/ncurses.dir: src/.dir
	test -L src/ncurses || ln -sf ../subrepos/ncurses src/ncurses
	touch $@

build/.dir:
	test -d build || $(MKDIR) build
	touch $@

build/wasm32/.dir: build/.dir
	test -d build/wasm32 || $(MKDIR) build/wasm32
	touch $@

build/wasm32/binutils-gdb/.dir: build/wasm32/.dir
	test -d build/wasm32/binutils-gdb || $(MKDIR) build/wasm32/binutils-gdb
	touch $@

build/wasm32/binutils-gdb/Makefile: src/wasm32/binutils-gdb.dir build/wasm32/binutils-gdb/.dir
	(cd src/wasm32/binutils-gdb/gas; aclocal; automake; autoreconf)
	(cd build/wasm32/binutils-gdb; ../../../src/wasm32/binutils-gdb/configure --target=wasm32-unknown-none --enable-debug --prefix=$(PWD)/wasm32-unknown-none CFLAGS=$(OPT_NATIVE))

build/wasm32/binutils-gdb.make: build/wasm32/binutils-gdb/Makefile bin/.dir
	$(MAKE) -C build/wasm32/binutils-gdb
	$(MAKE) -C build/wasm32/binutils-gdb install
	(cd bin; ln -sf ../wasm32-unknown-none/bin/wasm32-unknown-none-* .)
	touch $@

build/wasm32/gcc-preliminary/.dir: build/wasm32/.dir
	test -d build/wasm32/gcc-preliminary || $(MKDIR) build/wasm32/gcc-preliminary
	touch $@

build/wasm32/gcc-preliminary/Makefile: src/gcc.dir build/wasm32/gcc-preliminary/.dir
	(cd build/wasm32/gcc-preliminary; ../../../src/gcc/configure --enable-optimize=$(OPT_NATIVE) --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --enable-languages=c --disable-libssp --prefix=$(PWD)/wasm32-unknown-none)
	touch $@

build/wasm32/gcc-preliminary.make: build/wasm32/gcc-preliminary/Makefile
	$(MAKE) -C build/wasm32/gcc-preliminary
	$(MAKE) -C build/wasm32/gcc-preliminary install
	cp wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc.a wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc_eh.a
	cp wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc.a wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc_s.a
	(cd bin; ln -sf ../wasm32-unknown-none/bin/wasm32-unknown-none-* .)
	touch $@

build/wasm32/glibc/.dir: build/wasm32/.dir
	test -d build/wasm32/glibc || $(MKDIR) build/wasm32/glibc
	touch $@

build/wasm32/glibc/Makefile: src/glibc.dir build/wasm32/glibc/.dir
	(cd build/wasm32/glibc; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/glibc/configure CFLAGS="-fPIC -O3 -Wno-error=missing-attributes" --enable-optimize=$(OPT_NATIVE) --host=wasm32-unknown-none --target=wasm32-unknown-none --enable-hacker-mode --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)
	touch $@

build/wasm32/glibc.make: build/wasm32/glibc/Makefile
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/glibc
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/glibc install
	touch $@

build/wasm32/gcc/.dir: build/wasm32/.dir
	test -d build/wasm32/gcc || $(MKDIR) build/wasm32/gcc
	touch $@

build/wasm32/gcc/Makefile: src/gcc.dir build/wasm32/gcc/.dir
	(cd build/wasm32/gcc; ../../../src/gcc/configure --enable-optimize=$(OPT_NATIVE) --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --disable-libssp --prefix=$(PWD)/wasm32-unknown-none)
	touch $@

build/wasm32/gcc.make: build/wasm32/gcc/Makefile
	test -d build/wasm32/gcc/gcc || $(MKDIR) build/wasm32/gcc/gcc
	cp build/wasm32/gcc-preliminary/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_eh.a
	cp build/wasm32/gcc-preliminary/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_s.a
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gcc
	cp build/wasm32/gcc/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_eh.a
	cp build/wasm32/gcc/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_s.a
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gcc install
	touch $@

build/wasm32/ncurses/.dir: build/wasm32/.dir
	test -d build/wasm32/ncurses || $(MKDIR) build/wasm32/ncurses
	touch $@

build/wasm32/ncurses/Makefile: src/ncurses.dir build/wasm32/ncurses/.dir
	(cd build/wasm32/ncurses; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/ncurses/configure --enable-optimize=$(OPT_ASMJS) --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --disable-stripping)
	touch $@

build/wasm32/ncurses.make: build/wasm32/ncurses/Makefile
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/ncurses
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/ncurses install
	touch $@
