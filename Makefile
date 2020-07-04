# $(MKDIR) command
MKDIR ?= mkdir -p
# $(PWD) is the top-level directory. No recursion here (except for subrepos).
PWD ?= $(shell pwd)
OPT_NATIVE ?= "-O0 -g3"
OPT_WASM ?= "-O2"
WASMDIR ?= $(PWD)
JS ?= $$JS

.SECONDEXPANSION:
# This has to be the first rule: build everything, currently scattered over too many directories.

all!: lds/wasm32.cpp-lds.lds built/all js/wasm32.js wasm/libc.wasm wasm/ld.wasm wasm/libm.wasm wasm/libstdc++.wasm tools/bin/wasmrewrite tools/bin/wasmsect tools/bin/bitpush wasm/libdl.wasm wasm/libncurses.wasm wasm/bash.wasm

# Top-level directories to be created automatically and deleted when cleaning. Keep them in sync!
bin build built extracted github/assets github/release github/install js lib ship src stamp test wasm:
	$(MKDIR) $@

start-over!:
	rm -rf bin build built extracted github/assets github/release github/install js lib ship src stamp test wasm wasm32-unknown-none lds/*.cpp-lds.lds

# environment for bash shells
env:
	@echo "export WASMDIR=$(PWD)"
	@echo "export LANG=C"
	@echo "export JS=$(JS)"

# subsidiary directories. Nothing interesting here.
src/wasm32: | src
	$(MKDIR) $@
build/common: | build
	$(MKDIR) $@
built/common: | built
	$(MKDIR) $@
build/wasm32: | build
	$(MKDIR) $@
built/wasm32: | built
	$(MKDIR) $@
test/wasm32: | test
	$(MKDIR) $@
build/wasm32/binutils-gdb build/wasm32/gcc-preliminary build/wasm32/gdb build/wasm32/glibc build/wasm32/gcc build/wasm32/gcc-testsuite build/wasm32/ncurses build/wasm32/bash: | build/wasm32
	$(MKDIR) $@
build/common/binaryen build/common/wabt: | build/common
	$(MKDIR) $@

# binutils-gdb requires source tree modification, so we copy the source.
src/wasm32/binutils-gdb: | src/wasm32
	$(MKDIR) $@T
	(cd subrepos/binutils-gdb; tar c --exclude .git .) | (cd $@T; tar x)
	mv $@T $@

# These repos do not require source tree modification.
good-repos = gcc glibc ncurses bash wabt binaryen coreutils

$(patsubst %,src/%,$(good-repos)): src/%: | src
	test -L $@ || ln -sf ../subrepos/$* $@

# Emacs is _built_ in the source directory, so copy that.
build/wasm32/emacs: | build/wasm32
	test -d $@ || ($(MKDIR) $@T; (cd subrepos/emacs; tar c --exclude .git .) | (cd $@T; tar x); mv $@T $@)

# Coreutils requires its own destructive bootstrap script
build/wasm32/coreutils: | build/wasm32
	test -d $@ || ($(MKDIR) $@T; (cd subrepos/coreutils; tar c --exclude .git .) | (cd $@T; tar x); mv $@T $@)

# We use /Makefile as a sentinel for whether the configure/cmake script has run.
build/common/binaryen/Makefile: | build/common/binaryen src/binaryen
	(cd build/common/binaryen; cmake ../../../src/binaryen -DCMAKE_INSTALL_PREFIX=$(PWD)/common -DCMAKE_BUILD_TYPE=Debug)
build/common/wabt/Makefile: | src/wabt build/common/wabt
	(cd build/common/wabt; cmake ../../../src/wabt -DBUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$(PWD)/common -DCMAKE_BUILD_TYPE=Debug)
build/wasm32/binutils-gdb/Makefile: | src/wasm32/binutils-gdb build/wasm32/binutils-gdb
	(cd src/wasm32/binutils-gdb/gas; aclocal; automake; autoreconf)
	(cd build/wasm32/binutils-gdb; ../../../src/wasm32/binutils-gdb/configure --target=wasm32-unknown-none --enable-debug --prefix=$(PWD)/wasm32-unknown-none CFLAGS=$(OPT_NATIVE))
build/wasm32/gdb/Makefile: | src/wasm32/binutils-gdb build/wasm32/gdb
	(cd build/wasm32/gdb; ../../../src/wasm32/binutils-gdb/configure --target=wasm32-unknown-none --enable-debug --prefix=$(PWD)/wasm32-unknown-none CFLAGS=$(OPT_NATIVE))
# Note that src/gcc is shared between the gcc-preliminary and gcc targets.
build/wasm32/gcc-preliminary/Makefile: | built/wasm32/binutils-gdb build/wasm32/gcc-preliminary src/gcc
	(cd build/wasm32/gcc-preliminary; CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) ../../../src/gcc/configure --enable-optimize=$(OPT_NATIVE) --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --enable-languages=c --disable-libssp --prefix=$(PWD)/wasm32-unknown-none)
build/wasm32/glibc/Makefile: | built/wasm32/gcc-preliminary src/glibc build/wasm32/glibc
	(cd build/wasm32/glibc; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/glibc/configure CFLAGS="-fPIC -O3 -Wno-error=missing-attributes" --enable-optimize=$(OPT_NATIVE) --host=wasm32-unknown-none --target=wasm32-unknown-none --enable-hacker-mode --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)
build/wasm32/gcc/Makefile: | built/wasm32/glibc src/gcc build/wasm32/gcc
	(cd build/wasm32/gcc; ../../../src/gcc/configure CFLAGS="-O3 -g3" CXXFLAGS="-O3 -g3" --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --disable-libssp --prefix=$(PWD)/wasm32-unknown-none)
build/wasm32/gcc-testsuite/site.exp: | build
	$(MKDIR) $(dir $@)
	> $@
	echo 'set rootme "$(PWD)/build/wasm32/gcc-testsuite/"' >> $@
	echo 'set srcdir "$(PWD)/src/gcc/gcc"' >> $@
	echo 'set host_triplet x86_64-pc-linux-gnu' >> $@
	echo 'set build_triplet x86_64-pc-linux-gnu' >> $@
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
	echo 'set TEST_GCC_EXEC_PREFIX "$(PWD)/wasm32-unknown-none/lib/gcc/"' >> $@
	echo 'set TESTING_IN_BUILD_TREE 0' >> $@
	echo 'set HAVE_LIBSTDCXX_V3 1' >> $@
	echo 'set ENABLE_PLUGIN 1' >> $@
	echo 'set PLUGINCC "g++"' >> $@
	echo 'set PLUGINCFLAGS "-g  "' >> $@
	echo 'set GMPINC ""' >> $@
	echo 'set tmpdir /home/pip/g/wasm/build/wasm32/gcc-testsuite' >> $@
	echo 'set srcdir "$${srcdir}/testsuite"' >> $@

build/wasm32/gcc-testsuite/%.{dejagnu}.mk: built/wasm32/gcc | build/wasm32/gcc src/gcc
	$(MKDIR) $(dir $@)
	> $@
	for file in $$(cd src/gcc/gcc/testsuite/$(dir $*); find -type f | egrep '\.[cSi]$$' | sed -e 's/^\.\///g' | egrep -v '\/'); do \
	    echo "build/wasm32/gcc-testsuite/$(dir $*)$$file.{dejagnu}:" >> $@; \
	    echo "\t@(cd build/wasm32/gcc-testsuite; mkdir -p $(dir $*)$$file.{dejagnu}.log/; testtotest=$(dir $*)$$file PATH=$(PWD)/bin:$(PWD)/wasm32-unknown-none/bin:$$PATH runtest --outdir $(dir $*)$$file.{dejagnu}.log/ --tool gcc $* > /dev/null 2> /dev/null) || true" >> $@; \
	    echo "\t@! grep -q unexpected build/wasm32/gcc-testsuite/$(dir $*)$$file.{dejagnu}.log/gcc.log || echo $$file" >> $@; \
	    echo >> $@; \
	    all="$$all build/wasm32/gcc-testsuite/$(dir $*)$$file.{dejagnu}"; \
	done; \
        echo "build/wasm32/gcc-testsuite/$*.all: $$all" >> $@

build/wasm32/gcc-testsuite/%.{dejagnu}.tar: build/wasm32/gcc-testsuite/%.{dejagnu}.mk build/wasm32/gcc-testsuite/site.exp
	$(MAKE) -f $< build/wasm32/gcc-testsuite/$*.all
	tar cf $@ build/wasm32/gcc-testsuite/$(dir $*)

build/wasm32/ncurses/Makefile: | built/wasm32/gcc src/ncurses build/wasm32/ncurses
	(cd build/wasm32/ncurses; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/ncurses/configure --enable-optimize=$(OPT_ASMJS) --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --disable-stripping --with-shared)
	touch $@
build/wasm32/bash/Makefile: | built/wasm32/ncurses src/bash build/wasm32/bash
	(cd build/wasm32/bash; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/bash/configure --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --without-bash-malloc)
	touch $@
build/wasm32/coreutils/Makefile: | built/wasm32/ncurses src/coreutils build/wasm32/coreutils
	(cd build/wasm32/coreutils; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ./bootstrap --skip-po --no-git --gnulib-srcdir=$(PWD)/src/coreutils/gnulib; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ./configure  --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)
	touch $@

# Actually building a package and installing it: make && make install, plus package-specific workarounds.
built/common/binaryen: build/common/binaryen/Makefile | built/common bin
	$(MAKE) -C build/common/binaryen
	$(MAKE) -C build/common/binaryen install
	(cd bin; ln -sf ../common/bin/* .)
	touch $@
built/common/wabt: build/common/wabt/Makefile | built/common bin
	$(MAKE) -C build/common/wabt
	$(MAKE) -C build/common/wabt install
	(cd bin; ln -sf ../common/bin/* .)
	touch $@
built/wasm32/binutils-gdb: build/wasm32/binutils-gdb/Makefile | bin built/wasm32
	$(MAKE) -C build/wasm32/binutils-gdb
	$(MAKE) -C build/wasm32/binutils-gdb install
	(cd bin; ln -sf ../wasm32-unknown-none/bin/wasm32-unknown-none-* .)
	touch $@
built/wasm32/gdb: build/wasm32/gdb/Makefile built/wasm32/gcc | bin built/wasm32
	$(MAKE) -C build/wasm32/gdb
	$(MAKE) -C build/wasm32/gdb install
	(cd bin; ln -sf ../wasm32-unknown-none/bin/wasm32-unknown-none-* .)
	touch $@
built/wasm32/gcc-preliminary: build/wasm32/gcc-preliminary/Makefile | built/wasm32 bin
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) $(MAKE) -C build/wasm32/gcc-preliminary
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) $(MAKE) -C build/wasm32/gcc-preliminary install
	cp wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc.a wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc_eh.a
	cp wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc.a wasm32-unknown-none/lib/gcc/wasm32-unknown-none/11.0.0/libgcc_s.a
	(cd bin; ln -sf ../wasm32-unknown-none/bin/wasm32-unknown-none-* .)
	touch $@
built/wasm32/glibc: build/wasm32/glibc/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/glibc
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/glibc install
	touch $@
built/wasm32/gcc: build/wasm32/gcc/Makefile | built/wasm32
	$(MKDIR) build/wasm32/gcc/gcc
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gcc
	cp build/wasm32/gcc/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_eh.a
	cp build/wasm32/gcc/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_s.a
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gcc install
	touch $@
built/wasm32/ncurses: build/wasm32/ncurses/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/ncurses
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/ncurses install
	touch $@
built/wasm32/bash: build/wasm32/bash/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/bash
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/bash install
	touch $@
built/wasm32/coreutils: build/wasm32/coreutils/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/coreutils
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/coreutils install
	touch $@
# Emacs has a Makefile, so we configure it in the "built" step.
built/wasm32/emacs: build/wasm32/emacs built/wasm32/ncurses | built/wasm32
	(cd build/wasm32/emacs; sh autogen.sh; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ./configure --with-dumping=none --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --without-x --without-gnutls --without-modules --without-threads --without-x --without-libgmp --without-json --without-xft --without-all)
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/emacs
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/emacs install
	touch $@

tools/bin/%: tools/src/%.c lds/wasm32.cpp-lds.lds | bin
	gcc -Wall -g3 $< -o $@

tools/bin/%: tools/src/%.cc lds/wasm32.cpp-lds.lds | bin
	g++ -Wall -g3 $< -o $@

# wasm/ targets.
wasm/ld.wasm: wasm32-unknown-none/wasm32-unknown-none/lib/ld.so.1 tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect | wasm built/wasm32/glibc
	tools/bin/elf-to-wasm --library --dynamic $< > $@
wasm/libc.wasm: wasm32-unknown-none/wasm32-unknown-none/lib/libc.so tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect | wasm built/wasm32/glibc
	tools/bin/elf-to-wasm --library --dynamic $< > $@
wasm/libm.wasm: wasm32-unknown-none/wasm32-unknown-none/lib/libm.so tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect | wasm built/wasm32/glibc
	tools/bin/elf-to-wasm --library --dynamic $< > $@
wasm/libstdc++.wasm: wasm32-unknown-none/wasm32-unknown-none/lib/libstdc++.so tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect | wasm built/wasm32/gcc
	tools/bin/elf-to-wasm --library --dynamic $< > $@
wasm/libncurses.wasm: wasm32-unknown-none/wasm32-unknown-none/lib/libncurses.so tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect | wasm built/wasm32/ncurses
	tools/bin/elf-to-wasm --library --dynamic $< > $@
wasm/libdl.wasm: wasm32-unknown-none/wasm32-unknown-none/lib/libdl.so tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect | wasm built/wasm32/glibc
	tools/bin/elf-to-wasm --library --dynamic $< > $@
wasm/bash.wasm: wasm32-unknown-none/wasm32-unknown-none/bin/bash tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect | wasm built/wasm32/bash
	tools/bin/elf-to-wasm --executable --dynamic $< > $@
COREUTILS = echo true false
$(patsubst %,wasm/%.wasm,$(COREUTILS)): wasm/%.wasm: wasm32-unknown-none/wasm32-unknown-none/bin/% tools/bin/wasmrewrite tools/bin/wasmsect | wasm built/wasm32/coreutils
	tools/bin/elf-to-wasm --executable --dynamic $< > $@

# JSC->js substitution
js/wasm32-%.jsc.js: jsc/wasm32/%.jsc | js
	tools/bin/jsc wasm32-unknown-none < $< > $@
# asm- is the common prefix
js/wasm32-%.jsc.js: jsc/common/%.jsc | js
	tools/bin/jsc wasm32-unknown-none < $< > $@

# fixme: don't use a wildcard here.
jsc = $(wildcard jsc/wasm32/*.jsc) $(wildcard jsc/common/*.jsc)

# build the runtime JS
js/wasm32.js: js/wasm32-main.jsc.js js/wasm32-range.jsc.js js/wasm32-system.jsc.js js/wasm32-thinthin.jsc.js js/wasm32-boot.jsc.js
	echo "// autogenerated from $^, do not edit" > $@.new
	cat js/wasm32-range.jsc.js js/wasm32-system.jsc.js js/wasm32-thinthin.jsc.js js/wasm32-main.jsc.js js/wasm32-boot.jsc.js >> $@.new
	mv $@.new $@

# build-everything rules
built/all: built/wasm32/all built/common/all
	touch $@
built/wasm32/all: built/wasm32/binutils-gdb built/wasm32/gcc-preliminary built/wasm32/glibc built/wasm32/gcc built/wasm32/ncurses built/wasm32/bash built/wasm32/gdb
	touch $@
built/common/all: built/common/binaryen built/common/wabt
	touch $@

# pre-processed linker scripts
%.cpp-lds.lds: %.cpp-lds
	cpp < $< | egrep -v '^#' > $@

# how is this different from start-over! ?
clean!:
	rm -rf build built src wasm32-unknown-none

.SECONDARY: build/common/binaryen/Makefile build/common/wabt/Makefile build/wasm32/binutils-gdb/Makefile build/wasm32/gdb/Makefile build/wasm32/gcc-preliminary/Makefile build/wasm32/glibc/Makefile build/wasm32/gcc/Makefile build/wasm32/ncurses/Makefile build/wasm32/bash/Makefile build/wasm32/emacs
.PRECIOUS: test/wasm32/%

# Test framework
testsuite-dirs = $(wildcard testsuite/*)
test-dirs = $(patsubst testsuite/%,test/wasm32/%,$(testsuite-dirs))

$(test-dirs): test/wasm32/%: | testsuite/% test/wasm32 built/wasm32/glibc
	$(MKDIR) test/wasm32/$*
	cp -r testsuite/$*/* test/wasm32/$*/
	ln -sf ../../../testsuite/$* test/wasm32/$*/src

test/wasm32/%/test.mk: testsuite/% tools/bin/testsuite-make-fragment
	$(MKDIR) test/wasm32/$*
	tools/bin/testsuite-make-fragment testsuite/$*/ test/wasm32/$*/ $(patsubst testsuite/$*/%,%,$(wildcard testsuite/$*/*)) > $@

include $(patsubst %,%/test.mk,$(test-dirs))

run-all-tests!: $(patsubst testsuite/%,test/wasm32/%/status,$(wildcard testsuite/*)) wasm/libc.wasm wasm/libm.wasm wasm/ld.wasm wasm/libdl.wasm

# GitHub support
# Check out a subrepo
subrepos/%/checkout!:
	git submodule update --depth=1 --single-branch --init --recursive subrepos/$*

# install various packages on the GitHub VM:
github/install/file-slurp: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install cpanminus
	sudo cpanm File::Slurp
	touch $@
github/install/texinfo-bison-flex: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install texinfo bison flex
	touch $@
github/install/gcc-dependencies: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install libgmp-dev libmpfr-dev libmpc-dev
	touch $@
github/install/dejagnu: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install dejagnu
	touch $@
github/install/gettext: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install gettext
github/install/autopoint: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install autopoint
github/install/gperf: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install gperf
github/install/binfmt_misc: | github/install
	$(MKDIR) $@
github/install/binfmt_misc/elf32-wasm32: | github/install github/install/binfmt_misc
	sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc || true
	echo ':elf32-wasm32:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x57\x41:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:'"$(PWD)/tools/bin/elf32-wasm32"':' | sudo tee /proc/sys/fs/binfmt_misc/register
github/install/binfmt_misc/wasm: | github/install github/install/binfmt_misc
	sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc || true
	echo ':wasm:M::\x00asm\x01\x00\x00\x00:\xff\xff\xff\xff\xff\xff\xff\xff:'"$(PWD)/tools/bin/wasm"':' | sudo tee /proc/sys/fs/binfmt_misc/register

# Build the various artifacts
artifact-wasm32.js!: | github/install/file-slurp js/wasm32.js artifact-timestamp artifacts
	cat js/wasm32.js > artifacts/wasm32.js
	$(MAKE) artifact-push!
artifact-binutils!: | github/install/texinfo-bison-flex subrepos/binutils-gdb/checkout! artifact-timestamp artifacts
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/binutils-gdb
	tar cf artifacts/binutils.tar built wasm32-unknown-none -N ./artifact-timestamp
	$(MAKE) artifact-push!
artifact-gcc-preliminary!: | github/install/texinfo-bison-flex subrepos/gcc/checkout! artifacts extracted/artifacts/binutils.tar github/install/gcc-dependencies
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/gcc-preliminary
	tar cf artifacts/gcc-preliminary.tar built wasm32-unknown-none -N ./artifact-timestamp
	$(MAKE) artifact-push!
artifact-glibc!: | github/install/texinfo-bison-flex subrepos/glibc/checkout! artifacts extracted/artifacts/binutils.tar extracted/artifacts/gcc-preliminary.tar
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/glibc
	tar cf artifacts/glibc.tar built wasm32-unknown-none -N ./artifact-timestamp
	$(MAKE) wasm/ld.wasm wasm/libc.wasm wasm/libm.wasm wasm/libdl.wasm
	cp wasm/ld.wasm wasm/libc.wasm wasm/libm.wasm wasm/libdl.wasm artifacts/
	$(MAKE) artifact-push!
artifact-gcc!: | github/install/texinfo-bison-flex subrepos/gcc/checkout! artifacts extracted/artifacts/binutils.tar extracted/artifacts/gcc-preliminary.tar extracted/artifacts/glibc.tar github/install/gcc-dependencies
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/gcc
	tar cf artifacts/gcc.tar built wasm32-unknown-none -N ./artifact-timestamp
	$(MAKE) wasm/libstdc++.wasm
	cp wasm/libstdc++.wasm artifacts/
	$(MAKE) artifact-push!
artifact-ncurses!: | subrepos/ncurses/checkout! artifacts extracted/artifacts/binutils.tar extracted/artifacts/gcc-preliminary.tar extracted/artifacts/glibc.tar extracted/artifacts/gcc.tar github/install/gcc-dependencies
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/ncurses
	$(MAKE) wasm/libncurses.wasm
	tar cf artifacts/ncurses.tar built wasm32-unknown-none -N ./artifact-timestamp
	cp wasm/libncurses.wasm artifacts/
	$(MAKE) artifact-push!

artifact-bash!: | subrepos/bash/checkout! artifacts extracted/artifacts/binutils.tar extracted/artifacts/gcc-preliminary.tar extracted/artifacts/glibc.tar extracted/artifacts/gcc.tar extracted/artifacts/ncurses.tar github/install/texinfo-bison-flex github/install/gcc-dependencies github/install/gettext
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/bash wasm/bash.wasm
	cp wasm/bash.wasm artifacts/
	$(MAKE) artifact-push!

artifact-coreutils!: | subrepos/coreutils/checkout! artifacts extracted/artifacts/binutils.tar extracted/artifacts/gcc-preliminary.tar extracted/artifacts/glibc.tar extracted/artifacts/gcc.tar extracted/artifacts/ncurses.tar github/install/texinfo-bison-flex github/install/gcc-dependencies github/install/gettext github/install/gperf github/install/autopoint github/install/binfmt_misc/elf32-wasm32 github/install/binfmt_misc/wasm github/install/file-slurp js/wasm32.js
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/coreutils $(patsubst %,wasm/%.wasm,$(COREUTILS))
	cp $(patsubst %,wasm/%.wasm,$(COREUTILS)) artifacts/
	$(MAKE) artifact-push!

# Create a file to be shipped
ship/%.wasm: artifacts/%.wasm | ship
	cat $< > $@
# Retrieve asset list (and cache it)
github/assets/%.json: | github/release/list! github/assets
	if [ -e "github/release/\"$*\"" ]; then \
	    curl -sSL "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets" > $@; \
	else \
	    echo "[]" > $@; \
	fi

# Ship assets
ship-%!: ship/libc.wasm ship/ld.wasm ship/libncurses.wasm ship/bash.wasm github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

github/release/list!: | github/release
	curl -sSL https://api.github.com/repos/$$GITHUB_REPOSITORY/releases | jq '.[] | [(.).tag_name,(.).id] | .[]' | while read tag; do read id; echo $$id > github/release/$$tag; done
	ls -l github/release/

github/check-release!: | github
	last_release_date="$$(curl https://api.github.com/repos/$$GITHUB_REPOSITORY/releases | jq "[.[] | .created_at] | sort[-1]" | cut -c 2-11)"; \
	this_release_date="$$(date --iso)"; \
	if [ "$$this_release_date" != "$$last_release_date" ]; then \
	    node ./github/release.js $$this_release_date $$last_release_date > github/release.json; \
	    curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases" --data '@github/release.json'; \
	    sleep 1m; \
	    $(MAKE) ship-$$this_release_date!; \
	fi; \
	true

github/latest: | github
	$(MKDIR) $@

# objdump debug rule
%.wasm.wasm-objdump: %.wasm built/common/wabt
	./bin/wasm-objdump -dhx $< > $@

# wasm-to-wasm optimization rules
%.wasm.{O}.wasm: %.wasm built/common/binaryen
	./bin/wasm-opt $< -o $@
%.wasm.{O4}.wasm: %.wasm built/common/binaryen
	./bin/wasm-opt -O4 $< -o $@
%.wasm.{Oz}.wasm: %.wasm built/common/binaryen
	./bin/wasm-opt -Oz $< -o $@

# C -> exe/o/s rules. These take special flags as part of the filename:
#  foo.{nostdlib}.c: a C file to be compiled without stdlibs
#  foo.c.{static}.exe: an executable compiled statically, from foo.c
cflags = $(shell tools/bin/cflags $(1) $(2))

test/wasm32/%.c.exe: test/wasm32/%.c
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc $(call cflags,$*.c,$(dir testsuite/$*)) $< -o $@

test/wasm32/%.c.{static}.exe: test/wasm32/%.c
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc $(call cflags,$*.c,$(dir testsuite/$*)) -Wl,-Map,test/wasm32/$*.c.{static}.map -static $< -o $@

test/wasm32/%.c.{debug}.exe: test/wasm32/%.c
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc $(call cflags,$*.c.{debug},$(dir testsuite/$*)) -Wl,-Map,test/wasm32/$*.c.{static}.map $< -o $@ -lstdc++ -lm

test/wasm32/%.c.{static}.exe.wasm.out.exp: test/wasm32/%.c.exe.wasm.out.exp
	cat $< > $@

test/wasm32/%.c.{static}.exe.wasm.out.exp.pl: test/wasm32/%.c.exe.wasm.out.exp.pl
	cat $< > $@

test/wasm32/%.cc.{static}.exe: test/wasm32/%.cc
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-g++ $(call cflags,$*.c,$(dir testsuite/$*)) -Wl,-Map,test/wasm32/$*.cc.{static}.map $< -lstdc++ -o $@

test/wasm32/%.cc.{static}.exe.wasm.out.exp: test/wasm32/%.cc.exe.wasm.out.exp
	cat $< > $@

test/wasm32/%.cc.{static}.exe.wasm.out.exp.pl: test/wasm32/%.cc.exe.wasm.out.exp.pl
	cat $< > $@

# exe -> wasm rule
test/wasm32/%.exe.wasm: test/wasm32/%.exe tools/bin/elf-to-wasm
	tools/bin/elf-to-wasm --executable $< > $@

# wasm output rule
test/wasm32/%.wasm.out: test/wasm32/%.wasm
	JS=$(JS) WASMDIR=$(PWD) $(JS) $(PWD)/js/wasm32.js $< > $@ 2> test/wasm32/$*.wasm.err || true
	@echo "STDOUT"
	@cat $@
	@echo "STDERR"
	@cat test/wasm32/$*.wasm.err

test/wasm32/%.gdb.out: test/wasm32/%.gdb
	JS=$(JS) WASMDIR=$(PWD) $(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-gdb --command=$< --batch > $@

comma = ,
car = $(firstword $(1))
cdr = $(wordlist 2,$(words $(1)),$(1))
multideps = $(addprefix $(2)$(call car,$(1)),$(subst $(comma), ,$(call cdr,$(1))))

test/wasm32/%].exe: $$(subst ./,,$$(call multideps,$$(subst [, ,./$$*),test/wasm32/))
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-$(if $(filter %.cc.o %.cc.s.o,$^),g++,gcc) $^ -o $@

test/wasm32/%].{static}.exe: $$(subst ./,,$$(call multideps,$$(subst [, ,./$$*),test/wasm32/))
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-$(if $(filter %.cc.o %.cc.s.o,$^),g++,gcc) -static $^ -o $@

test/wasm32/%.o.exe: test/wasm32/%.o
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc $< -o $@

test/wasm32/%.cc.exe: test/wasm32/%.cc
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-g++ $< -o $@

test/wasm32/%.c.s: test/wasm32/%.c
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc -S $< -o $@

test/wasm32/%.S.o: test/wasm32/%.S
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc $(call cflags,$*,$(dir testsuite/$*)) -c $< -o $@

test/wasm32/%.c.o: test/wasm32/%.c
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc $(call cflags,$*,$(dir testsuite/$*)) -c $< -o $@

test/wasm32/%.c.i: test/wasm32/%.c
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc $(call cflags,$*,$(dir testsuite/$*)) -E $< -o $@

test/wasm32/%.cc.i: test/wasm32/%.cc
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-g++ $(call cflags,$*,$(dir testsuite/$*)) -E $< -o $@

test/wasm32/%.cc.s: test/wasm32/%.cc
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-g++ -S $< -o $@

test/wasm32/%.cc.o: test/wasm32/%.cc
	$(PWD)/wasm32-unknown-none/bin/wasm32-unknown-none-g++ -c $< -o $@

test/wasm32/%.exp.cmp: test/wasm32/%.exp.pl test/wasm32/%
	perl $^ > $@

test/wasm32/%.c.{static}.exe.wasm.out.exp: test/wasm32/%.c.exe.wasm.out.exp
	cat $< > $@

test/wasm32/%.c.{static}.exe.wasm.out.exp.pl: test/wasm32/%.c.exe.wasm.out.exp.pl
	cat $< > $@

test/%.exp.cmp: test/%.exp test/%
	diff -u $^ > $@ || (cat $@; false)

artifacts: | .github-init
	$(MKDIR) $@

.github-init:
	bash github/artifact-init
	touch $@

# Extract an artifact
extracted/%.tar: %.tar | extracted
	$(MKDIR) $(dir extracted/$*)
	tar xf $*.tar
	touch $@

artifacts/%: | artifacts
	bash github/dl-artifact $*
	mv $@.new/$* $@
	rm -rf $@.new
	ls -l $@

artifact-timestamp:
	touch $@

artifact-push!:
	(cd artifacts; for file in *; do if [ "$$file" -nt ../artifact-timestamp ]; then name=$$(basename "$$file"); (cd ..; bash github/ul-artifact "$$name" "artifacts/$$name"); fi; done)
	@echo "(Do not be confused by the size stated above; it's the compressed size)"

%.{dejagnu}!: github/install/file-slurp github/install/texinfo-bison-flex github/install/gcc-dependencies github/install/dejagnu build
	$(MAKE) extracted/artifacts/binutils.tar
	$(MAKE) extracted/artifacts/gcc-preliminary.tar
	$(MAKE) extracted/artifacts/gcc.tar
	$(MAKE) extracted/artifacts/glibc.tar
	$(MAKE) tools/bin/wasmrewrite > /dev/null
	$(MAKE) tools/bin/wasmsect > /dev/null
	$(MAKE) artifacts/jsshell-linux-x86_64.zip
	$(MAKE) github/install/binfmt_misc/wasm github/install/binfmt_misc/elf32-wasm32
	$(MAKE) js/wasm32.js
	$(MAKE) artifacts/libc.wasm artifacts/ld.wasm artifacts/libm.wasm
	$(MKDIR) wasm
	cp artifacts/*.wasm wasm
	$(MAKE) artifact-timestamp
	$(MAKE) artifacts
	unzip artifacts/jsshell-linux-x86_64.zip -d bin
	$(MKDIR) build/wasm32/gcc/gcc/testsuite/gcc
	(cd build/wasm32/gcc/gcc; make site.exp && cp site.exp testsuite && cp site.exp testsuite/gcc)
#	(cd src/gcc/gcc/testsuite/; find -type d | while read DIR; do cd $DIR; ls * | shuf | head -n +128 | egrep -v '*.dg' | while read; do rm $REPLY; done; done) || true
	(cd src/gcc/gcc/testsuite; find -type f | egrep '\.[cisS]$$' | xargs md5sum | egrep -v "^$$PREFIX" | while read shasum path; do rm -f $$path; done)
	(cd build/wasm32/gcc/gcc/testsuite/gcc; WASMDIR=$(PWD) JS=$(PWD)/bin/js srcdir=$(PWD)/src/gcc/gcc runtest -a --tool gcc $*) | tee $(notdir $*).out || true
	cp $(notdir $*).out artifacts/$(notdir $*)-$$PREFIX.out
	cp build/wasm32/gcc/gcc/testsuite/gcc/gcc.log artifacts/$(notdir $*)-$$PREFIX.log
	grep FAIL build/wasm32/gcc/gcc/testsuite/gcc/gcc.log > artifacts/$(notdir $*)-$$PREFIX-short.log || true
	$(MAKE) artifact-push!

%.{dejanew}!: github/install/file-slurp github/install/texinfo-bison-flex github/install/gcc-dependencies github/install/dejagnu
	$(MAKE) extracted/artifacts/binutils.tar
	$(MAKE) extracted/artifacts/gcc-preliminary.tar
	$(MAKE) extracted/artifacts/gcc.tar
	$(MAKE) extracted/artifacts/glibc.tar
	$(MAKE) tools/bin/wasmrewrite > /dev/null
	$(MAKE) tools/bin/wasmsect > /dev/null
	$(MAKE) artifacts/jsshell-linux-x86_64.zip
	unzip artifacts/jsshell-linux-x86_64.zip -d bin
	$(MAKE) github/install/binfmt_misc/wasm github/install/binfmt_misc/elf32-wasm32
	$(MAKE) js/wasm32.js
	$(MAKE) artifacts/libc.wasm artifacts/ld.wasm artifacts/libm.wasm
	$(MKDIR) wasm
	$(MAKE) subrepos/gcc/checkout!
	$(MAKE) src/gcc
	cp artifacts/*.wasm wasm
	$(MAKE) artifact-timestamp
	$(MAKE) artifacts
	$(MAKE) build/wasm32/gcc-testsuite/$*.{dejagnu}.tar
	cp build/wasm32/gcc-testsuite/$*.{dejagnu}.tar artifacts/
	$(MAKE) artifact-push!

binutils-test!: github/install/texinfo-bison-flex github/install/dejagnu
	$(MAKE) subrepos/binutils-gdb/checkout!
	$(MAKE) built/wasm32/binutils-gdb
	$(MAKE) artifacts
	$(MAKE) artifact-timestamp
	$(MAKE) -k -C build/wasm32/binutils-gdb check || true
	find build/wasm32/binutils-gdb -name '*.log' | egrep -v 'config\.log$$' | while read; do cp $REPLY artifacts/; done
	$(MAKE) artifact-push!

gcc-testsuite!: build/wasm32/gcc-testsuite/gcc.c-torture/compile/compile.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.c-torture/execute/execute.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.dg/dg.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.dg/weak/weak.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.c-torture/execute/ieee/ieee.exp.{dejagnu}.tar

clean: clean!
all: built/all

.PHONY: %! clean all
.SUFFIXES:
