#!/usr/bin/perl
use strict;
my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir;
}
use GEO::Tagger;
my $spreadsheet = $ARGV[0];
use constant P_dir => '/home/zzha/my_modENCODE';
use constant Data_dir => 'all_data';
use constant Slink_dir => 'symbolic_links';
my ($lvl1_dir, $lvl2_dir, $lvl3_dir, $lvl4_dir);
open my $fh, "<", $spreadsheet;
<$fh>; #header 
while(my $line = <$fh>) {
    chomp $line;    
    my ($id, 
	$title, 
	$filename, 
	$rel_path,
	$organism,
	$target,
	$tech,
	$format,
	$factor,
	$condition,
	$lvl4_tech,
	$algo,
	$rep,
	$build,
	$std_id) = split "\t", $line;
    next unless defined($factor); # a few ones that has two hop of submissions
    ($lvl1_dir, $lvl2_dir, $lvl3_dir, $lvl4_dir) = ($organism, $target, $tech, $format);
    $condition =~ s/_/-/g; $condition =~ s/ /-/g;
    
    my $bio_dir = gen_bio_dir($factor, $condition);
    my $leaf_dir = ln_dir(P_dir, Slink_dir, $lvl1_dir, $lvl2_dir, $lvl3_dir, $bio_dir, $lvl4_dir);
}

sub gen_bio_dir {
    my ($factor, $condition) = @_;
    
}

sub universal_factor {
    my $factor = shift;
    $factor =~ s/^\s*//g; $factor =~ s/\s*$//g;
    $factor =~ s/_/-/g; $factor =~ s/ /-/g;
    my %map = (
	'BEAF32A and B' => 'beaf-32',
        'BEAF32A and BEAF32B' => 'beaf-32',
	"cap'n collar" => 'cnc',
	"CTCF C-terminus" => 'ctcf',
	"CTCF N-terminus" => 'ctcf',
	'CBP-1' => 'cbp',
	'C-terminal Binding Protein' => 'cbp',
	'H4acTetra' => 'h4actetra',
	'H4tetraac' => 'h4actetra',
	'Histone H3' => 'h3',
	'histone H3' => 'h3',
	'MCM2-7 complex' => 'mcm2-7',
	'MOD(MDG4)67.2' => 'mod(mdg4)',
	'na' => 'no-antibody-control',
	'Not Applicable' => 'no-antibody-control', 
	'PolII' => 'pol2',
	'RNA polII CTD domain unphosophorylated' => 'pol2', 
	'RNA Polymerase II' => 'pol2',
	'RNA polymerase II CTD repeat YSPTSPS' => 'pol2', 
	'SU(HW)' => 'su(hw)',
	'Su(Hw)' => 'su(hw)',
	'trimethylated Lys-36 of histone H3' => 'h3k36me3',
	'Trimethylated Lys-4 of histone H3' => 'h3k4me3',
	'Trimethylated Lys-9 on histone H3' => 'h3k9me3',
	);
    if ( exists $map{$factor} ) {
	$factor = $map{$factor};
    } else {
	$factor = lc($factor);
    }
    return $factor;
}

sub parse_condition {
    my $condition = shift;
    $condition =~ s/^\s*//g; $condition =~ s/\s*$//g;
    my ($strain, $cellline, $devstage, $tissue);
    $strain = $1 if $condition =~ /STRAIN_(.*)?_/;
    $cellline = $1 if $condition =~ /Cell-Line_(.*)?_/;
    $devstage = $1 if $condition =~ /Developmental-Stage_(.*)?_/;
    $tissue = $1 if $condition =~ /Tissue_(.*)?_/;
    return ($strain, $cellline, $devstage, $tissue);
}

sub universal_strain {
}

sub universal_cellline {
}

sub universal_devstage {
}

sub universal_tissue {
}

sub ln_dir {
    my @dirs = @_;
    die if $dirs[0] ne P_dir;
    die if $dirs[1] ne Slink_dir;
    my $dir;
    for (my $i=0; $i<scalar @dirs; $i++) {
	my $tdir = '';
	for (my $j=0; $j<=$i; $j++) {
	    $tdir .= "/" . $dirs[$j];
	}
	mkdir($tdir) unless -e $tdir;
	$dir = $tdir;
    }
    return $dir;
}
