#!/usr/bin/perl
my %byext;
my @all;
my @frags;

my $prefix = shift @ARGV;
for my $file (@ARGV) {
    $file = substr $file, length($prefix);
    my $ext = $file;
    $ext =~ s/.*\.//g;
    $byext{$ext}{$file} = $file;
}

push @frags, <<'EOF';
%.c.exe: %.c
	$(WASMDIR)/bin/wasm32-unknown-none-gcc $< -o $@

%.exe.wasm: %.exe
	$(WASMDIR)/wasmify/wasmify-executable $< > $@

%.wasm.out: %.wasm
	$(JS) $(WASMDIR)/js/wasm32.js $< > $@ 2> $*.wasm.err
EOF
if (scalar keys %{$byext{c}} == 1) {
    for my $file (values %{$byext{c}}) {
	push @all, "$file.exe";
	push @all, "$file.exe.wasm";
	push @all, "$file.exe.wasm.out";
    }
}
if (scalar keys %{$byext{c}} > 0) {
    push @frags, <<'EOF';
%.c.s: %.c
	$(WASMDIR)/bin/wasm32-unknown-none-gcc -S $< -o $@

%.c.o: %.c
	$(WASMDIR)/bin/wasm32-unknown-none-gcc -c $< -o $@
EOF
    for my $file (values %{$byext{c}}) {
	push @all, "$file.s";
	push @all, "$file.o";
    }
}

for my $file (keys %{$byext{exp}}) {
    my $out = $file;
    $out =~ s/\.ext$//;
    push @frags, <<'EOF';
%.exp.cmp: %.exp %
	diff -u $^
EOF
    push @all, $file . ".cmp";
}

unshift @frags, "all: " . join(" ", @all) . "\n";
unshift @frags, "vpath %.c src .\nvpath %.h src .\nvpath %.S src .\nvpath %.cc src .\nvpath %.exp src\n";
print join("\n", @frags);
