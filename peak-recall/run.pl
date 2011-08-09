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
print $root_dir;
my $cfg = $root_dir . 'config/pipeline.ini';
my $name;
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
my @pipeline;

if (defined($preprocess) && $preprocess == 1) {
    my $rm_barcode = $ini{PRE_PROCESS}{run_remove_barcode};
    if (defined($rm_barcode) && $rm_barcode == 1) {
	my $rm_barcode_script = $ini{REMOVE_BARCODE}{script};
	push @pipeline, $rm_barcode_script;
	print "pipeline will remove barcode, the script is at $rm_barcode_script\n";
    }
}

if (defined($align) && $align == 1) {
    my $run_bowtie = $ini{ALIGNMENT}{run_bowtie};
    if (defined($run_bowtie) && $run_bowtie == 1) {
	#my 
    }
}

if (defined($peakcall) && $peakcall == 1) {
    my


sub usage
{
}
