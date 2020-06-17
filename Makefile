all: built/all

MKDIR ?= mkdir
PWD ?= $(shell pwd)
OPT_NATIVE ?= "-O0 -g3"
OPT_WASM ?= "-O2"

env:
	@echo "export WASMDIR=$(PWD)"
	@echo "export LANG=C"

src/wasm32: | src
	test -d $@ || $(MKDIR) $@

src/wasm32/binutils-gdb: | src/wasm32
	$(MKDIR) $@T
	(cd subrepos/binutils-gdb; tar c --exclude .git .) | (cd $@T; tar x)
	mv $@T $@

src/gcc: | src
	test -L $@ || ln -sf ../subrepos/gcc $@

src/glibc: | src
	test -L $@ || ln -sf ../subrepos/glibc $@

src/ncurses: | src
	test -L $@ || ln -sf ../subrepos/ncurses $@

src/bash: | src
	test -L $@ || ln -sf ../subrepos/bash $@

src/wabt: | src
	test -L $@ || ln -sf ../subrepos/wabt $@

src/binaryen: | src
	test -L $@ || ln -sf ../subrepos/binaryen $@

bin build built js lib src test wasm:
	test -d $@ || $(MKDIR) $@

build/common: | build
	test -d $@ || $(MKDIR) $@

built/common: | built
	test -d $@ || $(MKDIR) $@

build/wasm32: | build
	test -d $@ || $(MKDIR) $@

built/wasm32: | built
	test -d $@ || $(MKDIR) $@

test/wasm32: | test
	test -d $@ || $(MKDIR) $@

build/wasm32/binutils-gdb build/wasm32/gcc-preliminary build/wasm32/glibc build/wasm32/gcc build/wasm32/ncurses build/wasm32/bash: | build/wasm32
	test -d $@ || $(MKDIR) $@

build/wasm32/emacs: | build/wasm32
	test -d $@ || ($(MKDIR) $@T; (cd subrepos/emacs; tar c --exclude .git .) | (cd $@T; tar x); mv $@T $@)

build/common/binaryen build/common/wabt: | build/common
	test -d $@ || $(MKDIR) $@

build/common/binaryen/Makefile: | build/common/binaryen src/binaryen
	(cd build/common/binaryen; cmake ../../../src/binaryen -DCMAKE_INSTALL_PREFIX=$(PWD)/common -DCMAKE_BUILD_TYPE=Debug)

built/common/binaryen: build/common/binaryen/Makefile | built/common
	$(MAKE) -C build/common/binaryen
	$(MAKE) -C build/common/binaryen install
	(cd bin; ln -sf ../common/bin/* .)
	touch $@

build/common/wabt/Makefile: | src/wabt build/common/wabt
	(cd build/common/wabt; cmake ../../../src/wabt -DBUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$(PWD)/common -DCMAKE_BUILD_TYPE=Debug)

built/common/wabt: build/common/wabt/Makefile | built/common
	$(MAKE) -C build/common/wabt
	$(MAKE) -C build/common/wabt install
	(cd bin; ln -sf ../common/bin/* .)
	touch $@

build/wasm32/binutils-gdb/Makefile: | src/wasm32/binutils-gdb build/wasm32/binutils-gdb
	(cd src/wasm32/binutils-gdb/gas; aclocal; automake; autoreconf)
	(cd build/wasm32/binutils-gdb; ../../../src/wasm32/binutils-gdb/configure --target=wasm32-unknown-none --enable-debug --prefix=$(PWD)/wasm32-unknown-none CFLAGS=$(OPT_NATIVE))

built/wasm32/binutils-gdb: build/wasm32/binutils-gdb/Makefile | bin built/wasm32
	$(MAKE) -C build/wasm32/binutils-gdb
	$(MAKE) -C build/wasm32/binutils-gdb install
	(cd bin; ln -sf ../wasm32-unknown-none/bin/wasm32-unknown-none-* .)
	touch $@

build/wasm32/gcc-preliminary/Makefile: built/wasm32/binutils-gdb | build/wasm32/gcc-preliminary src/gcc
	(cd build/wasm32/gcc-preliminary; CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) ../../../src/gcc/configure --enable-optimize=$(OPT_NATIVE) --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --enable-languages=c --disable-libssp --prefix=$(PWD)/wasm32-unknown-none)

built/wasm32/gcc-preliminary: build/wasm32/gcc-preliminary/Makefile | built/wasm32
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) $(MAKE) -C build/wasm32/gcc-preliminary
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) $(MAKE) -C build/wasm32/gcc-preliminary install
	cp wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc.a wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc_eh.a
	cp wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc.a wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc_s.a
	(cd bin; ln -sf ../wasm32-unknown-none/bin/wasm32-unknown-none-* .)
	touch $@

build/wasm32/glibc/Makefile: built/wasm32/gcc-preliminary | src/glibc build/wasm32/glibc
	(cd build/wasm32/glibc; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/glibc/configure CFLAGS="-fPIC -O1 -Wno-error=missing-attributes" --enable-optimize=$(OPT_NATIVE) --host=wasm32-unknown-none --target=wasm32-unknown-none --enable-hacker-mode --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)

built/wasm32/glibc: build/wasm32/glibc/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/glibc
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/glibc install
	touch $@

build/wasm32/gcc/Makefile: built/wasm32/glibc | src/gcc build/wasm32/gcc
	(cd build/wasm32/gcc; ../../../src/gcc/configure --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --disable-libssp --prefix=$(PWD)/wasm32-unknown-none)

built/wasm32/gcc: build/wasm32/gcc/Makefile | built/wasm32
	test -d build/wasm32/gcc/gcc || $(MKDIR) build/wasm32/gcc/gcc
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gcc
	cp build/wasm32/gcc/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_eh.a
	cp build/wasm32/gcc/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_s.a
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gcc install
	touch $@

build/wasm32/ncurses/Makefile: built/wasm32/gcc | src/ncurses build/wasm32/ncurses
	(cd build/wasm32/ncurses; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/ncurses/configure --enable-optimize=$(OPT_ASMJS) --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --disable-stripping --with-shared)
	touch $@

built/wasm32/ncurses: build/wasm32/ncurses/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/ncurses
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/ncurses install
	touch $@

build/wasm32/bash/Makefile: built/wasm32/ncurses | src/bash build/wasm32/bash
	(cd build/wasm32/bash; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/bash/configure --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)
	touch $@

built/wasm32/bash: build/wasm32/bash/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/bash
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/bash install
	touch $@

built/wasm32/emacs: build/wasm32/emacs built/wasm32/ncurses | built/wasm32
	(cd build/wasm32/emacs; sh autogen.sh; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ./configure --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --without-x --with-gnutls=ifavailable)
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/emacs
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/emacs install
	touch $@

bin/wasmify-library: wasmify/wasmify-library bin/wasmrewrite bin/wasmsect | bin
	ln -sf ../$< $@

bin/wasmify-executable: wasmify/wasmify-executable bin/wasmrewrite bin/wasmsect | bin
	ln -sf ../$< $@

wasm/ld.wasm: bin/wasmify-library wasm32-unknown-none/wasm32-unknown-none/lib/ld.so.1 | wasm
	bash -x bin/wasmify-library wasm32-unknown-none/wasm32-unknown-none/lib/ld.so.1 > $@

wasm/libc.wasm: bin/wasmify-library wasm32-unknown-none/wasm32-unknown-none/lib/libc.so | wasm
	bash -x bin/wasmify-library wasm32-unknown-none/wasm32-unknown-none/lib/libc.so > $@

wasm/libncurses.wasm: bin/wasmify-library wasm32-unknown-none/wasm32-unknown-none/lib/libncurses.so | wasm
	bash -x bin/wasmify-library wasm32-unknown-none/wasm32-unknown-none/lib/libncurses.so > $@

wasm/bash.wasm: wasm32-unknown-none/wasm32-unknown-none/bin/bash bin/wasmify-executable | wasm
	bash -x bin/wasmify-executable $< > $@

js/wasm32-%.jsc.js: jsc/wasm32-%.jsc | js
	perl ./jsc-interpolate/jsc.pl wasm32-unknown-none < $< > $@

js/wasm32-%.jsc.js: jsc/asm-%.jsc | js
	perl ./jsc-interpolate/jsc.pl wasm32-unknown-none < $< > $@

js/wasm32.js: js/wasm32-main.jsc.js js/wasm32-range.jsc.js js/wasm32-system.jsc.js js/wasm32-thinthin.jsc.js js/wasm32-boot.jsc.js
	echo "// autogenerated from $^, do not edit" > $@.new
	cat js/wasm32-range.jsc.js js/wasm32-system.jsc.js js/wasm32-thinthin.jsc.js js/wasm32-main.jsc.js js/wasm32-boot.jsc.js >> $@.new
	mv $@.new $@

bin/wasmrewrite: wasmrewrite/wasmrewrite.c | bin
	gcc -g3 $< -o $@

bin/wasmsect: wasmrewrite/wasmsect.c | bin
	gcc -g3 $< -o $@

built/all: built/wasm32/all built/common/all
	touch $@

built/wasm32/all: built/wasm32/binutils-gdb built/wasm32/gcc-preliminary built/wasm32/glibc built/wasm32/gcc built/wasm32/ncurses built/wasm32/bash
	touch $@

built/common/all: built/common/binaryen built/common/wabt
	touch $@

%.cpp-lds.lds: %.cpp-lds
	cpp < $< | egrep -v '^#' > $@

clean:
	rm -rf build built src wasm32-unknown-none

.SECONDARY: build/common/binaryen/Makefile build/common/wabt/Makefile build/wasm32/binutils-gdb/Makefile build/wasm32/gcc-preliminary/Makefile build/wasm32/glibc/Makefile build/wasm32/gcc/Makefile build/wasm32/ncurses/Makefile build/wasm32/bash/Makefile build/wasm32/emacs
.PRECIOUS: test/wasm32/% test/wasm32/%/Makefile

test/wasm32/%: | tests/% test/wasm32 built/wasm32/glibc
	$(MKDIR) test/wasm32/$*
	ln -sf ../../../tests/$* test/wasm32/$*/src

test/wasm32/%/Makefile: tests/%/ test-templ/Makefile.pl | test/wasm32/%
	perl test-templ/Makefile.pl tests/$*/ tests/$*/* > $@

test/wasm32/%/status: test/wasm32/%/Makefile
	$(MAKE) WASMDIR=$(PWD) JS=$$JS -C test/wasm32/$* all

all-tests: $(patsubst tests/%,test/wasm32/%/status,$(wildcard tests/*))

start-over:
	rm -rf build built src test

artifact-test:
	bash -x github/artifact-init
	echo bar > foo
	bash -x github/ul-artifact foo foo

artifact-test-2: artifacts/wasm32.js
	shasum artifacts/wasm32.js

install-file-slurp:
	sudo apt-get install cpanminus
	sudo cpanm File::Slurp
	touch $@

artifact-wasm32.js: | install-file-slurp js/wasm32.js artifact-timestamp artifacts
	cat js/wasm32.js > artifacts/wasm32.js
	$(MAKE) artifact-push

-include github/github.mk
