#!/usr/bin/perl
#take a group of files in commandline or from configure file
#cp sim link, unzips and removes barcode as necessary and concats them
use strict;
use File::Basename qw[fileparse];
use Archive::Extract;
my ($out, @in) = @ARGV;
my $out_dir = (fileparse($out))[1];
my @tmp;
foreach my $inf (@in) {
    my $fn = (fileparse($inf))[0]; #original file
    my $t = $out_dir . $fn; #copy file
    if (-l $inf) { #symlink
	print "$inf is a symbolic link. copying...";
	system("cp -L $inf $t");
	print "done\n";
    } else {
	print "$inf is an ordinary file. copying...";
	system("cp $inf $t");
	print "done\n";
    }
    
    my $ae;
    eval {$ae = Archive::Extract->new(archive => $t)};
    if ( !$@ && defined($ae)) {#a zipped file
	print "$t is a zipped file. unzipping...";
	$ae->extract(to => $out_dir) || die "failed to extract $t.\n";
	die "multiple files found in $t.\n" if scalar $ae->files != 1;
	system("rm $t"); #remove zipped file
	$t = $out_dir . $ae->files->[0]; #the unzipped file
	die "can not found just extracted $t\n" if -e $t;
	print "done\n";
	print "the new unzipped file is $t, the copied file from the above step is removed.\n";
    }

    push @tmp $t;
}

#catenate files
system(join(" ", ("cat", @tmp, "> $out")));  

#cleanup tmp files
system(join(" ", ("rm", @tmp)));
