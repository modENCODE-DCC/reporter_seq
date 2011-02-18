#!/usr/bin/perl
use strict;
use Class::Struct;
use Data::Dumper;
my $id = $ARGV[0];
my $ins = $ARGV[1]; #snyder_pipeline_map.csv
my $map = {};
struct Geo => {
    'chip' => '$',
    'rep' => '$',
    'name' => '$',
};
open my $insh, "<", $ins || die "no $ins";
while(my $line = <$insh>) {
    chomp $line;
    next if $line =~ /^\s*#/;
    next if $line =~ /^#/;
    my @fields = split "\t", $line;
    my ($filename, $chip, $rep) = ($fields[3], $fields[4], $fields[5]);
    my $s = Geo->new; $s->chip($chip); $s->rep($rep); $s->name($filename);
    push @{$map->{$fields[0]}}, $s;
}
#print Dumper($map);
my $out = 'tmp/snyder/';
#my $out = '/home/zzha/misc_reporter/';
my $soft = $out . "modencode_" . $id . ".soft";
my $new = $out . 'new/' . "modencode_" . $id . ".soft";
print $soft, "\n";
print $new, "\n";
open my $sh, "<", $soft || die;
open my $nh, ">", $new;
my @ip;
my @rep;
my $i=-1;
while(my $line=<$sh>) {
    print $nh $line;
    chomp $line;
    if ($line =~ /Sample = /) {
	$i++;
	push @rep, '1' if $line =~ /_rep1/;
	push @rep, '2' if $line =~ /_rep2/;
    }
    elsif ($line =~ /Sample_description = /) {
	push @ip, "input" if $line =~ /is input DNA/;
	push @ip, "ChIP" if $line =~ /is ChIP DNA/;
    }
    elsif ($line =~ /Sample_data_processing = /) {
	my @ss = grep {$_->chip eq $ip[$i] && $_->rep eq $rep[$i]} @{$map->{$id}};
	print $i, "##\n";
	print Dumper(@ss);
	my @printed;
	for (my $j=0; $j<scalar @ss; $j++) {
	    my $t = $j+1;
	    my $n =  $ss[$j]->name;
	    unless (scalar grep {$_ eq $n} @printed) { 
		push @printed, $n;
		print $nh "!Sample_raw_file_" . $t . " = " . $n . "\n";
		print $nh "!Sample_raw_file_type_" . $t . " = FASTQ\n";
	    }
	}
    }
}
close $sh;
close $nh;

