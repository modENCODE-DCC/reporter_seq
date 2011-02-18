#!/usr/bin/perl
use strict;
my $file = $ARGV[0];
open my $fh, "<", $file || die;
while(my $l = <$fh>) {
    chomp $l;
    next if $l =~ /^\s*$/;
    next if $l =~ /==>/;
    print $l, "\n";
} 
