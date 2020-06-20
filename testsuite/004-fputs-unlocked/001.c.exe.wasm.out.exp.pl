#!/usr/bin/perl
$_ = readline; chomp;
die $_ unless /^stdout 0x[0-9a-f]+$/;
$_ = readline; chomp;
die $_ unless /^hello world$/;
warn "success";
