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

src/wasm32/binutils-gdb/.dir: src/wasm32/.dir
	test -d src/wasm32/binutils-gdb || mkdir src/wasm32/binutils-gdb
	(cd subrepos/binutils-gdb; tar c --exclude .git .) | (cd src/wasm32/binutils-gdb; tar x)
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

build/wasm32/binutils-gdb/Makefile: src/wasm32/binutils-gdb/.dir build/wasm32/binutils-gdb/.dir
	(cd src/wasm32/binutils-gdb/gas; aclocal; automake; autoreconf)
	(cd build/wasm32/binutils-gdb; ../../../src/wasm32/binutils-gdb/configure --target=wasm32-unknown-none --enable-debug --prefix=$(PWD)/wasm32-unknown-none CFLAGS=$(OPT_NATIVE))

build/wasm32/binutils-gdb.make: build/wasm32/binutils-gdb/Makefile bin/.dir
	$(MAKE) -C build/wasm32/binutils-gdb
	$(MAKE) -C build/wasm32/binutils-gdb install
	(cd bin; ln -sf ../wasm32-unknown-none/bin/wasm32-unknown-none-* .)
	touch $@
