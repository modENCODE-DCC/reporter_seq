#!/usr/bin/perl
use strict;
use Config::IniFiles;
use Getopt::Long;
use GEO::Gsm;
my $root_dir;
BEGIN {
    $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir;
}
my ($map, $output_dir);
my $config = $root_dir . 'geoid.ini';
tie my %ini, 'Config::IniFiles', (-file => $config);
my $option = GetOptions ("m=s"    => \$map,
                         "o=s"    => \$output_dir,
                         "c=s"    => \$config);


my $xmldir = $ini{cache}{gsm};
for my $dir ($output_dir, $xmldir) {
    $dir = File::Spec->rel2abs($dir);
    $dir .= '/' unless $dir =~ /\/$/;
}

open my $fh, "<", $map || die;
while(my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^#/;
    my ($id, @gsms) = split /\t/, $line;
    for my $gsm (@gsms) {
	next if $gsm =~ /SR[R|X]/i;
	my $gsmr = new GEO::Gsm({'config' => \%ini,
				 'xmldir' => $xmldir,
				 'gsm' => $gsm});
	$gsmr->set_miniml(1);
	$gsmr->set_other();
	my $gd = $gsmr->get_general_data();
	print join("\t", ($id, $gsm, @$gd)), "\n";
    }
}
close $fh;
