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
my $title = $tagger->get_title();
my $lvl1 = $tagger->get_level1();
my $lvl2 = $tagger->get_level2();
my $lvl3 = $tagger->get_level3();
my $lvl4_factor = $tagger->lvl4_factor();
print "level4 factor is ", $lvl4_factor, "\n";
my $lvl4_condition = $tagger->lvl4_condition();
print "level4 condition is ", $lvl4_condition, "\n";
#my $lvl4_algorithm = '';
#my $replicatesetnum = '';
#my @tags = ($id, $title, $lvl1, $lvl2, $lvl3, $lvl4_factor, $lvl4_condition, $lvl4_algorithm, $replicatesetnum);
my @tags = ($id, $title, $lvl1, $lvl2, $lvl3, $lvl4_factor, $lvl4_condition);
 
open my $tagfh, ">", $output_file;
print $tagfh join("\t", ('DCC id', 'Title', 'Data File', 'Data Filepath', 'Level 1 <organism>', 'Level 2 <Target>', 'Level 3 <Technique>', 'Level 4 <File Format>', 'Filename <Factor>', 'Filename <Condition>', 'Filename <Technique>', 'Filename <ReplicateSetNum>', 'Filename <ChIP>', 'Filename <label>', 'Filename <Build>', 'Filename <Modencode ID>')), "\n";
print "try to get raw data...";
my ($raw, $raw_type, $raw_group, $raw_ab, $raw_label);
if (defined($tagger->get_seq_slot)) {
    ($raw, $raw_type, $raw_group, $raw_ab, $raw_label) = $tagger->get_raw_data(1);
} else {
    ($raw, $raw_type, $raw_group, $raw_ab, $raw_label) = $tagger->get_raw_data();
}
print "done.\ntry to get intermediate data...";
my ($im, $im_type, $im_group, $im_ab) = $tagger->get_intermediate_data();
print "done\ntry to get interpret data...";
my ($ip, $ip_type, $ip_group) = $tagger->get_interprete_data();
print "done\n";
print_tag_spreadsheet(@tags, $tagfh, $raw, $raw_type, $raw_group, $raw_ab, $raw_label);
print_tag_spreadsheet(@tags, $tagfh, $im, $im_type, $im_group, $im_ab);
print_tag_spreadsheet(@tags, $tagfh, $ip, $ip_type);
close $tagfh;

sub print_tag_spreadsheet {
    #my ($tagfh, $data, $data_type, $data_groups, $id, $title, $lvl1, $lvl2, $lvl3, $lvl4_factor, $lvl4_condition) = @_;
    my ($id, $title, $lvl1, $lvl2, $lvl3, $lvl4_factor, $lvl4_condition, $tagfh, $data, $data_type, $data_groups, $ab, $label) = @_;
    for (my $i=0; $i<scalar @$data; $i++) {
	my ($file, $dir, $suffix) = fileparse($data->[$i]);
	my $t = $file . $suffix;
	my $u = defined($data_groups) ? $data_groups->[$i] : 'all';
	my $v = defined($ab) ? $ab->[$i] : undef;
	my $w = defined($label) ? $label->[$i] : undef;
	print $tagfh join("\t", ($id, $title, $t, $data->[$i], $lvl1, $lvl2, $lvl3, $data_type->[$i], $lvl4_factor, $lvl4_condition, $lvl3, $u, $v, $w, $lvl1));
	print $tagfh "\t";
	print $tagfh 'modENCODE_', $id;
	#printf $tagfh '%s%05s', 'MDENC', $id;
	print $tagfh "\n";
    } 
}

sub usage {
    my $usage = qq[$0 -id <unique_submission_id> -o <output_dir> [-cfg <config_file>]];
    print "Usage: $usage\n";
    print "option e: use geo/sra id instead of filename for raw data.\n";
    exit 2;
} 
