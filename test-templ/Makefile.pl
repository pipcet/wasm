#!/usr/bin/perl
my %byext;
my @all;
my @frags;

my $prefix = shift @ARGV;
my $outprefix = shift @ARGV;
$prefix =~ s/\/*$//;
for my $file (@ARGV) {
    # $file = substr $file, length($prefix);
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

push @frags, <<"EOF";
${prefix}/\%: ${prefix}/src/\% \| ${prefix}
	cat \$< > \$\@
EOF

push @frags, <<'EOF';
EOF
push @frags, <<'EOF';
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
EOF
    push @all, "$out.exp.cmp";
}

unshift @frags, "${outprefix}/status:" . (@all ? (" " . join(" ", @all)) : "") . "\n";
print join("\n", @frags);
print "\n.SUFFIXES:\n";
