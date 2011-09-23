#!/usr/bin/perl
my $f1 = $ARGV[0];
my $f2 = $ARGV[1];
open my $fh1, "<", $f1 || die;
open my $fh2, "<", $f2 || die;
my $m1 = {};
while(my $line = <$fh1>) {
	chomp $line;
	$line =~ s/^\s*//; $line =~ s/\s*$//;
	$m1->{$line} = 1;
}
while(my $line = <$fh2>) {
	chomp $line;
	$line =~ s/^\s*//; $line =~ s/\s*$//;
	if (exists $m1->{$line}) {
		$m1->{$line} = 2;
		print "shared $line\n";
	} else {
		print "uniq to file 2 $line\n";
	}
}
while(my ($k, $v) = each %$m1) {
	print "uniq to file 1 $k\n" if $v == 1;
}
close $fh1;
close $fh2;
