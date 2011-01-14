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
use File::Basename;
use ModENCODE::Parser::LWChado;
use GEO::Annotator;

print "initializing...\n";
#parse command-line parameters
my ($unique_id, $output_dir, $config, $geo_id_file);
#default config
$config = $root_dir . 'chado2GEO.ini';
my $option = GetOptions ("id=s"     => \$unique_id,
                         "o=s"      => \$output_dir,
                         "cfg=s"    => \$config,
			 "g=s"      => \$geo_id_file) or usage();
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
my $output_file = $output_dir . $unique_id . '.soft';
print "output file is $output_file\n";

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

print "generate soft file ...";
open my $seriesFH, ">", $output_file;
open my $geoFH, "<", $geo_id_file || die;
my $annotator = new GEO::Annotator({
    'geo' => $geoFH,
    'unique_id' => $unique_id,
    'reader' => $reader,
    'experiment' => $experiment,
    'config' => \%ini,
    'seriesFH' => $seriesFH
});

$annotator->set_all();
$annotator->chado2series();
close $seriesFH;
close $geoFH;
print "done\n";

sub usage {
    my $usage = qq[$0 -id <unique_submission_id> -o <output_dir> -g <geo_id_file> [-cfg <config_file>]];
    print "Usage: $usage\n";
    print "option g: the file contains all geo/sra id known to DCC.\n";
    exit 2;
} 
