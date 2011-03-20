#!/usr/bin/perl
use strict;
my $all = $ARGV[0]; #all-srr.csv
my $down = $ARGV[1]; #downloaded-srr.txt
my %t;
open my $dh, "<", $down || die;
while(my $line = <$dh>) {
    chomp $line;
    next if $line =~ /^\s*$/;
    $line =~ s/\.gz//g;
    $line =~ s/\.fastq//g;
    $line =~ s/_\d//g;
    $t{$line} = 1;
}
#print scalar keys %t;
open my $ah, "<", $all || die;
while(my $line = <$ah>) {
    chomp $line;
    my @fld = split "\t", $line;
    unless (exists $t{$fld[2]}) {
	print $line, "\n";
    }
}

