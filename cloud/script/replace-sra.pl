#!/usr/bin/perl
use strict;
my $sra_file = $ARGV[0]; #sra-map.csv 4 fields id/srx/srr/url
my $dcc_file = $ARGV[1]; #tag file
my $fastq_dir = $ARGV[2]; 
my $xr_map = {};
my $rx_map = {};
open my $sra_fh, "<", $sra_file || die;
while(my $line=<$sra_fh>) {
	chomp $line;
	my @fields = split /\t/, $line;
	my @srx_dirs = split "/", $fields[1];
	my $srx = $srx_dirs[-1];
	my @srr_dirs = split "/", $fields[2];
	my $srr = $srr_dirs[-1];
	if (exists $xr_map->{$srx}) {
		push @{$xr_map->{$srx}}, $srr;
	} else {
		$xr_map->{$srx} = [$srr];
	}
	$rx_map->{$srr} = $srx;
}
close $sra_fh;
open my $dcc_fh, "<", $dcc_file || die;
while (my $line = <$dcc_fh>) {
	chomp $line;
	my @fields = split /\t/, $line;
	my $id = $fields[0];
	my $sra = $fields[3];
	if ($sra =~ /^SRX/) {
		if ( exists $xr_map->{$sra} ) {
			for my $srr (@{$xr_map->{$sra}}) {
				my @srr_fastq = get_fastq_family($fastq_dir, $srr);
				for my $fastq (@srr_fastq) {
					$fields[2] = $fastq;
					$fields[3] = $fastq;
					$fields[7] = 'raw-seqfile_fastq';
					print join("\t", @fields), "\n";
				}
			}
		} else {
			print "err: $line\n";
		}
	} 
	elsif ($sra =~ /^SRR/) {
		if (exists $rx_map->{$sra}) {
			my @srr_fastq = get_fastq_family($fastq_dir, $sra); 
			for my $fastq (@srr_fastq) {
				$fields[2] = $fastq;
				$fields[3] = $fastq;
				$fields[7] = 'raw-seqfile_fastq';
				print join("\t", @fields), "\n";
			}
		} else {
			print "err: $line\n";
		}
	}
}
close $dcc_fh;

sub get_fastq_family {
	my ($dir, $srr) = @_;
	my @fs;
	my $name = $srr . '.fastq';
	my $path = $dir . '/' . $name;
	push @fs, $name if -e $path;
	for my $i (1..10) {
		my $name = $srr . "_" . $i . ".fastq";
		my $path = $dir . '/' . $name;
		push @fs, $name if -e $path;
	}
	return @fs;
}
