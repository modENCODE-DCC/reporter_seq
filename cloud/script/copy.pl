#!/usr/bin/perl
use strict;
my $file = $ARGV[0];
my $new_file = $file . ".correct_path";
open my $fh, "<", $file || die;
open my $nfh, ">", $new_file || die;
while(my $line = <$fh>) {
	chomp $line;
	my @fields = split /\t/, $line;
	my $path = "/modencode/raw/data/" . $fields[0] . "/" . "extracted/" . $fields[3];
	my $to = "/modencode/modencode-dcc/data2/" . $fields[0] . "_" . $fields[3];
	if (-e $path) {
		unless (system("cp $path $to") == 0) {
			print "err: $path\n" and next;
		} else {
			$fields[3] = $path;
			#print $nfh join("\t", @fields), "\n";
		}
	} else {
		print "err: $path\n";
	}
}
