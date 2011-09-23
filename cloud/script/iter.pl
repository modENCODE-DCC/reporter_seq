#!/usr/bin/perl
use strict;
use File::Find;
my $file = $ARGV[0];
open my $fh, "<", $file || die;
while(my $line = <$fh>) {
    chomp $line;
    next unless $line =~ s/^err: //;
    my @fld = split '/', $line;
    my ($id, $datafile) = ($fld[4], $fld[-1]);
    my $to = '/modencode/modencode-dcc/data2/' . $id . "_$datafile";	  
    my $dir = join '/', ($fld[0], $fld[1],  $fld[2], $fld[3], $fld[4], $fld[5]);
    find(sub {
               if ($_ eq $datafile) {
                   my $path = $File::Find::name;
		   if ($path !~ /\/ws180\//i && $path !~ /\/ws210\//i && $path !~ /\/ws170\//i) {
                       print "$path $to\n";
		   }
	       }
    }, $dir);		
}

