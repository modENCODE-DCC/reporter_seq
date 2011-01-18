#!/usr/bin/perl

my $id_file = $ARGV[0];
my $out_dir = $ARGV[1];
open my $idfh, "<", $id_file || die;
while(my $line = <$idfh>) {
    chomp $line;
    next if $line =~ /^#/;
    next if $line =~ /^\s*$/;
    my @cols = split "\t", $line;
    my $id = $cols[0];
    print $id, "\n";
    next if system("perl extract.pl -id $id -o $out_dir > $id.log") != 0;
}
