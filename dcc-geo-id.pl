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
#use ModENCODE::Parser::LWChado;
#use GEO::LWReporter;
use GEO::Geo;
use GEO::Gsm;
use Data::Dumper;
use URI;

my ($dcc_id_file, $output_dir, $config);
$config = $root_dir . 'geoid.ini';
my $option = GetOptions ("id=s"            => \$dcc_id_file,
			 "out=s"           => \$output_dir,
			 "config=s"        => \$config);
die unless -r $dcc_id_file;
my $dcc_ids = get_ids($dcc_id_file);
my %ini;
tie %ini, 'Config::IniFiles', (-file => $config);
my $summary_cache_dir = $ini{cache}{summary};
my $gsm_cache_dir = $ini{cache}{gsm};
for my $dir ($output_dir, $summary_cache_dir, $gsm_cache_dir) {
    $dir = File::Spec->rel2abs($dir);
    $dir .= '/' unless $dir =~ /\/$/;
    die unless -w $dir;
}
my $dcc_summary_file = $output_dir . 'dcc_summary.txt';
open my $dsfh, ">", $dcc_summary_file;

my $geo_reader = new GEO::Geo({'config' => \%ini,
			       'xmldir' => $summary_cache_dir});
print "geo reader ready\n";
$geo_reader->set_uid();
$geo_reader->set_all_gse_gsm();
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
my $geo_ids = {};
while( my ($gse, $gsml) = each %{$geo_reader->get_gsm()}) {
    for my $gsmid (@$gsml) {
	unless ($in_memory{$gsmid}) {
	    $in_memory{$gsmid} = 1;
	    my $gsm = new GEO::Gsm({'config' => \%ini,
				    'xmldir' => $gsm_cache_dir,
				    'gsm' => $gsmid});
	    $gsm->set_all();
	    my $lab = $gsm->get_lab();
	    if ($lab =~ /kevin\s*white/i) {		
		my $tgt = $gsm->get_antibody();
		my $devstage = $gsm->get_devstage();
		my $tissue = $gsm->get_tissue();
		my $timepoint =$gsm->get_timepoint();
		print join(' ', ($gse, $gsmid, $lab, $tgt, 'devstage', $devstage, 'tissue', $tissue, 'timepoint', $timepoint)), "\n";
		my $dev = geo_map_devstage($gsm->get_title(), $devstage, $tissue, $timepoint);
		$geo_ids->{$gsmid} = [$gse, $tgt, $dev];
	    }
	}	
    }
}

foreach my $dcc_id (sort keys %$dcc_ids) {
    my $dcc_ch = $dcc_ids->{$dcc_id};
    next if $dcc_id == 918; #a rna-seq experiment
    my $ab = $dcc_ch->[1];
    my $devstage = $dcc_ch->[2];
    $ab =~ s/AbName=//;
    $ab =~ s/,control//;
    $ab =~ s/control,//;
    $ab =~ s/,cad//;
    $ab =~ s/,inv//;
    $ab =~ s/,sens//;
    $ab = lc($ab);
    $ab = 'run' if $ab eq 'runt';
    $ab = 'sens' if $ab eq 'senseless';
    $ab = 'ttk' if $ab eq 'tremtrak';
    $ab = 'bab1' if $ab eq 'bab-1';
    $ab = 'cnc' if $ab eq "cap'n collar";
    $ab = 'caudal' if $ab eq 'cad';
    $ab = 'dctbp' if $ab eq 'nejire';
    $ab = 'kr' if $ab eq 'kruppel';
    $ab = 'gro' if $ab eq 'groucho';
    $ab = 'inv' if $ab eq 'invected';
    $ab = 'cbp' if $ab eq 'c-terminal binding protein';
    my $len = length($ab);
    print join(" ", ($dcc_id, $ab, " "));
    while ( my ($gsmid, $gsm_ch) = each %$geo_ids) {
	my $tgt = lc($gsm_ch->[1]);
	my $dev = $gsm_ch->[2];
	$tgt = 'dichaete' if $tgt eq 'd';
	$tgt = 'rna polymerase ii' if $tgt eq 'polii';
	$tgt = 'ctcf c-terminus' if $tgt eq 'ctcf-c';
	$tgt = 'ctcf n-terminus' if $tgt eq 'ctcf-n';
	$tgt = 'brahma' if $tgt eq 'brm';
	$tgt = 'engrailed' if $tgt eq 'end300';
	$tgt = 'knot' if $tgt eq 'kn';
	$tgt = 'engrailed' if $tgt eq 'enserum';
	$tgt = 'brakeless' if $tgt eq 'bks';
	if ($tgt eq $ab) {
	    if ($dev eq $devstage) {
		print $gsmid, " ";
	    }
	}
	elsif (substr($tgt, 0, $len) eq $ab) {
	    if ($dev eq $devstage) {
		print $gsmid, " ";
	    }
	}
    }
    print "\n";
}


sub geo_map_devstage {
    my ($title, $devstage, $tissue, $timepoint) = @_;
    my $dev;
    if ($devstage) {
	if ($devstage =~ /E(\d)-(\d)/) {
	    $dev = 'Embryo ' . $1 . '-' . $2 . 'h';
	} else {
	    $dev = $devstage;
	}
    }
    elsif ($tissue && $timepoint) {
	if ($tissue eq 'embryos') {
	    $timepoint =~ s/ hours of development/h/; 
	    $dev = 'Embryo ' . $timepoint;
	}
	$tissue =~ s/embryos/Embryo/;
	if ($tissue eq 'larvae') { 
	    $dev = $timepoint;
	}
    }
    else {
	my @tmp = split /_/, $title, 2;
	$devstage = $tmp[0];
	if ($devstage =~ /E(\d)-(\d)/) {
	    $dev = 'Embryo ' . $1 . '-' . $2 . 'h';
	}
	$dev = 'AdultFemale' if $devstage =~ /^Adult[_\s]*Female/i;
	$dev = 'AdultFemale' if $devstage =~ /^Adult[_\s]*Fem/i;
	$dev = 'AdultMale' if $devstage =~ /^Adult[_\s]*Male/i;
    }
    return $dev;
}


sub dcc_map_devstage {
    my ($title, $devstage) = @_;
    my $dev;
    $dev = 'mixed embryo' if $devstage eq 'embryonic stage';
    $dev = 'late embryo' if $devstage eq 'late embryonic stage';
    $dev = 'Embryo 0-12h' if $devstage eq 'embryonic stage 1-15';
    $dev = 'Embryo 0-4h' if $devstage eq 'embryonic stage 1-9';
    $dev = 'Embryo 0-8h' if $devstage eq 'embryonic stage 1-12';
    $dev = 'Embryo 4-8h' if $devstage eq 'embryonic stage 9-12';
    $dev = 'Embryo 8-12h' if $devstage eq 'embryonic stage 12-15';
    $dev = 'Embryo 12-16h' if $devstage eq 'embryonic stage 15-16';
    $dev = 'Embryo 16-20h' if $devstage eq 'embryonic stage 17';
    $dev = 'AdultFemale' if $title =~ /^Adult[_\s]*Female/i;
    $dev = 'AdultFemale' if $title =~ /^Adult[_\s]*Fem/i;
    $dev = 'AdultMale' if $title =~ /^Adult[_\s]*Male/i;
    $dev = 'L3' if $devstage eq 'third instar larval stage';
    $dev = 'L2' if $devstage eq 'second instar larval stage';
    $dev = 'L1' if $devstage eq 'first instar larval stage';
    $dev = 'Pupae' if $devstage eq 'pupal stage';
    return $dev;
}

sub get_ids {
    my $file = shift;
    open my $fh, "<", $file;
    my $id = {};
    while(my $line = <$fh>) {
	chomp $line;
	next if $line =~ /^\s*$/;
	next if $line =~ /^#/;
	my @fields = split /\t/, $line, 5; #lab title id antibody devstage
	my $dev = dcc_map_devstage($fields[1], $fields[4]);
	$id->{$fields[2]} = [$fields[1], $fields[3], $dev];  

    }
    close $fh;
    return $id;
}
