#!/usr/bin/perl
my $file = $ARGV[0];
open my $fh, "<", $file || die;
while (my $line = <$fh>) {
	chomp $line;
	my @dir = split '/', $line;
	$line .= "/" . $dir[-1] . ".sra";
	print $line, "\n" unless -e $line;
}
