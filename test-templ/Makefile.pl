#!/usr/bin/perl
my %byext;
my @all;
my @frags;

my $prefix = shift @ARGV;
my $outprefix = shift @ARGV;
$prefix =~ s/\/*$//;
$outprefix =~ s/\/*$//;

for my $file (@ARGV) {
    my $ext = $file;
    push @frags, <<"EOF";
${outprefix}/${file}: ${prefix}/${file}
	cat \$< > \$\@
EOF
    do {
	$byext{$ext}{$file} = substr($file, 0, length($file) - length($ext) - 1);
	$ext =~ s/.*?\././;
    } while ($ext =~ s/^\.//);
}

if (scalar keys %{$byext{c}} == 1) {
    for my $file (keys %{$byext{c}}) {
	push @all, "${outprefix}/$file.exe";
	push @all, "${outprefix}/$file.exe.wasm";
	push @all, "${outprefix}/$file.exe.wasm.out";
	push @all, "${outprefix}/$file.{static}.exe";
	push @all, "${outprefix}/$file.{static}.exe.wasm";
	push @all, "${outprefix}/$file.{static}.exe.wasm.out";
    }
}
if (scalar keys %{$byext{cc}} == 1) {
    for my $file (keys %{$byext{cc}}) {
	push @all, "${outprefix}/$file.exe";
	push @all, "${outprefix}/$file.exe.wasm";
	push @all, "${outprefix}/$file.exe.wasm.out";
    }
}
if (scalar keys %{$byext{c}} > 0) {
    for my $file (keys %{$byext{c}}) {
	push @all, "${outprefix}/$file.s";
	push @all, "${outprefix}/$file.o";
    }
}

for my $file (keys %{$byext{exp}}) {
    my $out = $byext{exp}{$file};
    push @all, $outprefix . "/" . $file . ".cmp";
}

for my $file (keys %{$byext{"c.exe.wasm.out.exp"}}) {
    my $out = $byext{"c.exe.wasm.out.exp"}{$file};
    push @all, $outprefix . "/" . $out . ".c.{static}.exe.wasm.out.exp.cmp";
}

for my $file (keys %{$byext{"c.exe.wasm.out.exp.pl"}}) {
    my $out = $byext{"c.exe.wasm.out.exp.pl"}{$file};
    push @all, $outprefix . "/" . $out . ".c.{static}.exe.wasm.out.exp.cmp";
}

for my $file (keys %{$byext{"exp.pl"}}) {
    my $out = $byext{"exp.pl"}{$file};
    push @all, "${outprefix}/$out.exp.cmp";
}

unshift @frags, "${outprefix}/status:" . (@all ? (" " . join(" ", @all)) : "") . "\n";
print join("\n", @frags);
