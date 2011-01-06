#!/usr/bin/perl

my $id_file = $ARGV[0];
open my $idfh, "<", $id_file || die;
while(my $line = <$idfh>) {
    chomp $line;
    next if $line =~ /^#/;
    next if $line =~ /^\s*$/;
    my @cols = split "\t", $line;
    my $id = $cols[0];
    print $id, "\n";
    next if system("perl extract.pl -id $id -o tmp/cloud > $id.log") != 0;
}
