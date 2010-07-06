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
my %uid                    :ATTR( :get<uid>                    :default<[]>);
my %gse                    :ATTR( :name<gse>                    :default<{}>);
my %gsm                    :ATTR( :name<gsm>                    :default<{}>);
my %xmldir                 :ATTR( :name<xmldir>                 :default<undef>);
sub BUILD {
    my ($self, $ident, $args) = @_;
    for my $parameter (qw[config xmldir]) {
	my $value = $args->{$parameter};
	defined $value || croak "can not find required parameter $parameter"; 
	my $set_func = "set_" . $parameter;
	$self->$set_func($value);
    }
    return $self;
}

sub set_uid {
    my $self = shift;
    unless (scalar @{$uid{ident $self}}) {
    #get xml result from entrez search
#    print "download entrez esearch results ...";
    my $ini = $config{ident $self}; 
    my $search_url = $ini->{geo}{search_url} . "db=$ini->{geo}{db}" . "&term=$ini->{geo}{term}" . "[$ini->{geo}{field}]" . "&retmax=$ini->{geo}{retmax}" ;
    my $searchfile = 'esearch.xml';
    $searchfile = fetch($search_url, $searchfile);    
#    print "done.\n";
    #parse the xml file to get entrez UID for submissions
#    print "parsing esearch result xml file ...";
    my $xs = new XML::Simple;
    my $esearch = $xs->XMLin($searchfile);
    my $ids = $esearch->{IdList}->{Id};
#    print "done.\n";
    $uid{ident $self} = $ids;
    }
}

sub _parse_esummary {
    my $summaryfile = shift;
    my $xs = new XML::Simple;
    my $esummary = $xs->XMLin($summaryfile);
    my $gse;
    my @gsml;
    for my $item (@{$esummary->{DocSum}->{Item}}) {
	if ($item->{Name} eq 'GSE') {
	    $gse = $item->{content};
	    $gse =~ /(\d*)/; $gse = 'GSE' . $1;
	}
	if ($item->{Name} eq 'GSM_L') {
	    my $gsml = $item->{content};
	    $gsml =~ s/^\s*//; $gsml =~ s/\s*$//;
	    @gsml = split(';', $gsml);
	    pop @gsml if $gsml[scalar(@gsml)-1] =~ /^\s*$/;
	    @gsml = map { $_ =~ /(\d*)/; 'GSM' . $1; } @gsml;
	}
    }
    return ($gse, \@gsml);
}

sub parse_cached_esummary {
    my ($self) = @_;
    opendir my $xdh, $xmldir{ident $self};
    my @xmlfiles = grep { $_ =~ /\.xml/} readdir($xdh);
    @xmlfiles = map {$xmldir{ident $self} . $_;} @xmlfiles;
    for my $summaryfile (@xmlfiles) {
	$summaryfile =~ /(\d*)\.xml/;
	my $uid = $1;
	my ($gsx, $gsml) = _parse_esummary($summaryfile);
	$gse{ident $self}->{$uid} = $gsx;
	$gsm{ident $self}->{$gsx} = $gsml;
    }
}

sub set_all_gse_gsm {
    my $self = shift;
    my $ini = $config{ident $self};
    #use entrez esummary with input UID to fetch summary
#    print "download and parse esummary xml file for GEO UIDs ...\n";
    for my $id (@{$uid{ident $self}}) {
#	print "GEO UID $id: ";
	my $xmlfile = $xmldir{ident $self} . $id . '.xml';
	print "use cached $xmlfile\n" and next if -e $xmlfile;
	$self->fetch_gse_gsm($id);
    }
    $self->parse_cached_esummary();
}

sub fetch_gse_gsm {
    my ($self, $uid) = @_;
    my $ini = $config{ident $self};
#    print "downloading...";
    my $summary_url = $ini->{geo}{summary_url} . "db=$ini->{geo}{db}" . "&id=$uid";
    my $xmlfile = $xmldir{ident $self} . $uid . '.xml';
    my $summaryfile = fetch($summary_url, $xmlfile);
#    print "done. parsing...";
    my ($gsx, $gsml) = _parse_esummary($summaryfile);
    $gse{ident $self}->{$uid} = $gsx;
    $gsm{ident $self}->{$gsx} = $gsml;
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
    while ( my ($gse, $gsml) = each %{$gsm{ident $self}} ) {
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
