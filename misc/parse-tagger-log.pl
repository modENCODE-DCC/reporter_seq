#!/usr/bin/perl
use strict;
my $file = $ARGV[0];
open my $fh, "<", $file;
while(my $line = <$fh>) {
    $line =~ s/\d*\.log:try to find antibody \.\.\.//g;
    $line =~ s/ done//g;
    print $line if $line =~ /Ab:/i;
}
