#!/usr/bin/perl
use strict;

my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir;
}

use Config::IniFiles;
use Getopt::Long qw[GetOptions];
#default config files
my $cfg_dir = $root_dir . 'config/';
my $cfg = $cfg_dir . 'pipeline.ini';
#uniform name for all intermediate files;
#do we need timestamp to make it unique?
my $name;
#create cfg for each TF run to override the default
my $option = GetOptions ("cfg:s" => \$cfg,
			 "name=s" => \$name);
usage() unless -e $cfg;
usage() unless defined($name);

tie my %ini, 'Config::IniFiles', (-file => $cfg);

#parse [PIPELINE] session to understand what need to run
my $preprocess = $ini{PIPELINE}{run_preprocess};
my $align = $ini{PIPELINE}{run_alignment};
my $peakcall = $ini{PIPELINE}{run_peak_calling};
my $postprocess = $ini{PIPELINE}{run_postprocess};
#make sure dirs exist and end with '/'
my $out_dir = $ini{OUTPUT}{dir};
my $log_dir = $ini{OUTPUT}{log};
mkdir($out_dir) unless -e $out_dir;
mkdir($log_dir) unless -e $log_dir;
$out_dir .= '/' unless $out_dir =~ /\/$/;
$log_dir .= '/' unless $log_dir =~ /\/$/;

#input files
my @r1_chip = split /\s+/, $ini{INPUT}{r1_ChIP};
my @r2_chip = split /\s+/, $ini{INPUT}{r2_ChIP} if exists $ini{INPUT}{r2_ChIP};
my @r1_input = split /\s+/, $ini{INPUT}{r1_input};
my @r2_input = split /\s+/, $ini{INPUT}{r2_input} if exists $ini{INPUT}{r2_input};
#check files exist, to do!
die "no rep1 ChIP files specified.\n" unless scalar @r1_chip;
die "no rep1 input files specified.\n" unless scalar @r1_input;
die "not rep2 ChIP files specified although there are rep2 input files.\n" if scalar @r2_input && !scalar @r2_chip;
die "not rep2 input files specified although there are rep2 ChIP files.\n" if scalar @r2_chip && !scalar @r2_input;
map {die "$_ does not exist!\n" unless -e $_} (@r1_chip, @r1_input);
map {die "$_ does not exist!\n" unless -e $_} @r2_chip if scalar @r2_chip;
map {die "$_ does not exist!\n" unless -e $_} @r2_input if scalar @r2_input;
 
#uniform name/format of the input short read files
my $r1_chip_reads = $out_dir . $name . '_r1_chip.fastq';
my $r2_chip_reads = $out_dir . $name . '_r2_chip.fastq';
#my $chip_reads = $out_dir . $name . '_chip.fastq';
my $r1_input_reads = $out_dir . $name . '_r1_input.fastq';
my $r2_input_reads = $out_dir . $name . '_r2_input.fastq';
#my $input_reads = $out_dir . $name . '_input.fastq';
#uniform name/format of the alignment files;
my $r1_chip_alignment = $out_dir . $name . '_r1_chip.sam';
my $r2_chip_alignment = $out_dir . $name . '_r2_chip.sam';
my $chip_alignment = $out_dir . $name . '_chip.sam';
my $r1_input_alignment = $out_dir . $name . '_r1_input.sam';
my $r2_input_alignment = $out_dir . $name . '_r2_input.sam';
my $input_alignment = $out_dir . $name . '_input.sam';
#uniform name for peak files;
my $r1_peak = $out_dir . $name . '_r1_peak';
my $r2_peak = $out_dir . $name . '_r2_peak';
my $peak = $out_dir . $name . '_peak';

if (defined($preprocess) && $preprocess == 1) {
    my $remove_barcode = $ini{PRE_PROCESS}{run_remove_barcode};
    if (defined($remove_barcode) && $remove_barcode == 1) {
	print "pipeline will do preprocess: remove barcode.\n";
	run_uniform_input({rm_barcode =>1});
    } else {
	run_uniform_input();
    }
}

if (defined($align) && $align == 1) {
    my $run_bowtie = $ini{ALIGNMENT}{run_bowtie};
    if (defined($run_bowtie) && $run_bowtie == 1) {
	print "pipeline will do alignment: bowtie.\n";
	my $cfg = $cfg_dir . 'bowtie.ini';
	run_bowtie($cfg);
    }
}

if (defined($peakcall) && $peakcall == 1) {
    my $run_peakranger = $ini{PEAK_CALLING}{run_peakranger};
    if (defined($run_peakranger) && $run_peakranger == 1) {
	print "pipeline will do peak call: peakranger.\n";
	my $cfg = $cfg_dir . 'peakranger.ini';
	run_peakranger($cfg);
    }
}

if (defined($postprocess) && $postprocess == 1) {
    my $run_idr = $ini{POSTPROCESS}{run_idr};
    if (defined($run_idr) && $run_idr == 1) {
	die "need rep2 files to do IDR.\n" unless scalar @r2_chip && scalar @r2_input; 
	print "pipeline will do postprocess: idr.\n";
	my $cfg = $cfg_dir . 'idr.ini';
	run_idr($cfg);
    }
}

sub usage {
    my $usage = qq[$0 -name <name> [-cfg <cfg_file>]];
    print "Usage: $usage\n";
}

sub run_uniform_input {
    my ($opt) = @_;
    #do copy if input are symlink
    #do unzip if input are zipped
    #cat multiple-lanes file into one lane file
    #remove barcode if necessary
    my $script = $root_dir . 'uniform_input.pl';
    die "$script does not exist.\n" unless -e $script;
    my $rm_barcode = "";
    $rm_barcode = '-rm_barcode 1' if defined($opt) && $opt->{rm_barcode} == 1;
    system(join(" ", ($script, $rm_barcode, $r1_chip_reads, @r1_chip)));
    system(join(" ", ($script, $rm_barcode, $r1_input_reads, @r1_input)));
    system(join(" ", ($script, $rm_barcode, $r2_chip_reads, @r2_chip))) if scalar @r2_chip;
    system(join(" ", ($script, $rm_barcode, $r2_input_reads, @r2_chip))) if scalar @r2_input;
}

sub run_bowtie {
    my ($cfg) = @_;
    tie my %ini, 'Config::IniFiles', (-file => $cfg);
    my $bowtie_bin = $ini{BOWTIE}{bowtie_bin};
    die "bowtie binary $bowtie_bin does not exist.\n" unless -e $bowtie_bin;
    my $bowtie_index = $ini{BOWTIE}{bowtie_index};
    my $parameter = $ini{BOWTIE}{parameter};
    system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $r1_chip_reads, $r1_chip_alignment)));
    if (scalar @r2_chip) {
	system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $r2_chip_reads, $r2_chip_alignment)));	
	system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, join(",", ($r1_chip_reads, $r2_chip_read)), $chip_alignment)));
    }
    system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $r1_input_reads, $r1_input_alignment)));
    if (scalar @r2_input) {
	system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $r2_input_reads, $r2_input_alignment)));	
	system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, join(",", ($r1_input_reads, $r2_input_reads)), $input_alignment)));
    }
}

sub run_peakranger {
    my ($cfg) = @_;
    tie my %ini, 'Config::IniFiles', (-file => $cfg);
    my $script = $ini{PEAKRANGER}{script};
    die "peakranger binary $script does not exist.\n" unless -e $script;
    my $parameter = $ini{PEAKRANGER}{parameter};
    system("$script -d $r1_chip_alignment -c $r1_input_alignment -o $r1_peak $parameter");
    if (scalar @r2_chip && scalar @r2_input) {
	system("$script -d $r2_chip_alignment -c $r2_input_alignment -o $r2_peak $parameter");
	system("$script -d $chip_alignment -c $input_alignment -o $peak $parameter");
    }
}
