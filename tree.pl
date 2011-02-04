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
    next unless (defined($target) && $target !~ /^\s*$/);
    next unless (defined($tech) && $tech !~ /^\s*$/);
    my ($lvl1_dir, $lvl2_dir, $lvl3_dir, $lvl4_dir) = ($organism, $target, $tech, $format);

    
    $factor = universal_factor($factor);
    my ($strain, $cellline, $devstage, $tissue) = parse_condition($condition);
    #print "$id Strain: $strain Cell Line: $cellline Devstage: $devstage Tissue: $tissue\n";
    #unless (defined($strain) || defined($cellline) || defined($devstage) || defined($tissue)) {
	#print $id, "\n";
    #}
    my @bio_dir = gen_bio_dir($factor, $strain, $cellline, $devstage, $tissue);
    my $leaf_dir = ln_dir(P_dir, Slink_dir, $lvl1_dir, $lvl2_dir, $lvl3_dir, $lvl4_dir, @bio_dir);
    $algo = "" unless defined($algo);
    $rep = "" unless defined($rep);
    my $universal_filename = join(":", ($factor, $condition, $tech, $algo, $rep, $build, $std_id));
    $universal_filename = format_dirname($universal_filename);
    my $ln_file = $leaf_dir . $universal_filename;
    chdir P_dir;
    mkdir(Data_dir);
    my $data_file = Data_dir . "/". $filename;
    symlink($rel_path, $data_file);  
    symlink($data_file, $ln_file);
}

sub gen_bio_dir {
    my ($factor, $strain, $cellline, $devstage, $tissue) = @_;
    my @rna = ('5-prime-utr', 'small-rna', '3-prime-utr', 'utr', 'splice-junction', 'transfrag', 'polya-rna', 'total-rna');
    if (scalar grep {$_ eq $factor} @rna) {
	if (defined($cellline)) {
	    #print $cellline, "\n";
	    $cellline = universal_cellline($cellline);
	    return ($cellline);
	} else {
	    if (defined($tissue)) {
		#print $tissue, "\n";
		$tissue = universal_tissue($tissue);
		return ($tissue);
	    } else {
		#print $strain, "\n";
		#print $devstage, "\n";
		$strain = universal_strain($strain);
		$devstage = universal_devstage($devstage);
		return ($strain, $devstage);
	    }
	}
    } else {
	return ($factor, $devstage);
    }
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

sub format_dirname {
    my $dir = shift;
    $dir =~ s/\(//g;
    $dir =~ s/\)//g;
    $dir =~ s/,//g;
    $dir =~ s/ +/-/g;
    return $dir;
}

sub parse_condition {
    my $condition = shift;
    $condition =~ s/^\s*//g; $condition =~ s/\s*$//g;
    my %map = split("_", $condition);
    my ($strain, $cellline, $devstage, $tissue) = (
	$map{'Strain'}, 
	$map{'Cell-Line'}, 
	$map{'Developmental-Stage'},
	$map{'Tissue'},
	);
    #$strain = $1 if $condition =~ /Strain_(.*?)_/;
    #$cellline = $1 if $condition =~ /Cell-Line_(.*?)_/;
    #$devstage = $1 if $condition =~ /Developmental-Stage_(.*?)_/;
    #$tissue = $1 if $condition =~ /Tissue_(.*?)_/;
    return ($strain, $cellline, $devstage, $tissue);
}

sub universal_strain {
    my $strain = shift;
    return $strain;
}

sub universal_cellline {
    my $cellline = shift;
    return $cellline;
}

sub universal_devstage {
    my $devstage = shift;
    my %map = (
	'E0-4' => 'Embryo 0-4h',
	'E12-16' => 'Embryo 12-16h',
	'E16-20' => 'Embryo 16-20h',
	'E20-24' => 'Embryo 20-24h',
	'E4-8' => 'Embryo 4-8h',
	'E8-12' => 'Embryo 8-12h',
	'Embryo 22-24hSC' => 'Embryo 22-24h',
	'L1 stage larvae' => 'L1',
	'L2 stage larvae' => 'L2',
	);
    if ( exists $map{$devstage} ) {
	return $map{$devstage};
    } else {
	return $devstage;
    }
}

sub universal_tissue {
    my $tissue = shift;
    return $tissue;
}

sub ln_dir {
    my @dirs = @_;
    die if $dirs[0] ne P_dir;
    die if $dirs[1] ne Slink_dir;
    my $dir;
    for (my $i=0; $i<scalar @dirs; $i++) {
	my $tdir = '';
	for (my $j=0; $j<=$i; $j++) {
	    my $t = format_dirname($dirs[$j]);
	    $tdir .= $t . "/";
	}
	mkdir($tdir) unless -e $tdir;
	$dir = $tdir;
    }
    return $dir;
}
