#!/usr/bin/perl
my $file = $ARGV[0];
my $tgt_file = $ARGV[1];
open my $fh, "<", $file || die;
while(my $line = <$fh>) {
	chomp $line;
	system("grep $line $tgt_file") == 0 || die;
}
