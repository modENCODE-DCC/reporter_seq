#!/usr/bin/perl

use strict;

my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir;
}

use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Cookies;
use File::Basename;
use File::Copy;
use File::Spec;
use Net::FTP;
use Mail::Mailer;
use Config::IniFiles;
use Getopt::Long;
use Digest::MD5;
use ModENCODE::Parser::LWChado;
use GEO::LWReporter;
use GEO::Geo;
use GEO::Gsm;

my ($dcc_id_file, $output_dir, $config);
$config = $root_dir . 'geoid.ini';
my $option = GetOptions ("id=s"            => \$dcc_id_file,
			 "out=s"           => \$output_dir,
			 "config=s"        => \$config);

my %ini;
tie %ini, 'Config::IniFiles', (-file => $config);

my @dcc_ids = get_dcc_ids($dcc_id_file);

my $dbname = $ini{database}{dbname};
my $dbhost = $ini{database}{host};
my $dbusername = $ini{database}{username};
my $dbpassword = $ini{database}{password};
my $reader = new ModENCODE::Parser::Chado({
    'dbname' => $dbname,
    'host' => $dbhost,
    'username' => $dbusername,
    'password' => $dbpassword});

my $geo_reader = new GEO::Geo({
    'config' => \%ini});
print "geo reader ready\n";

for my $unique_id (@dcc_ids) {
    print "# submission $unique_id #\n";
    print "connecting to database ...";
    #search path for this dataset, this is fixed by modencode chado db
    my $schema = $ini{database}{pathprefix}. $unique_id . $ini{database}{pathsuffix} . ',' . $ini{database}{schema};
    my $experiment_id = $reader->set_schema($schema);
    print "connected db $dbname.\n";
    print "loading experiment ...";
    $reader->load_experiment($experiment_id);
    my $experiment = $reader->get_experiment();
    print "done.\n";
    my $reporter = new GEO::Reporter({
        'unique_id' => $unique_id,
        'reader' => $reader,
        'experiment' => $experiment,
    });
    print "reporter done.\n";
    $reporter->get_all();
    my @fastq_files = $reporter->get_fastq_files();
    my @geo_ids = $reporter->get_geo_ids();
    my ($sdrf_fastq_found, $sdrf_geo_id_found);
    if ( scalar @fastq_files == 0 ) {
	print "no fastq file in sdrf.\n"
    } else {
	print "fastq files in sdrf:\n";
	$sdrf_fastq_found = 1;
	print @fastq_files;
    }
    if ( scalar @geo_ids == 0 ) {
	print "no geo ids in sdrf.\n";
    } else {
	print "geo ids in sdrf:\n";
	$sdrf_geo_id_found = 1;
	print @geo_ids, "\n";
	for my $gsm_id (@geo_ids) {
	    my $gsm_reader = new GEO::Gsm({
		'config' => $ini2,
		'gsm' => $gsm_id});
	    my $gsm_reader->get_all();
	    my $sra = $gsm_reader->get_sra();
	    if ( scalar @$sra != 0 ) {
		print "sra found.\n";
		print @$sra, "\n";
	    }
	}
    }
    unless ( $sdrf_fastq_found || $sdrf_geo_id_found) {
	my @wiggles = $reporter->get_wiggle_files();
	print "wiggle files:\n";
	print @wiggles, "\n";
    }
}




sub get_dcc_ids {
    my $file = shift;
    open my $fh, "<", $file;
    my @ids;
    while(my $line = <$fh>) {
	chomp;
	next if $line =~ /^\s*$/;
	next if $line =~ /^#/;
	my @fields = split / \s*/, $line, 2;
	push @ids, $fields[0]; 
    }
    close $fh;
    return @ids;
}
