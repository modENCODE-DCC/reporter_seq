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
use ModENCODE::Parser::LWChado;
use ModENCODE::Tagger;

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

my $dbname = $ini{database}{dbname};
my $dbhost = $ini{database}{host};
my $dbusername = $ini{database}{username};
my $dbpassword = $ini{database}{password};
#search path for this dataset, this is fixed by modencode chado db
my $schema = $ini{database}{pathprefix}. $unique_id . $ini{database}{pathsuffix} . ',' . $ini{database}{schema};
print "connecting to database ...";
$reader = new ModENCODE::Parser::LWChado({
    'dbname' => $dbname,
    'host' => $dbhost,
    'username' => $dbusername,
    'password' => $dbpassword,
});
my $experiment_id = $reader->set_schema($schema);
print "database connected.\n";
print "loading experiment ...";
$reader->load_experiment($experiment_id);
$experiment = $reader->get_experiment();
print "done.\n";

my $tagger = new GEO::Tagger({
     'unique_id' => $unique_id,
     'reader' => $reader,
     'experiment' => $experiment,
     'config' => $config,
});
$tagger->set_all();

sub usage {
    my $usage = qq[$0 -unique_id <unique_submission_id> -out <output_dir> [-config <config_file>]];
    print "Usage: $usage\n";
} 
