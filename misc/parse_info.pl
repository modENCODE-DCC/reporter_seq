#!/usr/bin/perl
use strict;
use Class::Struct;
my $file = $ARGV[0];
struct Info => {
    'id' => '$',
    'project' => '$',
    'title' => '$',
    'source' => '$',
    'sample' => '$',
    'extract' => '$',
    'hyb' => '$',
    'rep' => '$',
    'les' => '$',
};
my @ss;
open my $fh, "<", $file || die;
while(my $l = <$fh>) {
    chomp $l;
    my @fields = split "\t", $l;
    #test if any info for grouping is found
    #my $nf = scalar @fields - 3;
    #print join("\t", ($fields[0], $fields[1], $nf)), "\n";
    #my $source = $fields[3] if defined($fields[3]);
    #my $sample = $fields[4] if defined($fields[4]);
    #my $extract = $fields[5] if defined($fields[5]);
    #my $hyb = $fields[6] if defined($fields[6]);
    #my $rep = $fields[7] if defined($fields[7]);
    #my $last = $fields[8] if defined($fields[8]);
    my $s = Info->new;
    $s->id($fields[0]);
    $s->project($fields[1]);
    $s->title($fields[2]);
    $s->source($fields[3]) if defined($fields[3]);
    $s->sample($fields[4]) if defined($fields[4]);
    $s->extract($fields[5]) if defined($fields[5]);
    $s->hyb($fields[6]) if defined($fields[6]);
    $s->rep($fields[7]) if defined($fields[7]);
    $s->les($fields[8]) if defined($fields[8]);
    push @ss, $s;
}
