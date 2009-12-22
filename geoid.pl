#!/usr/bin/perl
use strict;

my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir;
}

use Carp;
use Data::Dumper;
use Getopt::Long;
use Config::IniFiles;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;
use LWP::Simple;
use File::Temp;
use XML::Simple;
use LWP::Simple;

print "initializing...";
#default config
my $config;
$config = $root_dir . 'geoid.ini';
#get option, override default config if config parameter exists
my $option = GetOptions ("config=s" => \$config);
tie my %ini, 'Config::IniFiles', (-file => $config);
print "done.\n";

#output files
my $gsefile = $ini{output}{gse};
my $gsmfile = $ini{output}{gsm};
my $fastqfile = $ini{output}{fastq};
my $gsm_fastq_file = '/home/zheng/chipseq/geo/gsm_fastq.txt';
my $nr_valid_fastqfile = $fastqfile . ".nr_valid";
my $option = $ini{output}{strategy};
my @all_gsm_with_sra;
my @all_sra_acc;

#get xml result from entrez search
print "download entrez esearch results ...";
my $search_url = $ini{geo}{search_url} . "db=$ini{geo}{db}" . "&term=$ini{geo}{term}" . "[$ini{geo}{field}]" . "&retmax=$ini{geo}{retmax}" ;

#my $outfile = '/home/zheng/chipseq/geo_esearch.xml';
#my $searchfile = fetch($search_url, $outfile);
my $searchfile = fetch($search_url);
print "done.\n";

#parse the xml file to get entrez UID for submissions
print "parsing esearch result xml file ...";
my $xs = new XML::Simple;
my $esearch = $xs->XMLin($searchfile);
my $ids = $esearch->{IdList}->{Id};
print "done.\n";

#use entrez esummary with input UID to fetch summary
print "download and parse esummary xml file for GEO UIDs ...\n";
my $xs = new XML::Simple;
open my $gsefh, ">", $gsefile;
open my $gsmfh, ">", $gsmfile;
open my $fastqfh, ">", $fastqfile;
open my $nr_valid_fastqfh, ">", $nr_valid_fastqfile;
open my $gsm_fastq_fh, ">", $gsm_fastq_file;
print $gsefh "#ncbi_uid title GSE\n";
print $gsmfh "#ncbi_uid title GSM\n";
print $fastqfh "#GSM sra_acc\n";
for my $id (@$ids) {
    print "############\n";
    print "GEO UID $id: downloading...";
    my $summary_url = $ini{geo}{summary_url} . "db=$ini{geo}{db}" . "&id=$id";
    my $summaryfile = fetch($summary_url);
    print "done. parsing...";
    my $esummary = $xs->XMLin($summaryfile);
    my ($type, $title, $summary, $gse, $gsml);
    my $is_gse = 0;
    for my $item (@{$esummary->{DocSum}->{Item}}) {
	if ($item->{Name} eq 'entryType') {
	    $type = $item->{content};
	    $type =~ s/^\s*//; $type =~ s/\s*$//;
	    if ($type eq 'GSE') {
		$is_gse = 1 and last;
	    }
	}
    }
    if ($is_gse) {
	for my $item (@{$esummary->{DocSum}->{Item}}) {
	    $title = $item->{content} if $item->{Name} eq 'title';
	    $summary = $item->{content} if $item->{Name} eq 'summary';
	    $gse = $item->{content} if $item->{Name} eq 'GSE';
	    $gsml = $item->{content} if $item->{Name} eq 'GSM_L';
	}
	#$gse =~ s/^\s*//; $gse =~ s/\s*$//; $gse = 'GSE' . $gse;
	$gse =~ /(\d*)/; $gse = 'GSE' . $1;
	$gsml =~ s/^\s*//; $gsml =~ s/\s*$//;
	my @gsml = split(';', $gsml);
	pop @gsml if $gsml[scalar(@gsml)-1] =~ /^\s*$/;
	#@gsml = map { $_ =~ s/^\s*//; $_ =~ s/\s*$//; 'GSM' . $_; } @gsml;
	@gsml = map { $_ =~ /(\d*)/; 'GSM' . $1; } @gsml;

	print "done. write out ...";
	#print $gsefh join("\t", ($id, $title, $gse)), "\n";
	print $gsefh join("\t", ($title, $gse)), "\n";
	#print $gsmfh join("\t", ($id, $title, @gsml)), "\n";
	print $gsmfh join("\t", ($title, @gsml)), "\n";
	print "done.\n";
	for my $gsm (@gsml) {
	    print "  GSM: ", $gsm, "\n";
	    my $acc_url = $ini{acc}{acc_url} . $gsm . "&targ=$ini{acc}{targ}" . "&view=$ini{acc}{view}" . "&form=$ini{acc}{form}" ;
	    my $accfile = fetch($acc_url);
	    #sleep(1);
	    my $xsacc = new XML::Simple;
	    my $accxml = $xsacc->XMLin($accfile);
	    my $pfn = $accxml->{Contributor}->{Person}->{First};
	    #my $pfm = $accxml->{Contributor}->{Person}->{Middle};
	    my $pfl = $accxml->{Contributor}->{Person}->{Last};
	    my $contributor = "$pfn $pfl";
	    print "   Contributor: $contributor ";
	    my $lab = $accxml->{Contributor}->{Laboratory};
	    print "   Lab: $lab " if $lab;
	    my $title = $accxml->{Sample}->{Title};
	    $title =~ s/^\s*//; $title =~ s/\s*$//; 
	    print "   Title: $title ";
	    my $date = $accxml->{Sample}->{Status}->{'Submission-Date'};
	    print "   Submission date: $date ";
	    my $type = $accxml->{Sample}->{Type};
	    print "   Type: $type ";
	    my $strategy = $accxml->{Sample}->{'Library-Strategy'};
	    print "   Strategy: $strategy\n";
	    my $sra_acc;
	    if ($type eq 'SRA') {
		    my $datal = $accxml->{Sample}->{'Supplementary-Data'};
		    my $found = 0;
		    if (ref($datal) eq 'ARRAY') {
			for my $data (@$datal) {
			    if ($data->{'type'} eq 'SRA Experiment') {
				print "    SRA link: ", $data->{content}, "\n";
				$sra_acc = $data->{content};
				$sra_acc =~ s/^\s*//; $sra_acc =~ s/\s*$//;
				$found = 1 and last;
			    }
			}
		    }
		    if (ref($datal) eq 'HASH') {
			if ($datal->{'type'} eq 'SRA Experiment') {
			    print "    SRA link: ", $datal->{content}, "\n";
			    $sra_acc = $datal->{content};
			    $sra_acc =~ s/^\s*//; $sra_acc =~ s/\s*$//; 
			    $found = 1;
			}
		    }
		    print "   NO SRA link from GEO yet!\n" unless $found; 
		    if ($strategy eq $option) {#chip-seq
			if ($found) {
			    print $gsm_fastq_fh join("\t", ($gse, $gsm, $lab, $sra_acc)), "\n";
			}
			else {
			    print $gsm_fastq_fh join("\t", ($gse, $gsm, $lab, 'no sra yet')), "\n";
			}
		    }
	    } 
	    else {
		print "   NOT A HTSeq experiment\n";
	    }


#	    if ( defined($sra_acc) ) {
#		push @all_gsm_with_sra, [$gsm, $title, $contributor];
#		push @all_sra_acc, $sra_acc;
#		if ( $option eq 'all' ) {
#		    print $fastqfh join("\t", ($gsm, $title, $contributor, $sra_acc)), "\n";
#		} else {
#		    if ($strategy eq $option) {
#			print $fastqfh join("\t", ($gsm, $title, $contributor, $sra_acc)), "\n";
#		    }
#		}
#	    }

	}
    }
}
close $gsefh;
close $gsmfh;
close $fastqfh;
close $gsm_fastq_fh;
my %written;
#for (my $i=0; $i<scalar(@all_gsm_with_sra); $i++) {
#    my $gsm = $all_gsm_with_sra[$i]->[0];
#    my $sra_acc = $all_sra_acc[$i];
    #sleep(1);
#    if (!exists($written{$sra_acc})) {
#	if (LWP::Simple::head($sra_acc)) {
#	    print $nr_valid_fastqfh join("\t", (@{$all_gsm_with_sra[$i]}, $sra_acc)), "\n";  
#	} else {
#	    print "invalid sra: $sra_acc\n";
#	}
#	$written{$sra_acc} = 1;
#    } else {
#	print "redundant sra: $sra_acc\n";
#    }

#    if ( (!exists($written{$sra_acc})) and (LWP::Simple::head($sra_acc)) ) {
#	print $nr_valid_fastqfh join("\t", (@{$all_gsm_with_sra[$i]}, $sra_acc)), "\n";
#	$written{$sra_acc} = 1;
#    }
#}
close $nr_valid_fastqfh;

print "all done\n";

exit 0; 

sub fetch {
    my ($url, $outfile) = @_;
    my ($fh, $file);
    if ($outfile) {
	$file = $outfile;
	open $fh, ">", $file;
    } else {
	($fh, $file) = File::Temp::tempfile();
    }
    my $ua = new LWP::UserAgent;
    my $request = $ua->request(HTTP::Request->new('GET' => $url));
    $request->is_success or die "$url: " . $request->message;
    print $fh $request->content();
    close $fh;
    return $file;
}
