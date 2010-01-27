#!/usr/bin/perl
use strict;
use Config::IniFiles;
use GEO::Gse;

my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir;
}

my $config = $root_dir . 'geoid.ini';
tie my %ini, 'Config::IniFiles', (-file => $config);
my $gse = 'GSE20000';
my $xmldir = $root_dir . 'temp/';

my $gser = new GEO::Gse({config => \%ini,
			 gse => $gse,
			 xmldir => $xmldir
			});
$gser->get_miniml();
my @gsms = $gser->get_gsm();
map {print $_, "\n"} @gsms; 
