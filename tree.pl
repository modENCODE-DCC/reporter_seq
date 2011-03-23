#!/usr/bin/perl
use strict;
use File::Path;
use Data::Dumper;
use File::Basename;

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
use constant Filename_separator => ';';
use constant Tag_value_separator => '_';
my ($lvl1_dir, $lvl2_dir, $lvl3_dir, $lvl4_dir);
open my $fh, "<", $spreadsheet;
<$fh>; #header
my @nr = ();
my @r = (); 
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
	$rep,
	$chip,
	$label,
	$build,
	$std_id) = split "\t", $line;
    my ($lvl1_dir, $lvl2_dir, $lvl3_dir, $lvl4_dir) = ($organism, $target, $tech, $format);    
    $factor = universal_factor($factor);
    my ($strain, $cellline, $devstage, $tissue) = parse_condition($condition);
    #print "$id Strain: $strain Cell Line: $cellline Devstage: $devstage Tissue: $tissue\n";
    #unless (defined($strain) || defined($cellline) || defined($devstage) || defined($tissue)) {
	#print $id, "\n";
    #}
    my @bio_dir = gen_bio_dir($factor, $strain, $cellline, $devstage, $tissue);
#    rmtree(P_dir) if -e P_dir; #why it does not work?!
    my $leaf_dir = ln_dir(P_dir, Slink_dir, $lvl1_dir, $lvl2_dir, $lvl3_dir, $lvl4_dir, @bio_dir);

    my $universal_filename = std_filename($factor, $condition, $tech, $rep, $chip, $label, $build, $std_id);
    my $universal_ext_filename = format_dirname2($universal_filename, $filename);
    $universal_ext_filename .= sfx($format);
    my $ln_file = $leaf_dir . $universal_ext_filename;
    print $ln_file, "\n";
    if (scalar(grep {$_ eq $ln_file} @nr)) {
	print "repeat $ln_file\n";
    } else {
	push @nr, $ln_file;
    }

    #print $ln_file, "##link file\n";
    my $data_file = Data_dir . "/" . "$id" . "_". $filename;
    chdir P_dir;
    mkdir(Data_dir);
    symlink($rel_path, $data_file);  
    symlink($data_file, $ln_file);
}
#map {print $_, "\n"} @nr;

sub std_filename {
    my ($factor, $condition, $tech, $rep, $chip, $label, $build, $std_id) = @_ ;
    $rep+=1; 
    #$rep = 'ReplicateSet-' . $rep;
    $rep = 'Rep-' . $rep;
    my $filename = join(Filename_separator, ($factor, $condition, $tech, $rep));
    if (defined($chip) && $chip ne '') {
	#my $t = join(Tag_value_separator, ('ChIP-or-input', $chip));
	#$filename = join(Filename_separator, ($filename, $t));
	$filename = join(Filename_separator, ($filename, $chip));
    }
    if (defined($label) && lc($label) ne 'biotin' && $label ne '') {
	#my $t = join(Tag_value_separator, ('Label', $label));
	#$filename = join(Filename_separator, ($filename, $t));
	$filename = join(Filename_separator, ($filename, $label));
    }
    $filename = join(Filename_separator, ($filename, $build, $std_id));
    return $filename;
}

sub gen_bio_dir {
    my ($factor, $strain, $cellline, $devstage, $tissue) = @_;
    my @rna = ('5-prime-utr', 'small-rna', '3-prime-utr', 'utr', 'splice-junction', 'transfrag', 'polya-rna', 'total-rna');
    if (scalar grep {$_ eq $factor} @rna) {
	if (defined($cellline)) {
	    #print $cellline, "\n";
	    $cellline = universal_cellline($cellline);
	    #1182-4H
	    #CME-L1
	    #CME-W1-Cl.8+
	    #CME W2
	    #GM2
	    #Kc167
	    #Kc-Rubin
	    #Mbn2
	    #ML-DmBG1-c1
	    #ML-DmBG2-c2
	    #ML-DmBG3-c2
	    #ML-DmD11
	    #ML-DmD16-c3
	    #ML-DmD17-c3
	    #ML-DmD20-c2
	    #ML-DmD20-c5
	    #ML-DmD21
	    #ML-DmD32
	    #ML-DmD4-c1
	    #ML-DmD8
	    #ML-DmD9
	    #OvarySomaticSheet
	    #S1
	    #S2-DRSC
	    #S2-NP
	    #S2R+
	    #S2-Rubin
	    #S3
	    #Sg4
	    #$cellline = format_dirname($cellline);
	    return ($cellline);
	} else {
	    if (defined($tissue)) {
		#print "#$tissue\n";
#Adult testis
#BAG neurons (embryonic)
#body wall muscle
#CEPsh (YA)
#coelomocytes
#Coelomocytes (L2)
#Dmel Female heads
#Dmel Male heads
#Dmoj Female heads
#Dmoj Male heads
#dopaminergic neurons (embryonic)
#Dopaminergic neurons (L3-L4)
#Dpse Female heads
#Dpse Male heads
#embryo-AVA
#embryo-AVE
#Excretory cell (L2)
#Female body
#Female heads
#GABA neurons (embryonic)
#GABA neurons (L2)
#germ line precursor (embryonic)
#Glutamate receptor expressing neurons (L2)
#Gonad
#hypodermis
#hypodermis (L3-L4)
#Imaginal disc
#intestinal cells
#Intestine (L2)
#L2-A-class
#Male body
#Male heads
#panneural
#Pan-neural (L2)
#pharyngeal muscle
#PVC neurons (embryonic)
#PVD OLLs (L3-L4)
#reference (early embryo)
#reference (embryo)
#reference (L2)
#reference (L3-L4)
#reference (YA)
		$tissue = universal_tissue($tissue);
		#$tissue = format_dirname($tissue);
		return ($tissue);
	    } else {
		#print $strain, "\n";
		#print $devstage, "\n";
#Canton S
#daf-11(m47)
#daf-2(e1370)
#daf-7(e1372)
#daf-9(m540)
#dpy28(y1)
#GR1373
#him-8(e1489)
#JK1107
#MT10430
#N2
#Oregon-R
#spe-9(hc88)
#SS104
#TX189
#w1118
#Y cn bw sp
		$strain = universal_strain($strain);
#1st instar larvae
#2-18hr embryo
#2-4 day old pupae
#3rd instar larvae
#Adult 20dC 70hr post-L1
#Adult 23dC 12 days post-L4
#Adult 23dC 5 days post-L4
#Adult Female
#Adult female, eclosion + 1 day
#Adult female, eclosion + 30 days
#Adult female, eclosion + 5 days
#Adult Male
#Adult male, eclosion + 1 day
#Adult male, eclosion + 30 days
#Adult male, eclosion + 5 days
#Adult males 20dC 70hr post-L1
#Adult spe-9(hc88) 23dC 8 days post-L4 molt
#dauer daf-2(el370) 25dC 91hrs post-L1
#dauer entry daf-2(el370) 25dC 48 hrs post-L1
#dauer exit daf-2(el370) 25dC 91hrs 15dC 12hrs post-L1
#Dauer Larvae
#early embryo
#Embryo 0-12h
#Embryo 0-1h
#Embryo 0-2h
#Embryo 0-4h
#Embryo 10-12h
#Embryo 12-14h
#Embryo 12-16h
#Embryo 12-24h
#Embryo 14-16h
#Embryo 16-18h
#Embryo 16-20h
#Embryo 18-20h
#Embryo 20-22h
#Embryo 20-24h
#Embryo 22-24h
#Embryo 2-4h
#Embryo 2-6h
#Embryo 4-6h
#Embryo 4-8h
#Embryo 6-10h
#Embryo 6-8h
#Embryo 8-10h
#Embryo 8-12h
#embryo him-8(e1480) 20dC
#L1
#L1 20dC 8hr post-L1
#L2
#L2 20dC 20hr post-L1
#L3
#L3 20dC 30hr post-L1
#L3 stage larvae, 12 hr post-molt
#L3 stage larvae, clear gut PS(7-9) stage
#L3 stage larvae, dark blue gut PS(1-2) stage
#L3 stage larvae, light blue gut PS(3-6) stage
#L4 20dC 45hr post-L1
#larva mid-L1 25dC 4.0 hrs post-L1
#larva mid-L2 25dC 17.75 hrs post-L1
#larva mid-L3 25dC 26.75 hrs post-L1
#larva mid-L4 25dC 34.25 hrs post-L1
#late embryo 20dC 4.5 hrs post-early embryo
#Lin-35(n745) larva mid-L1 25dC 4.0 hrs post-L1
#Male larva mid-L4 25dC 30 hrs post-L1
#Mass spec
#mid-L1 20dC 4hrs post-L1
#mid-L2 20dC 14hrs post-L1
#mid-L3 20dC 25hrs post-L1
#mid-L4 20dC 36hrs post-L1
#Mixed Adult 7-11 day
#Mixed Embryos 0-24h
#Mixed embryos 20dC
#Mixed Population Worms
#Mixed stage of embryos 20dC
#Older embryos (12-cell+ stage)
#one cell stage embryos
#post-gastrulation embryos
#Pupae
#Pupae, WPP + 2 days
#Pupae, WPP + 3 days
#Pupae, WPP + 4 days
#two-to-four cell stage embryos
#White prepupae (WPP)
#WPP + 12 hr
#WPP + 24 hr
#yAdult 20dC 48hrs post-L1
#yAdult 23dC DAY0post-L4 molt
#yAdult Males 23dC
#young Adult 25dC
#Young Adult (pre-gravid) 25dC 46 hrs post-L1
		$devstage = universal_devstage($devstage);
		#$strain = format_dirname($strain);
		$devstage = format_dirname($devstage);
		return ($strain, $devstage);
	    }
	}
    } else {
	$devstage = format_dirname($devstage);
	return ($factor, $devstage);
    }
}

sub universal_factor {
    my $factor = shift;
    $factor =~ s/^\s*//g; $factor =~ s/\s*$//g;
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
    $dir =~ s/,//g;
    return $dir;
}

sub format_dirname2 {
    my ($dir, $name) = @_;
    $dir =~ s/\///g; #absolutely needed
    $dir =~ s/\(/ /g; #absolutely needed
    $dir =~ s/\)/ /g; #absolutely needed
    $dir =~ s/,//g;  #absolutely needed
    $dir =~ s/ +/-/g; #absolutely needed
    $dir =~ s/\.//g; #absolutely needed 
    #this version will creat 5995 symbolic link out of 6035 files
    #since the filename generated is tooo long for my poor 32bit laptop.
    #if I do s/ +//g, then 6019 slink created.
    my $base;
    my $rtn_name;
    if (defined($name)) {
	my ($file, $dirx, $suffix) = fileparse($name, qr/\.[^.]*/);
	#print $suffix, "\n";
	if (scalar grep {lc($suffix) eq $_} ('.zip', '.bz2', '.gz')) {
	    my ($zfile, $zdir, $zsuffix) = fileparse($file, qr/\.[^.]*/);
	    $base = $zfile;
	} else {
	    $base = $file;
	}
	$rtn_name = $dir . Filename_separator . $base;
    } else {
	$rtn_name = $dir;
    }
    return $rtn_name;
}

sub parse_condition {
    my $condition = shift;
    my %map;
    $condition =~ s/^\s*//g; $condition =~ s/\s*$//g;
    my @cds = split(Filename_separator, $condition);
    for my $cd (@cds) {
	my ($k, $v) = split(Tag_value_separator, $cd);
	$map{$k} = $v;
    }
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
	    my $t = $dirs[$j];
	    #$t = format_dirname($t);
	    $tdir .= $t . "/";
	}
	mkdir($tdir) unless -e $tdir;
	$dir = $tdir;
    }
#    print $dir, "\n"; #created right number of dir.
    return $dir;
}

sub sfx {
    my $format = shift;
    my ($category, $sfks) = split "_", $format;
    return ".$sfks";    
}
