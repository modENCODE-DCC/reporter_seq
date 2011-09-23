#!/usr/bin/perl
use strict;
my $file = $ARGV[0]; #dcc tag file
open my $fh, "<", $file || die;
my $idm = {};
my $gm = {}; #geo
my $sm = {}; #sra
my $cel = {}; #cel raw data
my $pair = {}; #pair raw data
<$fh>; #header;
while(my $line = <$fh>) {
	chomp $line;
	my @fields = split /\t/, $line;
	my $id = $fields[0];
	my $type = $fields[6];
	$idm->{$id} = $type;
	my $fmt = $fields[7];
	$sm->{$id} = 1 if $fmt eq 'ShortReadArchive_record';
	$gm->{$id} = 1 if $fmt eq 'GEO_record';
	$cel->{$id} = 1 if $fmt eq 'raw-arrayfile_CEL';
	$pair->{$id} = 1 if $fmt eq 'raw-arrayfile_pair';
}
for my $id (sort keys %$idm) {
	my $type = $idm->{$id};
	unless ($type eq 'integrated-gene-model' || $type eq 'RT-PCR') {
		print "$id\t$type\n" unless (exists $gm->{$id} || exists $sm->{$id} || exists $cel->{$id} || exists $pair->{$id});
	}
}
