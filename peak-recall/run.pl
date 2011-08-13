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
use Getopt::Long;
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
print "no rep1 ChIP files specified.\n" and die unless scalar @r1_chip;
print "no rep1 input files specified.\n" and die unless scalar @r1_input;
print "not rep2 ChIP files specified although there are rep2 input files.\n" and die if scalar @r2_input && !scalar @r2_chip;
print "not rep2 input files specified although there are rep2 ChIP files.\n" and die if scalar @r2_chip && !scalar @r2_input;
map {print "$_ does not exist!\n" and die unless -e $_} (@r1_chip, @r1_input);
map {print "$_ does not exist!\n" and die unless -e $_} @r2_chip if scalar @r2_chip;
map {print "$_ does not exist!\n" and die unless -e $_} @r2_input if scalar @r2_input;
 
#uniform name/format of the input short read files
my $r1_chip_reads = $out_dir . $name . '_r1_chip.fastq';
my $r2_chip_reads = $out_dir . $name . '_r2_chip.fastq';
my $chip_reads = $out_dir . $name . '_chip.fastq';
my $r1_input_reads = $out_dir . $name . '_r1_input.fastq';
my $r2_input_reads = $out_dir . $name . '_r2_input.fastq';
my $input_reads = $out_dir . $name . '_input.fastq';
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

#do copy if input are symlink
#do unzip if input are zipped
#cat multiple-lanes file into one lane file
run_uniform_input();

if (defined($preprocess) && $preprocess == 1) {
    my $remove_barcode = $ini{PRE_PROCESS}{run_remove_barcode};
    if (defined($remove_barcode) && $remove_barcode == 1) {
	print "pipeline will do preprocess: remove barcode.\n";
	my $cfg = $cfg_dir . 'remove_barcode.ini';
	run_remove_barcode($cfg);
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
	print "need rep2 files to do IDR.\n" and die unless scalar @r2_chip && scalar @r2_input; 
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
    my $script = $root_dir . 'uniform_input.pl';
    print "$script does not exist.\n" and die unless -e $script;
    system(join(" ", ("$script $r1_chip_reads", @r1_chip)));
    system(join(" ", ("$script $r1_input_reads", @r1_input)));
    system(join(" ", ("$script $r2_chip_reads", @r2_chip))) if scalar @r2_chip;
    system(join(" ", ("$script $r2_input_reads", @r2_chip))) if scalar @r2_input;
}

sub run_remove_barcode {
    my ($cfg) = @_;
    tie my %ini, 'Config::IniFiles', (-file => $cfg);
    my $script = $ini{SCRIPT}{remove_barcode};
    print "$script does not exist.\n" and die unless -e $script;
    system("$script -o $r1_chip_reads $r1_chip_reads");
    if (scalar @r2_chip) {
	system("$script -o $r2_chip_reads $r2_chip_reads");
	system("$script -o $chip_reads $r1_chip_reads $r2_chip_reads");
    }
    system("$script -o $r1_input_reads $r1_input_reads");
    if (scalar @r2_input) {
	system("$script -o $r2_input_reads $r2_input_reads");
	system("$script -o $input_reads $r1_input_reads $r2_input_reads");    
    }
}

sub run_bowtie {
    my ($cfg) = @_;
    tie my %ini, 'Config::IniFiles', (-file => $cfg);
    my $bowtie_bin = $ini{BOWTIE}{bowtie_bin};
    print "bowtie binary $bowtie_bin does not exist.\n" unless -e $bowtie_bin;
    my $bowtie_index = $ini{BOWTIE}{bowtie_index};
    my $parameter = $ini{BOWTIE}{parameter};
    system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $r1_chip_reads, $r1_chip_alignment)));
    if (scalar @r2_chip) {
	system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $r2_chip_reads, $r2_chip_alignment)));	
	system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $chip_reads, $chip_alignment)));
    }
    system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $r1_input_reads, $r1_input_alignment)));
    if (scalar @r2_input) {
	system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $r2_input_reads, $r2_input_alignment)));	
	system(join(" ", ($bowtie_bin, $parameter, $bowtie_index, $input_reads, $input_alignment)));
    }
}

sub run_peakranger {
    my ($cfg) = @_;
    tie my %ini, 'Config::IniFiles', (-file => $cfg);
    my $script = $ini{PEAKRANGER}{script};
    print "peakranger binary $script does not exist.\n" unless -e $script;
    my $parameter = $ini{PEAKRANGER}{parameter};
    system("$script -d $r1_chip_alignment -c $r1_input_alignment -o $r1_peak $parameter");
    if (scalar @r2_chip && scalar @r2_input) {
	system("$script -d $r2_chip_alignment -c $r2_input_alignment -o $r2_peak $parameter");
	system("$script -d $chip_alignment -c $input_alignment -o $peak $parameter");
    }
}
