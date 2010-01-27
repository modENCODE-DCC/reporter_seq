#!/usr/bin/perl
use strict;
use Config::IniFiles;
use Getopt::Long;
use File::Spec;
use GEO::Gse;
use Net::FTP;

my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir;
}

my ($gse, $output_dir);
my $config = $root_dir . 'geoid.ini';
my $option = GetOptions ("gse=s"            => \$gse,
			 "out=s"           => \$output_dir,
			 "config=s"        => \$config);

tie my %ini, 'Config::IniFiles', (-file => $config);
my $xmldir = $ini{cache}{gsm};
for my $dir ($output_dir, $xmldir) {
    $dir = File::Spec->rel2abs($dir);
    $dir .= '/' unless $dir =~ /\/$/;
}
my $gser = new GEO::Gse({config => \%ini,
			 gse => $gse,
			 xmldir => $xmldir
			});
$gser->get_miniml();
my @gsms = $gser->get_gsm();
map {print $_, "\n"} @gsms;
 
my $dcc_summary_file = $output_dir . 'dcc_summary.txt';
open my $dsfh, ">", $dcc_summary_file;
my $ftp = Net::FTP->new("ftp.ncbi.nlm.nih.gov") or die "Cannot connect to, $@";
$ftp->login();

for my $gsm (@gsms) {
    my $gsmr = new GEO::Gsm({'config' => \%ini,
			     'xmldir' => $xmldir,
			     'gsm' => $gsm});
    $gsmr->get_miniml();
    print $dsfh $gsm, " ", $gsmr->get_title(), "\n";
    my $sra = $gsmr->get_sra();
    if ( scalar @$sra != 0 ) {
	map {print $_, "\n"} @$sra;
	for my $dir (@$sra) {
	    print $dsfh $dir;
	    my $uri = URI->new($dir);
	    eval { map {print $_, "\n"; print $dsfh $_, "\n"} @{$ftp->ls($uri->path())} };
	    print "invalid sra link: $uri\n" and print $dsfh "invalid\n" if $@;
	}
    }
}