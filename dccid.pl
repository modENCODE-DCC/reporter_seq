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
use Data::Dumper;
use URI;

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
my $dcc_summary_file = $output_dir . 'dcc_summary.txt';
die unless -e $dcc_id_file;
my @dcc_ids = get_ids($dcc_id_file);
open my $dsfh, ">", $dcc_summary_file;

my $geo_reader = new GEO::Geo({'config' => \%ini,
			       'xmldir' => $summary_cache_dir});
print "geo reader ready\n";
$geo_reader->get_uid();
$geo_reader->get_all_gse_gsm();
print "ok1";
my $uidfile = $ini{output}{uid};
my $gsefile = $ini{output}{gse};
my $gsmfile = $ini{output}{gsm};

open my $uidfh, ">", $uidfile;
open my $gsefh, ">", $gsefile;
open my $gsmfh, ">", $gsmfile;
map {print $uidfh $_, "\n"} @{$geo_reader->get_uid()};
while ( my ($uid, $gse) = each %{$geo_reader->get_gse()} ) {
    print $gsefh $uid, " ", $gse, "\n";
}
while ( my ($gse, $gsml) = each %{$geo_reader->get_gsm()} ) {
    print $gsmfh $gse, " ", join(" ", @$gsml), "\n";
}
close $uidfh;
close $gsefh;
close $gsmfh;
print "ok2";
my %in_memory;
#@all_gsm;
for my $gsml (values %{$geo_reader->get_gsm()}) {
    for my $gsmid (@$gsml) {
	unless ($in_memory{$gsmid}) {
	    my $gsm = new GEO::Gsm({'config' => \%ini,
				    'xmldir' => $gsm_cache_dir,
				    'gsm' => $gsmid});
	    $gsm->set_miniml();
#	    push @all_gsm, $gsm;
	    $in_memory{$gsmid} = 1;
	}	
    }
}

my $ftp = Net::FTP->new("ftp.ncbi.nlm.nih.gov") or die "Cannot connect to, $@";
$ftp->login();

my $dbname = $ini{database}{dbname};
my $dbhost = $ini{database}{host};
my $dbusername = $ini{database}{username};
my $dbpassword = $ini{database}{password};
for my $unique_id (@dcc_ids) {
    print "# submission $unique_id #\n";
	print $dsfh "submission $unique_id\n";
    print "connecting to database ...";
    my $reader = new ModENCODE::Parser::LWChado({
    'dbname' => $dbname,
    'host' => $dbhost,
    'username' => $dbusername,
    'password' => $dbpassword});
    #search path for this dataset, this is fixed by modencode chado db
    my $schema = $ini{database}{pathprefix}. $unique_id . $ini{database}{pathsuffix} . ',' . $ini{database}{schema};
    my $experiment_id = $reader->set_schema($schema);
    print "connected schema $schema.\n";
    print "loading experiment ...";
    $reader->load_experiment($experiment_id);
    my $experiment = $reader->get_experiment();
    print Dumper($experiment);
    print "done.\n";
    my $reporter = new GEO::LWReporter({
        'unique_id' => $unique_id,
        'reader' => $reader,
        'experiment' => $experiment,
    });
    print "reporter done.\n";
    $reporter->get_all();
    my @karact = ('strain', 'cellline', 'devstage', 'tgt_gene');
    for my $kar (@karact) {
	my $fun = 'get_' . $kar;
	my $s = $reporter->$fun;
	print $dsfh $kar, ":", $s, "\n" if $s;
    }
    my @fastq_files = $reporter->get_fastq_files();
    my @geo_ids = $reporter->get_geo_ids();
    my @sra_ids = $reporter->get_sra_ids();
    my ($sdrf_fastq_found, $sdrf_geo_id_found, $sdrf_sra_id_found);
    if ( scalar @fastq_files == 0 ) {
	print "no fastq file in sdrf.\n";
	print $dsfh "No fastq files\n";
    } else {
	print "fastq files in sdrf:\n";
	$sdrf_fastq_found = 1;
	print @fastq_files;
        #non-redundant
        my %h = map {$_ => 1} @fastq_files;
        @fastq_files = keys %h;
        print @fastq_files, "\n";
	map {print $dsfh $_, "  "} @fastq_files;
	print $dsfh "\n";
    }
    if ( scalar @geo_ids == 0 ) {
	print "no geo ids in sdrf.\n";
	print $dsfh "No geo id.\n";
    } else {
	print "geo ids in sdrf:\n";
	$sdrf_geo_id_found = 1;
	#non-redundant
	my %h = map {$_ => 1} @geo_ids;
	@geo_ids = keys %h;
	print @geo_ids, "\n";
	#map {print $dsfh $_, "  "} @geo_ids;
	#print $dsfh "\n";
	for my $gsm_id (@geo_ids) {
	    my $gsm_reader = new GEO::Gsm({
		'config' => \%ini,
		'gsm' => $gsm_id,
		'xmldir' => $gsm_cache_dir});
	    $gsm_reader->set_all();
	    print $dsfh $gsm_id, " ", $gsm_reader->get_title(), "\n";
	    my $sra = $gsm_reader->get_sra();
	    if ( scalar @$sra != 0 ) {
		print "sra found.\n";
		print @$sra, "\n";
		for my $dir (@$sra) {
		    my $uri = URI->new($dir);
		    map {print $dsfh $_, "\n"} @{$ftp->ls($uri->path())};
		}
		#map {print $dsfh $_, "  "} @$sra;
		#if ( $gsm_reader->valid_sra() ) {
		#    print " all sra valid. ";
		#    print $dsfh "valid\n";
		#} else {
		#    print "sra invalid.\n";
		#    print $dsfh "invalid\n";
		#}
	    } else {
		print "no sra yet.\n";
		print $dsfh "No sra\n";
	    }
	}
    }
    if (scalar @sra_ids == 0) {
	print "no sra experiment id in sdrf.\n";
        print $dsfh "No sra experiment id\n";
    } else {
	print "sra experiment id found in sdrf:\n";
	$sdrf_sra_id_found = 1;
	my %h = map {$_ => 1} @sra_ids;
        @sra_ids = keys %h;
        print @sra_ids, "\n";
        map {print $dsfh $_, "  "} @sra_ids;
        print $dsfh "\n";
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

close $dsfh;

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

sub get_ids {
    my $file = shift;
    open my $fh, "<", $file;
    my @ids;
    while(my $line = <$fh>) {
	chomp $line;
	next if $line =~ /^\s*$/;
	next if $line =~ /^#/;
	my @fields = split / \s*/, $line, 2;
	push @ids, $fields[0]; 

    }
    close $fh;
    return @ids;
}
