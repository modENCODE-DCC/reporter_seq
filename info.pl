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
use GEO::Tagger;

print "initializing...\n";
#parse command-line parameters
my ($unique_id, $output_dir, $config);
#default config
$config = $root_dir . 'chado2GEO.ini';
my $option = GetOptions ("id=s"     => \$unique_id,
                         "o=s"      => \$output_dir,
                         "cfg=s"    => \$config) or usage();
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
my $output_file = $output_dir . $unique_id .'_tag.csv';
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

my $tagger = new GEO::Tagger({
      'unique_id' => $unique_id,
      'reader' => $reader,
      'experiment' => $experiment,
      'config' => \%ini,
});
$tagger->set_all();
my $id = $tagger->get_unique_id();
my $project = $tagger->get_project();
my $title = $tagger->get_title();
my $source_name_slot = $tagger->get_source_name_slot();
my $sample_name_slot = $tagger->get_sample_name_slot();
my $extract_name_slot = $tagger->get_extract_name_slot();
my $hybridization_name_slot = $tagger->get_hybridization_name_slot();
my $replicate_group_slot = $tagger->get_replicate_group_slot();
my $last_extraction_slot = $tagger->get_last_extraction_slot();
print join("\t", ($id, $project, $title, $source_name_slot, $sample_name_slot, $extract_name_slot, $hybridization_name_slot, $replicate_group_slot, $last_extraction_slot)), "\n";
sub usage {
    my $usage = qq[$0 -id <unique_submission_id> -o <output_dir> [-cfg <config_file>]];
    print "Usage: $usage\n";
    exit 2;
} 
