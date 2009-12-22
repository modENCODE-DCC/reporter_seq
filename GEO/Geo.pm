package GEO::Geo;

use strict;
use Carp;
use Class::Std;
use Data::Dumper;
use File::Basename;
use URI::Escape;
use HTML::Entities;
use File::Temp;
use XML::Simple;

my %config                 :ATTR( :name<config>                :default<undef>);
my %uid                    :ATTR( :set<uid>                    :default<[]>);
my %gse                    :ATTR( :set<gse>                    :default<{}>);
my %gsm                    :ATTR( :set<gsm>                    :default<{}>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    for my $parameter (qw[config]) {
	my $value = $args->{$parameter};
	defined $value || croak "can not find required parameter $parameter"; 
	my $set_func = "set_" . $parameter;
	$self->$set_func($value);
    }
    return $self;
}

sub get_uid {
    my $self = shift;
    #get xml result from entrez search
    print "download entrez esearch results ...";
    my $ini = $config{ident $self}; 
    my $search_url = $ini->{geo}{search_url} . "db=$ini->{geo}{db}" . "&term=$ini->{geo}{term}" . "[$ini->{geo}{field}]" . "&retmax=$ini->{geo}{retmax}" ;
    my $searchfile = fetch($search_url);    
    print "done.\n";
    #parse the xml file to get entrez UID for submissions
    print "parsing esearch result xml file ...";
    my $xs = new XML::Simple;
    my $esearch = $xs->XMLin($searchfile);
    my $ids = $esearch->{IdList}->{Id};
    print "done.\n";
    $uid{ident $self} = $ids;
}

sub get_all_gse_gsm {
    my $self = shift;
    my $ini = $config{ident $self};
    #use entrez esummary with input UID to fetch summary
    print "download and parse esummary xml file for GEO UIDs ...\n";
    for my $id (@{$uid{ident $self}}) {
	$self->get_gse_gsm_by_uid($id);
}

sub get_gse_gsm {
    my ($self, $uid) = @_;
    my $ini = $config{ident $self};
    print "############\n";
    print "GEO UID $id: downloading...";
    my $summary_url = $ini->{geo}{summary_url} . "db=$ini->{geo}{db}" . "&id=$uid";
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
	print "done.\n";
    }
    $gse{ident $self}->{$uid} = $gse;
    $gsm{ident $self}->{$gse} = \@gsml;
}

sub gsm_for_gse {
    my ($self, $gse) = @_;
    for my $k (keys %{$gsm{ident $self}}) {
	return $gsm{ident $self}->{$k} if $k eq $gse;
    }
    return undef;
}

sub gse_for_gsm {
    my ($self, $gsm) = @_;
    for my ($gse, $gsml) (each $gsm{ident $self}) {
	for my $xgsm (@$gsml) {
	    return $gse if $xgsm eq $gsm;
	}
    }
    return undef;
}

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


1;
