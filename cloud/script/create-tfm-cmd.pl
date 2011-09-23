#!/usr/bin/perl
use strict;
my $file = $ARGV[0]; #sra-map.csv
my $p = "/modencode/modencode-dcc/staging/";
my $o = "/modencode/modencode-dcc/staging/fastq/";
open my $fh, "<", $file ||die;
while(my $line = <$fh>) {
	chomp $line;
	my @fld = split /\t/, $line;
	my $dir = $fld[3]; $dir =~ s/ftp:\/\///; $dir = $p . $dir;
	my @xrr = split "/", $fld[2]; my $srr = $xrr[-1];
	my $c = "/home/zzha/sratoolkit.2.0rc5-ubuntu32/fastq-dump.2";
	my $a = $srr;
	$dir .= "/$srr.sra" unless $dir =~ /\.sra$/;
	my $cmd = "$c -A $a -O $o -D $dir";
	print $cmd, "\n";
}
