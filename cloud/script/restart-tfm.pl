#!/usr/bin/perl
my $cmd = $ARGV[0];
my $err = $ARGV[1];
open my $cf, "<", $cmd || die;
open my $erf, "<", $err || die;
my %map;
while(my $line = <$cf>) {
	chomp $line;
	@in = split /\s+/, $line;
	$map{$in[-1]} = $line;
}
while(my $line = <$erf>) {
	chomp $line;
	$line =~ /failed to open '(.*)'/;
	print $map{$1}, "\n";
}
