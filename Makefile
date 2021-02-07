# $(MKDIR) command
MKDIR ?= mkdir -p
# $(PWD) is the top-level directory. No recursion here (except for subrepos).
PWD ?= $(shell pwd)
OPT_NATIVE ?= "-Os"
OPT_WASM ?= "-O2"
WASMDIR ?= $(PWD)
JS ?= $$JS

.SECONDEXPANSION:
# This has to be the first rule: build everything, currently scattered over too many directories.

all!: lds/wasm32.cpp-lds.lds built/all js/wasm32.js wasm/libc.wasm wasm/ld.wasm wasm/libm.wasm wasm/libstdc++.wasm tools/bin/wasmrewrite tools/bin/wasmsect tools/bin/bitpush wasm/libdl.wasm wasm/libncurses.wasm wasm/bash.wasm

# Top-level directories to be created automatically and deleted when cleaning. Keep them in sync!
bin build built extracted github/assets github/release github/install install js lib ship src stamp test wasm:
	$(MKDIR) $@

start-over!:
	rm -rf artifacts bin build built daily extracted github/assets github/release github/install tools/bin/wasmrewrite tools/bin/wasmsect install js lib ship src stamp test wasm wasm32-unknown-none lds/*.cpp-lds.lds

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
build/wasm32/binutils-gdb build/wasm32/gcc-preliminary build/wasm32/gdb build/wasm32/glibc build/wasm32/gcc build/wasm32/gcc-testsuite build/wasm32/gcc-testsuite-tar build/wasm32/gcc-testsuite-make build/wasm32/ncurses build/wasm32/bash build/wasm32/python build/wasm32/native-binutils build/wasm32/gmp: | build/wasm32
	$(MKDIR) $@
build/common/binaryen build/common/wabt build/common/python: | build/common
	$(MKDIR) $@

# binutils-gdb requires source tree modification, so we copy the source.
src/wasm32/binutils-gdb: | src/wasm32
	$(MKDIR) $@T
	(cd subrepos/binutils-gdb; tar c --exclude .git .) | (cd $@T; tar x)
	mv $@T $@

# binutils-gdb requires source tree modification, so we copy the source.
src/wasm32/native-binutils: | src/wasm32
	$(MKDIR) $@T
	(cd subrepos/binutils-gdb; tar c --exclude .git .) | (cd $@T; tar x)
	mv $@T $@

# These repos do not require source tree modification.
good-repos = gcc glibc ncurses bash wabt binaryen coreutils perl zsh python gmp

$(patsubst %,src/%,$(good-repos)): src/%: | src
	test -L $@ || ln -sf ../subrepos/$* $@

# Emacs is _built_ in the source directory, so copy that.
build/wasm32/emacs: | build/wasm32
	test -d $@ || ($(MKDIR) $@T; (cd subrepos/emacs; tar c --exclude .git .) | (cd $@T; tar x); mv $@T $@)

# Emacs is _built_ in the source directory, so copy that.
build/wasm32/emacs-native-comp: | build/wasm32
	test -d $@ || ($(MKDIR) $@T; (cd subrepos/emacs-native-comp; tar c --exclude .git .) | (cd $@T; tar x); mv $@T $@)

# Zsh is spe-shell.
build/wasm32/zsh: | build/wasm32
	test -d $@ || ($(MKDIR) $@T; (cd subrepos/zsh; tar c --exclude .git .) | (cd $@T; tar x); mv $@T $@)

# Coreutils requires its own destructive bootstrap script
build/wasm32/coreutils: | build/wasm32
	test -d $@ || ($(MKDIR) $@T; (cd subrepos/coreutils; tar c --exclude .git .) | (cd $@T; tar x); mv $@T $@)

# We use /Makefile as a sentinel for whether the configure/cmake script has run.
build/common/binaryen/Makefile: | build/common/binaryen src/binaryen
	(cd build/common/binaryen; cmake ../../../src/binaryen -DCMAKE_INSTALL_PREFIX=$(PWD)/common -DCMAKE_BUILD_TYPE=Debug)

build/common/python/Makefile: | build/common/python src/python
	(cd build/common/python; ../../../src/python/configure)

build/common/wabt/Makefile: | src/wabt build/common/wabt
	(cd build/common/wabt; cmake ../../../src/wabt -DBUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$(PWD)/common -DCMAKE_BUILD_TYPE=Debug)

build/wasm32/binutils-gdb/Makefile: | src/wasm32/binutils-gdb build/wasm32/binutils-gdb
	(cd src/wasm32/binutils-gdb/gas; aclocal; automake; autoreconf)
	(cd build/wasm32/binutils-gdb; ../../../src/wasm32/binutils-gdb/configure --target=wasm32-unknown-none --enable-debug --prefix=$(PWD)/wasm32-unknown-none CFLAGS=$(OPT_NATIVE))

build/wasm32/native-binutils/Makefile: | src/wasm32/native-binutils build/wasm32/native-binutils
	(cd src/wasm32/native-binutils/gas; aclocal; automake; autoreconf)
	(cd build/wasm32/native-binutils; ../../../src/wasm32/native-binutils/configure --build=x86_64-pc-linux-gnu --target=wasm32-unknown-none --host=wasm32-unknown-none --enable-debug --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none CFLAGS=$(OPT_WASM))

build/wasm32/gdb/Makefile: | src/wasm32/binutils-gdb build/wasm32/gdb
	(cd build/wasm32/gdb; ../../../src/wasm32/binutils-gdb/configure --target=wasm32-unknown-none --enable-debug --prefix=$(PWD)/wasm32-unknown-none CFLAGS=$(OPT_NATIVE))

# Note that src/gcc is shared between the gcc-preliminary and gcc targets.

build/wasm32/gcc-preliminary/Makefile: | built/wasm32/binutils-gdb build/wasm32/gcc-preliminary src/gcc
	(cd build/wasm32/gcc-preliminary; CFLAGS=$(OPT_NATIVE) CXXFLAGS=$(OPT_NATIVE) ../../../src/gcc/configure --enable-optimize=$(OPT_NATIVE) --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --enable-languages=c --disable-libssp --prefix=$(PWD)/wasm32-unknown-none)

build/wasm32/glibc/Makefile: | built/wasm32/gcc-preliminary src/glibc build/wasm32/glibc
	(cd build/wasm32/glibc; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/glibc/configure CFLAGS="-fPIC -Os -Wno-error=missing-attributes" --enable-optimize=$(OPT_NATIVE) --host=wasm32-unknown-none --target=wasm32-unknown-none --enable-hacker-mode --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)

build/wasm32/gcc/Makefile: | built/wasm32/glibc src/gcc build/wasm32/gcc
	(cd build/wasm32/gcc; ../../../src/gcc/configure CFLAGS="-Os" CXXFLAGS="-Os" --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --disable-libssp --prefix=$(PWD)/wasm32-unknown-none)

build/wasm32/native-gcc/Makefile: | built/wasm32/glibc src/gcc build/wasm32/native-gcc
	(cd build/wasm32/native-gcc; ../../../src/gcc/configure CFLAGS="-Os" CXXFLAGS="-Os" --host=wasm32-unknown-none --build=x86_64-pc-linux-gnu --target=wasm32-unknown-none --disable-libatomic --disable-libgomp --disable-libquadmath --enable-explicit-exception-frame-registration --disable-libssp --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)

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
	echo 'set tmpdir $(PWD)/build/wasm32/gcc-testsuite' >> $@
	echo 'set srcdir "$${srcdir}/testsuite"' >> $@

build/wasm32/gcc-testsuite-make/%.{dejagnu}.mk: | build/wasm32/gcc-testsuite/site.exp
	$(MKDIR) $(dir $@)
	> $@
	for file in $$(cd src/gcc/gcc/testsuite/$(dir $*); find -type f | egrep '\.([cSi])$$' | sed -e 's/^\.\///g' | egrep -v '\/'); do \
	    echo "build/wasm32/gcc-testsuite/$(dir $*)$$file.{dejagnu}/okay:" >> $@; \
	    echo "\t(mkdir -p build/wasm32/gcc-testsuite/$(dir $*)$$file.{dejagnu}/; cp src/gcc/gcc/testsuite/$(dir $*)$$file build/wasm32/gcc-testsuite/$(dir $*)$$file.{dejagnu}/; cd build/wasm32/gcc-testsuite; testtotest=$(dir $*)$$file PATH=$(PWD)/bin:$(PWD)/wasm32-unknown-none/bin:$$PATH runtest --outdir $(dir $*)$$file.{dejagnu}/ --tool gcc $* > /dev/null 2> /dev/null) || true" >> $@; \
	    echo "\t! egrep -q '^# of unexpected|RuntimeError' build/wasm32/gcc-testsuite/$(dir $*)$$file.{dejagnu}/gcc.log && touch build/wasm32/gcc-testsuite/$(dir $*)$$file.{dejagnu}/okay || (echo src/gcc/gcc/testsuite/$(dir $*)$$file; false)" >> $@; \
	    echo >> $@; \
	    all="$$all build/wasm32/gcc-testsuite/$(dir $*)$$file.{dejagnu}/okay"; \
	done; \
        echo "build/wasm32/gcc-testsuite/$*.all: $$all" >> $@

build/wasm32/gcc-testsuite/gcc.c-torture/execute/%: build/wasm32/gcc-testsuite-make/gcc.c-torture/execute/execute.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)gcc.log > /dev/stderr; false)

build/wasm32/gcc-testsuite/gcc.c-torture/execute/ieee/%: build/wasm32/gcc-testsuite-make/gcc.c-torture/execute/ieee/ieee.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)gcc.log > /dev/stderr; false)

build/wasm32/gcc-testsuite/gcc.dg/%: build/wasm32/gcc-testsuite-make/gcc.dg/dg.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)gcc.log > /dev/stderr; false)

build/wasm32/gcc-testsuite/gcc.dg/debug/dwarf2/%: build/wasm32/gcc-testsuite-make/gcc.dg/debug/dwarf2/dwarf2.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)gcc.log > /dev/stderr; false)

build/wasm32/gcc-testsuite/gcc.dg/tls/%: build/wasm32/gcc-testsuite-make/gcc.dg/tls/tls.exp.{dejagnu}.mk
	make -f $< $@ || (cat $(dir $@)gcc.log > /dev/stderr; false)

build/wasm32/gcc-testsuite-tar/%.{dejagnu}.tar: build/wasm32/gcc-testsuite-make/%.{dejagnu}.mk build/wasm32/gcc-testsuite/site.exp | build/wasm32/gcc-testsuite-tar
	$(MKDIR) build/wasm32/gcc-testsuite-tar/$(dir $*)
	$(MKDIR) build/wasm32/gcc-testsuite/$(dir $*)
	$(MAKE) -f $< build/wasm32/gcc-testsuite/$*.all || true
	tar cf $@ build/wasm32/gcc-testsuite/$(dir $*)

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

build/wasm32/gcc-testsuite/problem.tar:
	$(MAKE) -k $(GCC_PROBLEM_TESTS:%=build/wasm32/gcc-testsuite/%.{dejagnu}/okay) || true
	tar cf $@ build/wasm32/gcc-testsuite

problem!: | subrepos/gcc/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz bin/js install/dejagnu install/gcc-dependencies install/texinfo-bison-flex install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm js/wasm32.js
	$(MAKE) extracted/daily/gcc-preliminary.tar.gz
	$(MAKE) extracted/daily/gcc.tar.gz
	$(MAKE) wasm wasm/ld.wasm wasm/libc.wasm wasm/libdl.wasm wasm/libcrypt.wasm wasm/libutil.wasm wasm/libm.wasm wasm/libstdc++.wasm
	$(MAKE) artifacts artifact-timestamp
	$(MKDIR) build/wasm32/gcc/gcc/testsuite/gcc
	JS=$(PWD)/bin/js WASMDIR=$(PWD) $(MAKE) build/wasm32/gcc-testsuite/problem.tar
	cp build/wasm32/gcc-testsuite/problem.tar artifacts
	$(MAKE) artifact-push!

# Trampolines are currently broken
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

gcc-testsuites!: $(patsubst %,build/wasm32/gcc-testsuite/%.{dejagnu}.tar,$(GCC_TESTSUITES)) | built/all

build/wasm32/ncurses/Makefile: | built/wasm32/gcc src/ncurses build/wasm32/ncurses
	(cd build/wasm32/ncurses; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/ncurses/configure --enable-optimize=$(OPT_ASMJS) --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --disable-stripping --with-shared)
	touch $@

build/wasm32/python/Makefile: | built/wasm32/gcc src/python build/wasm32/python
	(cd build/wasm32/python; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/python/configure --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --disable-ipv6 --with-ensurepip=no)
	touch $@

build/wasm32/bash/Makefile: | built/wasm32/ncurses src/bash build/wasm32/bash
	(cd build/wasm32/bash; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/bash/configure --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --without-bash-malloc)
	touch $@

build/wasm32/zsh/Makefile: | built/wasm32/ncurses src/zsh build/wasm32/zsh
	(cd build/wasm32/zsh; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH autoreconf -vif; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ./configure --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)
	touch $@

build/wasm32/coreutils/Makefile: | built/wasm32/ncurses src/coreutils build/wasm32/coreutils
	(cd build/wasm32/coreutils; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ./bootstrap --skip-po --no-git --gnulib-srcdir=$(PWD)/src/coreutils/gnulib; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ./configure  --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)
	touch $@

build/wasm32/perl: | src/perl wasm/libcrypt.wasm wasm/libutil.wasm
	$(MKDIR) $@
	(cd src/perl; tar c --exclude .git .) | (cd $@; tar x)

build/wasm32/perl/Makefile: | src/perl build/wasm32/perl built/wasm32/gcc wasm/libc.wasm wasm/libcrypt.wasm wasm/ld.wasm wasm/libutil.wasm wasm/libdl.wasm wasm/libm.wasm
	test -f build/wasm32/perl/config.sh && mv build/wasm32/perl/config.sh build/wasm32/perl/config.sh.old || true
	touch build/wasm32/perl/config.sh
	find build/wasm32/perl -type d | while read REPLY; do (cd $$REPLY; $(PWD)/tools/bin/dotdir > .dir); done
	(cd build/wasm32/perl; PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH sh ./Configure -der -Uversiononly -Uusemymalloc -Dar=wasm32-unknown-none-ar -Dcc=wasm32-unknown-none-gcc -Doptimize="-O3 -fno-strict-aliasing" -Dincpth='$(PWD)/wasm32-unknown-none/lib/gcc/wasm32-unknown-none/8.0.0/include $(PWD)/wasm32-unknown-none/lib/gcc/wasm32-unknown-none/8.0.0/include-fixed $(PWD)/wasm32-unknown-none/lib/gcc/wasm32-unknown-none/8.0.0/../../../../wasm32-unknown-none/include' -Dlibpth='$(PWD)/wasm32-unknown-none/lib/gcc/wasm32-unknown-none/8.0.0/include-fixed $(PWD)/wasm32-unknown-none/lib/gcc/wasm32-unknown-none/8.0.0/../../../../wasm32-unknown-none/lib' -Dcccdlflags='-fPIC -Wl,--shared -shared' -Dlddlflags='-Wl,--shared -shared' -Dccdlflags='-Wl,-E'  -Dloclibpth=' ' -Dglibpth=' ' -Dplibpth=' ' -Dusedl -Dlibs='-ldl -lm -lcrypt -lutil' -Dd_u32align=define -Dusedevel -Darchname='wasm32' -Dprefix='$(PWD)/wasm32-unknown-none/wasm32-unknown-none')
	touch $@

build/wasm32/gmp/Makefile: | src/gmp build/wasm32/gmp built/wasm32/gcc
	(cd build/wasm32/gmp; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ../../../src/gmp/configure --host=wasm32-unknown-none --build=x86_64-pc-linux-gnu --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none)

built/wasm32/python: build/wasm32/python/Makefile
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/python
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/python install
	touch $@


built/wasm32/miniperl: build/wasm32/perl/Makefile | install/binfmt_misc/elf32-wasm32
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/perl miniperl
	cp build/wasm32/perl/miniperl wasm32-unknown-none/wasm32-unknown-none/bin/miniperl
	touch $@

built/wasm32/perl: built/wasm32/miniperl build/wasm32/perl/Makefile | install/binfmt_misc/elf32-wasm32
	find build/wasm32/perl -type d | while read REPLY; do (cd $$REPLY; $(PWD)/tools/bin/dotdir > .dir); done
	PERL_CORE=1 PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/perl < /dev/null
	PERL_CORE=1 PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) install -C build/wasm32/perl < /dev/null
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

built/common/python: build/common/python/Makefile | built/common bin
	$(MAKE) -C build/common/python
	sudo $(MAKE) -C build/common/python install
	touch $@

built/wasm32/gmp: build/wasm32/gmp/Makefile | bin built/wasm32
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gmp
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gmp install
	touch $@

built/wasm32/binutils-gdb: build/wasm32/binutils-gdb/Makefile | bin built/wasm32
	$(MAKE) -C build/wasm32/binutils-gdb
	$(MAKE) -C build/wasm32/binutils-gdb install
	(cd bin; ln -sf ../wasm32-unknown-none/bin/wasm32-unknown-none-* .)
	touch $@

built/wasm32/native-binutils: build/wasm32/native-binutils/Makefile | bin built/wasm32
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/native-binutils
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/native-binutils install
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

built/wasm32/gcc-preliminary: | install/texinfo-bison-flex
built/wasm32/gcc: | install/texinfo-bison-flex
built/wasm32/binutils-gdb: | install/texinfo-bison-flex
built/wasm32/native-binutils: | install/texinfo-bison-flex
built/wasm32/glibc: | install/texinfo-bison-flex
built/wasm32/ncurses: | install/texinfo-bison-flex
built/wasm32/bash: | install/texinfo-bison-flex
built/wasm32/miniperl: | install/texinfo-bison-flex
built/wasm32/perl: | install/texinfo-bison-flex
built/wasm32/python: | install/texinfo-bison-flex
built/wasm32/zsh: | install/texinfo-bison-flex
built/wasm32/coreutils: | install/texinfo-bison-flex

built/wasm32/gcc-preliminary: | install/gcc-dependencies
built/wasm32/gcc: | install/gcc-dependencies
built/wasm32/binutils-gdb: | install/gcc-dependencies
built/wasm32/native-binutils: | install/gcc-dependencies
built/wasm32/glibc: | install/gcc-dependencies
built/wasm32/ncurses: | install/gcc-dependencies
built/wasm32/bash: | install/gcc-dependencies
built/wasm32/miniperl: | install/gcc-dependencies
built/wasm32/perl: | install/gcc-dependencies
built/wasm32/zsh: | install/gcc-dependencies
built/wasm32/coreutils: | install/gcc-dependencies
built/wasm32/python: | install/gcc-dependencies

built/wasm32/gcc: build/wasm32/gcc/Makefile | built/wasm32
	$(MKDIR) build/wasm32/gcc/gcc
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gcc
	cp build/wasm32/gcc/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_eh.a
	cp build/wasm32/gcc/gcc/libgcc.a build/wasm32/gcc/gcc/libgcc_s.a
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/gcc install
	touch $@

built/wasm32/native-gcc: build/wasm32/native-gcc/Makefile | built/wasm32
	$(MKDIR) build/wasm32/native-gcc/gcc
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/native-gcc
	cp build/wasm32/native-gcc/gcc/libgcc.a build/wasm32/native-gcc/gcc/libgcc_eh.a
	cp build/wasm32/native-gcc/gcc/libgcc.a build/wasm32/native-gcc/gcc/libgcc_s.a
	PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/native-gcc install
	touch $@

built/wasm32/ncurses: build/wasm32/ncurses/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/ncurses
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/ncurses install
	touch $@

built/wasm32/bash: build/wasm32/bash/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/bash
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/bash install
	touch $@

built/wasm32/zsh: build/wasm32/zsh/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/zsh
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/zsh install
	touch $@

built/wasm32/coreutils: build/wasm32/coreutils/Makefile | built/wasm32
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) --trace -C build/wasm32/coreutils
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) --trace -C build/wasm32/coreutils install
	touch $@

# Emacs has a Makefile, so we configure it in the "built" step.
built/wasm32/emacs: build/wasm32/emacs built/wasm32/ncurses | built/wasm32
	(cd build/wasm32/emacs; sh autogen.sh; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ./configure --with-dumping=none --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --without-x --without-gnutls --without-modules --without-threads --without-x --without-libgmp --without-json --without-xft --without-all)
	find build/wasm32/emacs -type d | while read REPLY; do (cd $$REPLY; $(PWD)/tools/bin/dotdir > .dir); done
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/emacs
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/emacs install
	touch $@

# Emacs has a Makefile, so we configure it in the "built" step.
built/wasm32/emacs-native-comp: build/wasm32/emacs-native-comp built/wasm32/ncurses built/wasm32/gmp | built/wasm32
	(cd build/wasm32/emacs-native-comp; sh autogen.sh; CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH ./configure --with-dumping=pdumper --build=x86_64-pc-linux-gnu --host=wasm32-unknown-none --prefix=$(PWD)/wasm32-unknown-none/wasm32-unknown-none --without-x --without-gnutls --without-modules --without-threads --without-x --without-json --without-xft --without-all)
	find build/wasm32/emacs-native-comp -type d | while read REPLY; do (cd $$REPLY; $(PWD)/tools/bin/dotdir > .dir); done
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/emacs-native-comp
	CC=wasm32-unknown-none-gcc PATH=$(PWD)/wasm32-unknown-none/bin:$$PATH $(MAKE) -C build/wasm32/emacs-native-comp install
	touch $@

tools/bin/%: tools/src/%.c lds/wasm32.cpp-lds.lds | bin
	gcc -Wall -g3 $< -o $@

tools/bin/%: tools/src/%.cc lds/wasm32.cpp-lds.lds | bin
	g++ -Wall -g3 $< -o $@

# wasm/ targets.

wasm/ld.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/glibc | wasm
	tools/bin/elf-to-wasm --library --dynamic wasm32-unknown-none/wasm32-unknown-none/lib/ld.so.1 > $@

wasm/libc.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/glibc | wasm
	tools/bin/elf-to-wasm --library --dynamic wasm32-unknown-none/wasm32-unknown-none/lib/libc.so > $@

wasm/libm.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/glibc | wasm
	tools/bin/elf-to-wasm --library --dynamic wasm32-unknown-none/wasm32-unknown-none/lib/libm.so > $@

wasm/libcrypt.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/glibc | wasm
	tools/bin/elf-to-wasm --library --dynamic wasm32-unknown-none/wasm32-unknown-none/lib/libcrypt.so > $@

wasm/libutil.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/glibc | wasm
	tools/bin/elf-to-wasm --library --dynamic wasm32-unknown-none/wasm32-unknown-none/lib/libutil.so > $@

wasm/libstdc++.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/gcc | wasm
	tools/bin/elf-to-wasm --library --dynamic wasm32-unknown-none/wasm32-unknown-none/lib/libstdc++.so > $@

wasm/libncurses.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/ncurses | wasm
	tools/bin/elf-to-wasm --library --dynamic wasm32-unknown-none/wasm32-unknown-none/lib/libncurses.so > $@

wasm/libdl.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/glibc | wasm
	tools/bin/elf-to-wasm --library --dynamic wasm32-unknown-none/wasm32-unknown-none/lib/libdl.so > $@

wasm/bash.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/bash | wasm
	tools/bin/elf-to-wasm --executable --dynamic wasm32-unknown-none/wasm32-unknown-none/bin/bash > $@

wasm/zsh.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/zsh | wasm
	tools/bin/elf-to-wasm --executable --dynamic wasm32-unknown-none/wasm32-unknown-none/bin/zsh > $@

wasm/miniperl.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/miniperl | wasm
	tools/bin/elf-to-wasm --executable --dynamic wasm32-unknown-none/wasm32-unknown-none/bin/miniperl > $@

wasm/perl.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/perl | wasm
	tools/bin/elf-to-wasm --executable --dynamic wasm32-unknown-none/wasm32-unknown-none/bin/perl > $@

wasm/python.wasm: tools/bin/elf-to-wasm tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/python | wasm
	tools/bin/elf-to-wasm --executable --dynamic wasm32-unknown-none/wasm32-unknown-none/bin/python3 > $@

COREUTILS = echo true false
$(patsubst %,wasm/%.wasm,$(COREUTILS)): wasm/%.wasm: wasm32-unknown-none/wasm32-unknown-none/bin/% tools/bin/wasmrewrite tools/bin/wasmsect built/wasm32/coreutils | wasm
	tools/bin/elf-to-wasm --executable --dynamic $< > $@

ifeq (${GITHUB},1)
bin/js:
	wget --quiet http://ftp.mozilla.org/pub/firefox/nightly/latest-mozilla-central/jsshell-linux-x86_64.zip
	unzip jsshell-linux-x86_64.zip -d bin
endif

# JSC->js substitution
js/wasm32-%.jsc.js: jsc/wasm32/%.jsc | js install/file-slurp
	tools/bin/jsc wasm32-unknown-none < $< > $@
js/wasm32-%.jsc.js: jsc/common/%.jsc | js install/file-slurp

# fixme: don't use a wildcard here.
jsc = $(wildcard jsc/wasm32/*.jsc) $(wildcard jsc/common/*.jsc)

js/wasm32.js: install/file-slurp

# build the runtime JS
js/wasm32.js: jsc/wasm32/wasm32.jsc
	$(MKDIR) js
	echo "// autogenerated from $^, do not edit" > $@.new
	tools/bin/jsc wasm32-unknown-none < $< >> $@.new
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

.SECONDARY: build/common/binaryen/Makefile build/common/python/Makefile build/common/wabt/Makefile build/wasm32/binutils-gdb/Makefile build/wasm32/gdb/Makefile build/wasm32/gcc-preliminary/Makefile build/wasm32/glibc/Makefile build/wasm32/gcc/Makefile build/wasm32/native-gcc/Makefile build/wasm32/ncurses/Makefile build/wasm32/bash/Makefile build/wasm32/emacs build/wasm32/emacs-native-comp
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

run-all-tests!: | install/binfmt_misc/elf32-wasm32
run-all-tests!: | install/binfmt_misc/wasm
run-all-tests!: | tools/bin/elf-to-wasm
run-all-tests!: $(patsubst testsuite/%,test/wasm32/%/status,$(wildcard testsuite/*)) wasm/libc.wasm wasm/libm.wasm wasm/ld.wasm wasm/libdl.wasm

test/wasm32!: run-all-tests!

test!: test/wasm32!

# GitHub support
# Check out a subrepo
subrepos/%/checkout!:
	git submodule update --depth=1 --single-branch --init --recursive subrepos/$*

# install various packages on the GitHub VM:
github/install/file-slurp: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install cpanminus
	sudo cpanm File::Slurp
	touch $@

github/install/nroff: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install groff-base
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
	touch $@

github/install/sysctl/overcommit_memory: | github/install/sysctl
	echo 1 | sudo tee /proc/sys/vm/overcommit_memory
	touch $@

artifact-miniperl!: | install/gettext
artifact-perl!: | install/gettext
artifact-python!: | install/gettext
built/wasm32/bash: | install/gettext
built/wasm32/coreutils: | install/gettext
built/wasm32/coreutils: | install/gettext
built/wasm32/miniperl: | install/gettext
built/wasm32/perl: | install/gettext
built/wasm32/python: | install/gettext
built/wasm32/zsh: | install/gettext

github/install/autopoint: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install autopoint

github/install/gperf: | github/install
	tools/bin/locked --lockfile apt.lock sudo apt-get install gperf

github/install/binfmt_misc: | github/install
	$(MKDIR) $@

github/install/sysctl: | github/install
	$(MKDIR) $@

github/install/binfmt_misc/elf32-wasm32: | github/install github/install/binfmt_misc
	sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc || true
	echo ':elf32-wasm32:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x57\x41:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:'"$(PWD)/tools/bin/elf32-wasm32"':' | sudo tee /proc/sys/fs/binfmt_misc/register
	touch $@

github/install/binfmt_misc/wasm: | github/install github/install/binfmt_misc
	sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc || true
	echo ':wasm:M::\x00asm\x01\x00\x00\x00:\xff\xff\xff\xff\xff\xff\xff\xff:'"$(PWD)/tools/bin/wasm"':' | sudo tee /proc/sys/fs/binfmt_misc/register
	touch $@

ifeq (${GITHUB},1)
install/%: github/install/%
	$(MKDIR) install/$(dir $*)
	touch $@
else
install/%:
	$(MKDIR) install/$(dir $*)
	touch $@
endif

# Build the various artifacts
artifact-wasm32.js!: | js/wasm32.js artifacts
	$(MAKE) artifact-timestamp
	cat js/wasm32.js > artifacts/wasm32.js
	$(MAKE) artifact-push!

artifact-binutils!: | subrepos/binutils-gdb/checkout! artifacts
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/binutils-gdb
	tar cf artifacts/binutils.tar built wasm32-unknown-none -N ./artifact-timestamp
	$(MAKE) artifact-push!

artifact-gcc-preliminary!: | subrepos/gcc/checkout! artifacts extracted/artifacts/binutils.tar
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/gcc-preliminary
	tar cf artifacts/gcc-preliminary.tar built wasm32-unknown-none -N ./artifact-timestamp
	$(MAKE) artifact-push!

artifact-glibc!: | subrepos/glibc/checkout! artifacts extracted/artifacts/binutils.tar extracted/artifacts/gcc-preliminary.tar
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/glibc
	tar cf artifacts/glibc.tar built wasm32-unknown-none -N ./artifact-timestamp
	$(MAKE) wasm/ld.wasm wasm/libc.wasm wasm/libm.wasm wasm/libdl.wasm wasm/libutil.wasm wasm/libcrypt.wasm
	cp wasm/ld.wasm wasm/libc.wasm wasm/libm.wasm wasm/libdl.wasm wasm/libutil.wasm wasm/libcrypt.wasm artifacts/
	$(MAKE) artifact-push!

artifact-gcc!: | subrepos/gcc/checkout! artifacts extracted/artifacts/binutils.tar extracted/artifacts/gcc-preliminary.tar extracted/artifacts/glibc.tar
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/gcc
	tar cf artifacts/gcc.tar built wasm32-unknown-none -N ./artifact-timestamp
	tar cf artifacts/toolchain.tar built wasm32-unknown-none
	$(MAKE) wasm/libstdc++.wasm
	cp wasm/libstdc++.wasm artifacts/
	$(MAKE) artifact-push!

artifact-ncurses!: | subrepos/ncurses/checkout! artifacts extracted/artifacts/toolchain.tar
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/ncurses
	$(MAKE) wasm/libncurses.wasm
	tar cf artifacts/ncurses.tar built wasm32-unknown-none -N ./artifact-timestamp
	cp wasm/libncurses.wasm artifacts/
	$(MAKE) artifact-push!

artifact-bash!: | subrepos/bash/checkout! artifacts extracted/artifacts/toolchain.tar extracted/artifacts/ncurses.tar
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/bash wasm/bash.wasm
	cp wasm/bash.wasm artifacts/
	$(MAKE) artifact-push!

artifact-zsh!: | subrepos/zsh/checkout! artifacts extracted/artifacts/toolchain.tar extracted/artifacts/ncurses.tar
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/zsh
	$(MAKE) artifact-push!

artifact-coreutils!: | subrepos/coreutils/checkout! artifacts extracted/artifacts/toolchain.tar extracted/artifacts/ncurses.tar install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp js/wasm32.js wasm/libc.wasm wasm/ld.wasm wasm/libm.wasm
	$(MAKE) artifacts/jsshell-linux-x86_64.zip
	unzip artifacts/jsshell-linux-x86_64.zip -d bin
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/coreutils
	$(MAKE) $(patsubst %,wasm/%.wasm,$(COREUTILS))
	cp $(patsubst %,wasm/%.wasm,$(COREUTILS)) artifacts/
	$(MAKE) artifact-push!

artifact-emacs!: | subrepos/emacs/checkout! artifacts extracted/artifacts/toolchain.tar extracted/artifacts/ncurses.tar install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp js/wasm32.js wasm/libc.wasm wasm/ld.wasm wasm/libm.wasm wasm/libncurses.wasm
	$(MAKE) artifacts/jsshell-linux-x86_64.zip
	unzip artifacts/jsshell-linux-x86_64.zip -d bin
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/emacs
	$(MAKE) $(patsubst %,wasm/%.wasm,temacs emacs)
	cp $(patsubst %,wasm/%.wasm,temacs emacs) artifacts/
	$(MAKE) artifact-push!

artifact-miniperl!: | install/binfmt_misc/elf32-wasm32
artifact-miniperl!: | install/binfmt_misc/wasm
artifact-miniperl!: | install/file-slurp

artifact-perl!: | install/binfmt_misc/elf32-wasm32
artifact-perl!: | install/binfmt_misc/wasm
artifact-perl!: | install/file-slurp

artifact-miniperl!: | subrepos/perl/checkout! artifacts extracted/artifacts/toolchain.tar js/wasm32.js artifacts/jsshell-linux-x86_64.zip
	unzip artifacts/jsshell-linux-x86_64.zip -d bin
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/miniperl wasm/miniperl.wasm
	cp wasm/miniperl.wasm artifacts/
	$(MAKE) artifact-push!

artifact-perl!: | subrepos/perl/checkout! artifacts extracted/artifacts/toolchain.tar js/wasm32.js artifacts/jsshell-linux-x86_64.zip
	unzip artifacts/jsshell-linux-x86_64.zip -d bin
	$(MAKE) artifact-timestamp
	$(MAKE) built/wasm32/perl wasm/perl.wasm
	cp wasm/perl.wasm artifacts/
	$(MAKE) artifact-push!

artifact-python!: | install/binfmt_misc/elf32-wasm32
artifact-python!: | install/binfmt_misc/wasm
artifact-python!: | install/file-slurp

artifact-python!: | subrepos/python/checkout! artifacts extracted/artifacts/toolchain.tar js/wasm32.js artifacts/jsshell-linux-x86_64.zip
	$(MAKE) built/common/python
	unzip artifacts/jsshell-linux-x86_64.zip -d bin
	$(MAKE) artifact-timestamp
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) built/wasm32/python wasm/python.wasm
	touch wasm32-unknown-none/wasm32-unknown-none/lib/python3.10/encodings/.dir wasm32-unknown-none/wasm32-unknown-none/lib/python3.10/.dir
	PYTHONHOME=$(PWD)/wasm32-unknown-none/wasm32-unknown-none ./wasm32-unknown-none/wasm32-unknown-none/bin/python3 -c 'print(3+4)' < /dev/null
	cp wasm/python.wasm artifacts/
	$(MAKE) artifact-push!

# Create a file to be shipped
ship/%.gz: artifacts/% | ship
	gzip < $< > $@
ship/%: artifacts/% | ship
	cat $< > $@
# Retrieve asset list (and cache it)
github/assets/%.json: | github/release/list! github/assets
	if [ -e "github/release/\"$*\"" ]; then \
	    curl -sSL "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets" > $@; \
	else \
	    echo "[]" > $@; \
	fi

# Ship assets
ship-wasm/%!: ship/libc.wasm ship/ld.wasm ship/libncurses.wasm ship/bash.wasm ship/libutil.wasm ship/libm.wasm ship/libdl.wasm ship/libcrypt.wasm github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-binutils/%!: ship/binutils.tar.gz github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-gcc-preliminary/%!: ship/gcc-preliminary.tar.gz github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-gcc/%!: ship/gcc.tar.gz github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-toolchain/%!: ship/toolchain.tar.gz github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-glibc/%!: ship/glibc.tar.gz github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-bash/%!: ship/bash.tar.gz github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-ncurses/%!: ship/ncurses.tar.gz github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)

ship-problem/%!: ship/problem.tar.gz github/assets/%.json | ship github github/release/list!
	$(MAKE) github/release/list!
	for name in $$(cd ship; ls *); do for id in $$(jq ".[] | if .name == \"$$name\" then .id else 0 end" < github/assets/$*.json); do [ $$id != "0" ] && curl -sSL -XDELETE -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/assets/$$id"; echo; done; done
	(for name in ship/*; do bname=$$(basename "$$name"); curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" --header "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$$GITHUB_REPOSITORY/releases/$$(cat github/release/\"$*\")/assets?name=$$bname" --upload-file $$name; echo; done)


github/release/list!: | github/release
	curl -sSL https://api.github.com/repos/$$GITHUB_REPOSITORY/releases?per_page=100 | jq '.[] | [(.).tag_name,(.).id] | .[]' | while read tag; do read id; echo $$id > github/release/$$tag; done
	curl -sSL https://api.github.com/repos/$$GITHUB_REPOSITORY/releases/tags/latest | jq '.[.tag_name,.id] | .[]' | while read tag; do read id; echo $$id > github/release/$$tag; done
	ls -l github/release/

github/check-release!: | github
	last_release_date="$$(curl https://api.github.com/repos/$$GITHUB_REPOSITORY/releases | jq "[.[] | .created_at] | sort[-1]" | cut -c 2-11)"; \
	this_release_date="$$(date --iso)"; \
	if [ "$$this_release_date" != "$$last_release_date" ]; then \
	    node ./github/release.js $$this_release_date $$last_release_date > github/release.json; \
	    curl -sSL -XPOST -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/repos/$$GITHUB_REPOSITORY/releases" --data '@github/release.json'; \
	    sleep 1m; \
	    $(MAKE) ship-wasm/$$this_release_date!; \
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
	JS=$(JS) WASMDIR=$(PWD) EXECUTABLE=$< $(JS) $(PWD)/js/wasm32.js $< > $@ 2> test/wasm32/$*.wasm.err || true
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

daily:
	$(MKDIR) $@

.github-init:
	bash github/artifact-init
	touch $@

# Extract an artifact
extracted/%.tar: %.tar | extracted
	$(MKDIR) $(dir extracted/$*)
	tar xf $*.tar
	touch $@

extracted/%.tar.gz: %.tar.gz | extracted
	$(MKDIR) $(dir extracted/$*)
	tar xzf $*.tar.gz
	touch $@

daily/%: | daily
	bash github/dl-daily $*
	ls -l $@

artifacts/%: | artifacts
	bash github/dl-artifact $*
	mv $@.new/$* $@
	rm -rf $@.new
	ls -l $@

artifact-timestamp:
	touch $@
	sleep 1

artifact-push!:
	(cd artifacts; for file in *; do if [ "$$file" -nt ../artifact-timestamp ]; then name=$$(basename "$$file"); (cd ..; bash github/ul-artifact "$$name" "artifacts/$$name"); fi; done)

%.{dejagnu}!: js/wasm32.js install/texinfo-bison-flex install/gcc-dependencies install/dejagnu build | extracted/artifacts/toolchain.tar tools/bin/wasmrewrite tools/bin/wasmsect artifacts/jsshell-linux-x86_64.zip install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 artifacts/libc.wasm artifacts/ld.wasm artifacts/libm.wasm artifacts wasm
	cp artifacts/*.wasm wasm
	$(MAKE) artifact-timestamp
	unzip artifacts/jsshell-linux-x86_64.zip -d bin
	$(MKDIR) build/wasm32/gcc/gcc/testsuite/gcc
	(cd build/wasm32/gcc/gcc; make site.exp && cp site.exp testsuite && cp site.exp testsuite/gcc)
#	(cd src/gcc/gcc/testsuite/; find -type d | while read DIR; do cd $DIR; ls * | shuf | head -n +128 | egrep -v '*.dg' | while read; do rm $REPLY; done; done) || true
	(cd src/gcc/gcc/testsuite; find -type f | egrep '\.([cisSxX]|x0|X0)$$' | xargs md5sum | egrep -v "^$$PREFIX" | while read shasum path; do rm -f $$path; done)
	(cd build/wasm32/gcc/gcc/testsuite/gcc; WASMDIR=$(PWD) JS=$(PWD)/bin/js srcdir=$(PWD)/src/gcc/gcc runtest -a --tool gcc $*) | tee $(notdir $*).out || true
	cp $(notdir $*).out artifacts/$(notdir $*)-$$PREFIX.out
	cp build/wasm32/gcc/gcc/testsuite/gcc/gcc.log artifacts/$(notdir $*)-$$PREFIX.log
	grep FAIL build/wasm32/gcc/gcc/testsuite/gcc/gcc.log > artifacts/$(notdir $*)-$$PREFIX-short.log || true
	$(MAKE) artifact-push!

%.{daily-dejanew}!: js/wasm32.js install/texinfo-bison-flex install/gcc-dependencies install/dejagnu | extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz tools/bin/wasmrewrite tools/bin/wasmsect install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 subrepos/gcc/checkout! daily src/gcc
	$(MAKE) extracted/daily/gcc-preliminary.tar.gz
	$(MAKE) extracted/daily/gcc.tar.gz
	$(MAKE) bin/js
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) wasm/libstdc++.wasm
	$(MAKE) artifacts artifact-timestamp
	JS=$(PWD)/bin/js WASMDIR=$(PWD) $(MAKE) build/wasm32/gcc-testsuite-tar/$*.{dejagnu}.tar
	cp build/wasm32/gcc-testsuite-tar/$*.{dejagnu}.tar artifacts/

%.{dejanew}!: js/wasm32.js install/texinfo-bison-flex install/gcc-dependencies install/dejagnu | extracted/artifacts/toolchain.tar tools/bin/wasmrewrite tools/bin/wasmsect install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 artifacts/libc.wasm artifacts/ld.wasm artifacts/libm.wasm subrepos/gcc/checkout! artifacts src/gcc
	$(MAKE) artifacts/jsshell-linux-x86_64.zip
	unzip artifacts/jsshell-linux-x86_64.zip -d bin
	$(MKDIR) wasm
	cp artifacts/*.wasm wasm
	$(MAKE) artifact-timestamp
	$(MAKE) build/wasm32/gcc-testsuite/$*.{dejagnu}.tar
	cp build/wasm32/gcc-testsuite/$*.{dejagnu}.tar artifacts/

binutils-test!: install/dejagnu
	$(MAKE) subrepos/binutils-gdb/checkout!
	$(MAKE) built/wasm32/binutils-gdb
	$(MAKE) artifacts
	$(MAKE) artifact-timestamp
	$(MAKE) -k -C build/wasm32/binutils-gdb check || true
	find build/wasm32/binutils-gdb -name '*.log' | egrep -v 'config\.log$$' | while read REPLY; do cp $$REPLY artifacts/; done
	$(MAKE) artifact-push!

gcc-testsuite!: build/wasm32/gcc-testsuite/gcc.c-torture/compile/compile.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.c-torture/execute/execute.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.dg/dg.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.dg/weak/weak.exp.{dejagnu}.tar build/wasm32/gcc-testsuite/gcc.c-torture/execute/ieee/ieee.exp.{dejagnu}.tar

daily-binutils!: | subrepos/binutils-gdb/checkout!
	$(MAKE) built/wasm32/binutils-gdb

daily-gcc-preliminary!: | subrepos/gcc/checkout! extracted/daily/binutils.tar.gz
	$(MAKE) built/wasm32/gcc-preliminary

daily-glibc!: | subrepos/glibc/checkout! extracted/daily/binutils.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/gcc.tar.gz
	touch built/wasm32/binutils-gdb
	touch built/wasm32/gcc-preliminary
	$(MAKE) built/wasm32/glibc

daily-gcc!: | subrepos/gcc/checkout! extracted/daily/binutils.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/glibc.tar.gz
	touch built/wasm32/binutils-gdb
	touch built/wasm32/gcc-preliminary
	touch built/wasm32/glibc
	$(MAKE) built/wasm32/gcc
	$(MAKE) wasm/libstdc++.wasm

daily-ncurses!: | subrepos/ncurses/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/gcc.tar.gz
	touch built/wasm32/binutils-gdb
	touch built/wasm32/gcc-preliminary
	touch built/wasm32/glibc
	touch built/wasm32/gcc
	$(MAKE) built/wasm32/ncurses
	$(MAKE) wasm/libncurses.wasm

daily-bash!: | install/file-slurp
daily-coreutils!: | install/file-slurp
daily-emacs!: | install/file-slurp
daily-emacs-native-comp!: | install/file-slurp
daily-miniperl!: | install/file-slurp
daily-perl!: | install/file-slurp
daily-python!: | install/file-slurp
daily-ncurses!: | install/file-slurp
daily-run-all-tests!: | install/file-slurp
daily-run-all-tests!: | tools/bin/dyninfo
daily-run-all-tests!: | js/wasm32.js
daily-run-elf!: | install/file-slurp
daily-run-elf!: | tools/bin/dyninfo
daily-run-elf!: | js/wasm32.js
daily-run-wasm!: | install/file-slurp
daily-run-wasm!: | tools/bin/dyninfo
daily-run-wasm!: | js/wasm32.js
daily-zsh!: | install/file-slurp

daily-bash!: | subrepos/bash/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/ncurses.tar.gz
	touch built/wasm32/binutils-gdb
	touch built/wasm32/gcc-preliminary
	touch built/wasm32/glibc
	touch built/wasm32/gcc
	touch built/wasm32/ncurses
	$(MAKE) built/wasm32/bash wasm/bash.wasm

built/wasm32/zsh: | install/nroff

daily-zsh!: | subrepos/zsh/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/ncurses.tar.gz
	$(MAKE) built/wasm32/zsh

daily-coreutils!: | subrepos/coreutils/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/ncurses.tar.gz install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp js/wasm32.js bin/js
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	JS=$(JS) WASMDIR=$(PWD) $(MAKE) built/wasm32/coreutils
	JS=$(JS) WASMDIR=$(PWD) $(MAKE) $(patsubst %,wasm/%.wasm,$(COREUTILS))

daily-emacs!: | subrepos/emacs/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/ncurses.tar.gz install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp js/wasm32.js bin/js
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) wasm/libncurses.wasm
	JS=$(JS) WASMDIR=$(PWD) $(MAKE) built/wasm32/emacs
	JS=$(JS) WASMDIR=$(PWD) $(MAKE) $(patsubst %,wasm/%.wasm,temacs emacs)

daily-emacs-native-comp!: | subrepos/emacs-native-comp/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/ncurses.tar.gz install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp js/wasm32.js bin/js
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) wasm/libncurses.wasm
	JS=$(JS) WASMDIR=$(PWD) $(MAKE) built/wasm32/emacs-native-comp

daily-gmp!: | subrepos/gmp/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz extracted/daily/ncurses.tar.gz install/gperf install/autopoint install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/file-slurp js/wasm32.js bin/js
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) wasm/libncurses.wasm
	JS=$(JS) WASMDIR=$(PWD) $(MAKE) built/wasm32/gmp

daily-miniperl!: | subrepos/perl/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm js/wasm32.js bin/js
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) built/wasm32/miniperl wasm/miniperl.wasm

daily-perl!: | subrepos/perl/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm install/sysctl/overcommit_memory js/wasm32.js bin/js
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) built/wasm32/perl wasm/perl.wasm

daily-python!: | subrepos/python/checkout! extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/elf32-wasm32 install/binfmt_misc/wasm js/wasm32.js bin/js
	$(MAKE) built/common/python
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) built/wasm32/python wasm/python.wasm
	touch wasm32-unknown-none/wasm32-unknown-none/lib/python3.10/encodings/.dir wasm32-unknown-none/wasm32-unknown-none/lib/python3.10/.dir
	PYTHONHOME=$(PWD)/wasm32-unknown-none/wasm32-unknown-none ./wasm32-unknown-none/wasm32-unknown-none/bin/python3 -c 'print(3+4)' < /dev/null

daily-run-elf!: | extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 js/wasm32.js bin/js
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	./wasm32-unknown-none/bin/wasm32-unknown-none-gcc ./testsuite/003-hello-world/hello-world.c -o hello-world.exe
	./hello-world.exe

daily-run-wasm!: | extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz install/binfmt_misc/wasm install/binfmt_misc/elf32-wasm32 js/wasm32.js bin/js tools/bin/elf-to-wasm
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	./wasm32-unknown-none/bin/wasm32-unknown-none-gcc ./testsuite/003-hello-world/hello-world.c -o hello-world.exe
	./hello-world.exe
	tools/bin/elf-to-wasm --executable hello-world.exe > hello-world.wasm
	chmod u+x hello-world.wasm
	./hello-world.wasm

daily-run-all-tests!: | extracted/daily/binutils.tar.gz extracted/daily/glibc.tar.gz extracted/daily/gcc.tar.gz extracted/daily/gcc-preliminary.tar.gz js/wasm32.js bin/js tools/bin/elf-to-wasm
	$(MKDIR) wasm
	$(MAKE) wasm/ld.wasm
	$(MAKE) wasm/libc.wasm
	$(MAKE) wasm/libdl.wasm
	$(MAKE) wasm/libcrypt.wasm
	$(MAKE) wasm/libutil.wasm
	$(MAKE) wasm/libm.wasm
	$(MAKE) wasm/libstdc++.wasm
	$(MAKE) run-all-tests!

gcc-testsuites-pack!: | artifacts/atomic.exp.{dejagnu}.tar artifacts/builtins.exp.{dejagnu}.tar artifacts/charset.exp.{dejagnu}.tar artifacts/compile.exp.{dejagnu}.tar artifacts/debug.exp.{dejagnu}.tar artifacts/dg.exp.{dejagnu}.tar artifacts/dwarf2.exp.{dejagnu}.tar artifacts/execute.exp.{dejagnu}.tar artifacts/format.exp.{dejagnu}.tar artifacts/ieee.exp.{dejagnu}.tar artifacts/lto.exp.{dejagnu}.tar artifacts/tls.exp.{dejagnu}.tar artifacts/tm.exp.{dejagnu}.tar artifacts/weak.exp.{dejagnu}.tar
	$(MAKE) artifact-timestamp
	mkdir tmp
	cd tmp; for a in artifacts/atomic.exp.{dejagnu}.tar artifacts/builtins.exp.{dejagnu}.tar artifacts/charset.exp.{dejagnu}.tar artifacts/compile.exp.{dejagnu}.tar artifacts/debug.exp.{dejagnu}.tar artifacts/dg.exp.{dejagnu}.tar artifacts/dwarf2.exp.{dejagnu}.tar artifacts/execute.exp.{dejagnu}.tar artifacts/format.exp.{dejagnu}.tar artifacts/ieee.exp.{dejagnu}.tar artifacts/lto.exp.{dejagnu}.tar artifacts/tls.exp.{dejagnu}.tar artifacts/tm.exp.{dejagnu}.tar artifacts/weak.exp.{dejagnu}.tar; do tar xvf ../$$a; done
	cd tmp; tar cvf ../artifacts/dejagnu.tar .

clean: clean!
all: built/all

.PHONY: %! clean all
.SUFFIXES:
