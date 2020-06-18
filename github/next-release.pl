#!/usr/bin/perl
my $res = 0.0;

while (<>) {
    chomp;
    my $version;
    /^"v([0-9.]*)"/ && ($version = $1);
    my $delta = .01;
    my $prec = 2;
    while (int ($version + $delta) != int ($version)) {
	$delta *= .1;
	$prec++;
    }
    my $nextversion = $version + $delta;
    if ($nextversion > $res) {
	$res = sprintf("%.${prec}f", $nextversion);
    }
}

print "v${res}\n";
