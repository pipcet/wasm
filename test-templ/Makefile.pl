#!/usr/bin/perl
my %byext;
my @all;
my @frags;

my $prefix = shift @ARGV;
for my $file (@ARGV) {
    $file = substr $file, length($prefix);
    my $ext = $file;
    do {
	$byext{$ext}{$file} = substr($file, 0, length($file) - length($ext) - 1);
	$ext =~ s/.*?\././;
    } while ($ext =~ s/^\.//);
}
for my $ext (sort keys %byext) {
    for my $file (sort keys %{$byext{$ext}}) {
	warn "$ext $file $byext{$ext}{$file}";
    }
}

push @frags, <<'EOF';
%.c.exe: %.c
	$(WASMDIR)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc $< -o $@

%.c.{static}.exe: %.c
	$(WASMDIR)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc -Wl,-Map,$*.c.{static}.map -static $< -o $@

%.{static}.exe.wasm.out.exp: %.exe.wasm.out.exp
	cat $< > $@

%.exe.wasm: %.exe
	$(WASMDIR)/wasmify/wasmify-executable $< > $@

%.wasm.out: %.wasm
	$(JS) $(WASMDIR)/js/wasm32.js $< | tee $@ 2> $*.wasm.err || true
	echo "STDOUT"
	cat $@
	echo "STDERR"
	cat $*.wasm.err
EOF
push @frags, <<'EOF';
%.cc.exe: %.cc
	$(WASMDIR)/wasm32-unknown-none/bin/wasm32-unknown-none-g++ $< -o $@
EOF
if (scalar keys %{$byext{c}} == 1) {
    for my $file (keys %{$byext{c}}) {
	push @all, "$file.exe";
	push @all, "$file.exe.wasm";
	push @all, "$file.exe.wasm.out";
	push @all, "$file.{static}.exe";
	push @all, "$file.{static}.exe.wasm";
	push @all, "$file.{static}.exe.wasm.out";
    }
}
if (scalar keys %{$byext{cc}} == 1) {
    for my $file (keys %{$byext{cc}}) {
	push @all, "$file.exe";
	push @all, "$file.exe.wasm";
	push @all, "$file.exe.wasm.out";
    }
}
if (scalar keys %{$byext{c}} > 0) {
    push @frags, <<'EOF';
%.c.s: %.c
	$(WASMDIR)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc -S $< -o $@

%.c.o: %.c
	$(WASMDIR)/wasm32-unknown-none/bin/wasm32-unknown-none-gcc -c $< -o $@

%.cc.s: %.cc
	$(WASMDIR)/wasm32-unknown-none/bin/wasm32-unknown-none-g++ -S $< -o $@

%.cc.o: %.cc
	$(WASMDIR)/wasm32-unknown-none/bin/wasm32-unknown-none-g++ -c $< -o $@
EOF
    for my $file (keys %{$byext{c}}) {
	push @all, "$file.s";
	push @all, "$file.o";
    }
}

for my $file (keys %{$byext{exp}}) {
    my $out = $byext{exp}{$file};
    push @frags, <<'EOF';
%.exp.cmp: %.exp %
	diff -u $^ > $@
EOF
    push @all, $file . ".cmp";
}

for my $file (keys %{$byext{"exp.pl"}}) {
    my $out = $byext{"exp.pl"}{$file};
    push @frags, <<'EOF';
%.exp.cmp: %.exp.pl %
	perl $^ > $@
EOF
    push @all, "$out.exp.cmp";
}

unshift @frags, "all: " . join(" ", @all) . "\n";
unshift @frags, "vpath %.c src .\nvpath %.h src .\nvpath %.S src .\nvpath %.cc src .\nvpath %.exp src\nvpath %.exp.pl src\n";
print join("\n", @frags);
print "\n.SUFFIXES:\n";
