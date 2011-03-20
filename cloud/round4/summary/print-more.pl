#!/usr/bin/perl
use strict;
my $file = $ARGV[0];
open my $fh, "<", $file || die;
while(my $line = <$fh>) {
    chomp $line;
    my @fld = split " ", $line;
    my @dir = split "/", $fld[2];
    print join("\t", ($fld[0], $dir[-3], $dir[-2], $fld[2])), "\n";
}
