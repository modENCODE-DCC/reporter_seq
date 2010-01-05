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
my $summary_cache_dir = $ini{cache}{summary};
my $gsm_cache_dir = $ini{cache}{gsm};
for my $dir ($output_dir, $summary_cache_dir, $gsm_cache_dir) {
    $dir = File::Spec->rel2abs($dir);
    $dir .= '/' unless $dir =~ /\/$/;
}
die unless -e $dcc_id_file;
my @dcc_ids = get_dcc_ids($dcc_id_file);

#my $geo_reader = new GEO::Geo({'config' => \%ini,
#			       'xmldir' => $summary_cache_dir});
#print "geo reader ready\n";
#$geo_reader->get_uid();
#$geo_reader->get_all_gse_gsm();
#%in_memory;
#@all_gsm;
#for my $gsml (values %{$geo_reader->get_gsm()}) {
#    for my $gsmid (@$gsml) {
#	unless ($in_memory{$gsmid}) {
#	    my $gsm = new GEO::Gsm({'config' => \%ini;
#				    'xmldir' => $gsm_cache_dir});
#	    $gsm->get_all();
#	    push @all_gsm, $gsm;
#	    $in_memory{$gsmid} = 1;
#	}	
#    }
#}

my $dbname = $ini{database}{dbname};
my $dbhost = $ini{database}{host};
my $dbusername = $ini{database}{username};
my $dbpassword = $ini{database}{password};
my $reader = new ModENCODE::Parser::Chado({
    'dbname' => $dbname,
    'host' => $dbhost,
    'username' => $dbusername,
    'password' => $dbpassword});
for my $unique_id (@dcc_ids) {
    print "# submission $unique_id #\n";
    print "connecting to database ...";
    #search path for this dataset, this is fixed by modencode chado db
    my $schema = $ini{database}{pathprefix}. $unique_id . $ini{database}{pathsuffix} . ',' . $ini{database}{schema};
    my $experiment_id = $reader->set_schema($schema);
    print "connected schema $schema.\n";
    print "loading experiment ...";
    $reader->load_experiment($experiment_id);
    my $experiment = $reader->get_experiment();
    print "done.\n";
    my $reporter = new GEO::LWReporter({
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
	#non-redundant
	my %h = map {$_ => 1} @geo_ids;
	@geo_ids = keys %h;
	print @geo_ids, "\n";
	for my $gsm_id (@geo_ids) {
	    my $gsm_reader = new GEO::Gsm({
		'config' => \%ini,
		'gsm' => $gsm_id,
		'xmldir' => $gsm_cache_dir});
	    $gsm_reader->get_all();
	    my $sra = $gsm_reader->get_sra();
	    if ( scalar @$sra != 0 ) {
		print "sra found.\n";
		print @$sra, "\n";
		if ( $gsm_reader->valid_sra() ) {
		    print " all sra valid. ";
		} else {
		    print 'sra invalid.\n';
		}
	    } else {
		print 'no sra yet.\n';
	    }
	}
    }
#    unless ( $sdrf_fastq_found || $sdrf_geo_id_found) {
#	my $organism = $reporter->get_organism();
#	my $dcc_strain = $reporter->get_strain();
#	my $dcc_cellline = $reporter->get_cellline();
#	my $dcc_devstage = $reporter->get_devstage();
#	my $dcc_antibody = $reporter->get_antibody();
#	my $dcc_tgt_gene = $reporter->get_tgt_gene();
#	my @dcc_wiggles = $reporter->get_wiggle_files();
	
#	my $found_wig = 0;
#	my @gsm_id = check_wiggles(\@dcc_wiggles, \@all_gsm);
#	if (scalar @gsm_id >= 1) {
#	    print " DCC submission $unique_id matches GEO records @gsm_id with wiggle datafiles\n";
#	    $found_wig = 1;
#	}
#	unless ($found_wig) {	    
#	}
#    }
}

#sub check_strain {    
#}


sub check_wiggles {
    my ($dcc_wig, $all_gsm) = @_;
    my @id;
    for my $gsm (@$all_gsm) {
	my @gsm_wig = @{$gsm->get_wiggle()};
	@gsm_wig = map { $_ =~ s/GSM\d*_//; $_; } @gsm_wig;
	sort @gsm_wig;
	push @id, $gsm->get_gsm() if part_of($dcc_wig, \@gsm_wig);
    }
    return @id;
}

sub part_of {
    my ($a, $b) = @_;
    return 0 if ( scalar @$a < scalar @$b);
    for my $bele (@$b) {
	my $in=0;
	for my $aele (@$a) {
	    $in=1 if $aele eq $bele;
	}
	return 0 unless $in;
    }
    return 1;
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
