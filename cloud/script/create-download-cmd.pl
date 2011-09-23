#!/usr/bin/perl
use strict;
my $sra_file = $ARGV[0];
my $dcc_file = $ARGV[1];
my $print_wgt_cmd = 0;
$print_wgt_cmd = $ARGV[2] if defined($ARGV[2]);
my $xr_map = {};
my $rx_map = {};
my $ru_map = {};	
open my $sra_fh, "<", $sra_file || die;
while(my $line=<$sra_fh>) {
	chomp $line;
	my @fields = split /\t/, $line;
	my @srx_dirs = split "/", $fields[0];
	my $srx = $srx_dirs[-1];
	my @srr_dirs = split "/", $fields[1];
	my $srr = $srr_dirs[-1];
	if (exists $xr_map->{$srx}) {
		push @{$xr_map->{$srx}}, $srr;
	} else {
		$xr_map->{$srx} = [$srr];
	}
	$rx_map->{$srr} = $srx;
	$ru_map->{$srr} = $fields[2];
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
				unless ($print_wgt_cmd) {
					print join("\t", ($id, $sra, $srr, $ru_map->{$srr})), "\n";
				} else {
					print "wget -rdc ", $ru_map->{$srr}, "\n";
				}
			}
		} else {
			print "err: $sra not found.\n";
		}
	} 
	elsif ($sra =~ /^SRR/) {
		if (exists $ru_map->{$sra}) {
			unless ($print_wgt_cmd) {	
				print join("\t", ($id, $rx_map->{$sra}, $sra, $ru_map->{$sra})), "\n";
			} else {
				print "wget -rdc ", $ru_map->{$sra}, "\n";
			}
		} else {
			print "err: $id: $sra not found.\n";
		}
	}
}
close $dcc_fh;
