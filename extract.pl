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
use File::Spec;
use ModENCODE::Parser::LWChado;
use GEO::Tagger;

print "initializing...\n";
#parse command-line parameters
my ($unique_id, $output_dir, $config);
#default config
$config = $root_dir . 'chado2GEO.ini';
my $option = GetOptions ("unique_id=s"     => \$unique_id,
                         "out=s"           => \$output_dir,
                         "config=s"        => \$config) or usage();
usage() if (!$unique_id or !$output_dir);
usage() unless -w $output_dir;
usage() unless -e $config;

#get config
my %ini;
tie %ini, 'Config::IniFiles', (-file => $config);

#report directory
$output_dir = File::Spec->rel2abs($output_dir);
#make sure $report_dir ends with '/'
$output_dir .= '/' unless $output_dir =~ /\/$/;

my $dbname = $ini{database}{dbname};
my $dbhost = $ini{database}{host};
my $dbusername = $ini{database}{username};
my $dbpassword = $ini{database}{password};
#search path for this dataset, this is fixed by modencode chado db
my $schema = $ini{database}{pathprefix}. $unique_id . $ini{database}{pathsuffix} . ',' . $ini{database}{schema};
print "connecting to database ...";
my $reader = new ModENCODE::Parser::LWChado({
      'dbname' => $dbname,
      'host' => $dbhost,
      'username' => $dbusername,
      'password' => $dbpassword,
});
my $experiment_id = $reader->set_schema($schema);
print "database connected.\n";
print "loading experiment ...";
$reader->load_experiment($experiment_id);
my $experiment = $reader->get_experiment();
print "done.\n";

my $tagger = new GEO::Tagger({
      'unique_id' => $unique_id,
      'reader' => $reader,
      'experiment' => $experiment,
      'config' => \%ini,
});
$tagger->set_all();
my @raw = $tagger->get_raw_data();
my @inm = $tagger->get_intermediate_data();
my @inp = $tagger->get_interprete_data();
my @dfs = (@raw, @inm, @inp);
for my $df (@dfs) {
    $df, $unique_id, $tagger->get_data_type, $tagger->get_assay_type
}

sub level1 {
    my $tagger = shift;
    my $org = $tagger->get_organism();
    return $org;
#    if ($org eq 'Caenorhabditis elegans') {
#	return 'Cele_WS190';
#    } elsif ($org eq 'Drosophila melanogaster') {
#	return 'Dmel_r5.4';
#    } elsif ($org eq 'Drosophila pseudoobscura') {
#	return 'Dpse_r2.4';
#    } elsif ($org eq 'Drosophila mojavensis') {
#	return 'Dmoj_r1.3';
#    }
}

sub level3 {
    my $tagger = shift;
    my %map = ('Alignment' => 'Alignment',
	       'Assay' => 'Assay',
	       'CAGE' => 'CAGE',
	       'cDNA sequencing' => 'cDNA sequencing',
	       'ChIP-chip' => 'ChIP-chip',
	       'ChIP-seq' => 'ChIP-seq',
	       'Computational annotation' => 'integrated-gene-model',
	       'DNA-seq' => 'DNA-seq',
	       'Mass spec' => 'Mass-spec', 
	       'RACE' => 'RACE',
	       'RNA-seq' => 'RNA-seq',
	       'RNA-seq, RNAi' =>
	       'RTPCR' => 'RT-PCR',
	       #'Sample creation' =>
	       #'sample creation' =>
	       'tiling array: DNA' => 'DNA-tiling-array',
	       'tiling array: RNA' => 'RNA-tiling-array',
	);
    my $at = $tagger->get_assay_type;
    if (defined($at)) {
	return $map{$at} if exists $map{$at};
    }
}

sub usage {
    my $usage = qq[$0 -unique_id <unique_submission_id> -out <output_dir> [-config <config_file>]];
    print "Usage: $usage\n";
    exit 2;
} 
