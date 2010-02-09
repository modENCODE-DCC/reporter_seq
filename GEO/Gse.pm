package GEO::Gse;
##certainly could use a common base class with GEO::Gsm; 
use strict;
use Carp;
use Class::Std;
use Data::Dumper;
use File::Temp;
use XML::Simple;
use LWP::UserAgent;

my %config                 :ATTR( :name<config>                :default<undef>);
my %gse                 :ATTR( :name<gse>                :default<undef>);
my %xmldir                 :ATTR( :name<xmldir>                :default<undef>);
my %miniml              :ATTR( :get<miniml>              :default<undef>);



sub BUILD {
    my ($self, $ident, $args) = @_;
    for my $parameter (qw[config gse xmldir]) {
	my $value = $args->{$parameter};
	defined $value || croak "can not find required parameter $parameter"; 
	my $set_func = "set_" . $parameter;
	$self->$set_func($value);
    }
    return $self;
}

sub set_miniml {
    my ($self) = @_;
    my $ini = $config{ident $self};
    my $gse_id = $gse{ident $self};
    my $acc_url = $ini->{acc}{acc_url} . $gse_id . "&targ=$ini->{acc}{targ}" . "&view=$ini->{acc}{view}" . "&form=$ini->{acc}{form}" ;
    my $accfile = $xmldir{ident $self} . $gse_id . '.xml';
    print "miniml $accfile exists. use cache...\n" if -e $accfile;
    unless (-e $accfile) { 
	$accfile = fetch($acc_url, $accfile);
    }
    my $xsacc = new XML::Simple;
    my $accxml = $xsacc->XMLin($accfile);
    $miniml{ident $self} = $accxml;
}

sub get_gsm {
     my ($self) = @_;
     my @gsms;
     my $accxml = $miniml{ident $self};
     my $samples = $accxml->{Sample};
     if (ref($samples) eq 'ARRAY') {
	 for my $sample (@$samples) {
	     push @gsms, $sample->{Accession}->{content};
	 }
     }
     if (ref($samples) eq 'HASH') {
	 push @gsms, $samples->{Accession}->{content};
     }
     return @gsms;
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
