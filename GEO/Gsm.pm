package GEO::Gsm;

use strict;
use Carp;
use Class::Std;
use Data::Dumper;
use File::Temp;
use XML::Simple;

my %config                 :ATTR( :name<config>                :default<undef>);
my %gsm                 :ATTR( :name<gsm>                :default<undef>);
my %miniml              :ATTR( :set<miniml>              :default<undef>);
my %contributor         :ATTR( :set<contributor>         :default<undef>);
my %lab                :ATTR( :set<lab>         :default<undef>);
my %title              :ATTR( :set<title>         :default<undef>);
my $submission_date    :ATTR( :set<submission_date>         :default<undef>); 
my %type         :ATTR( :set<type>         :default<undef>);
my %strategy      :ATTR( :set<strategy>         :default<undef>);
my %supplementary_data  :ATTR( :set<supplementary_data>         :default<undef>);
my %bed             :ATTR( :set<bed>         :default<[]>);
my %wiggle         :ATTR( :set<wiggle>         :default<[]);
my %sra             :ATTR( :set<sra>         :default<[]>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    for my $parameter (qw[config gsm]) {
	my $value = $args->{$parameter};
	defined $value || croak "can not find required parameter $parameter"; 
	my $set_func = "set_" . $parameter;
	$self->$set_func($value);
    }
    return $self;
}

sub get_all {
    my ($self) = @_;
    for my $parameter (qw[miniml contributor lab title submission_date type strategy supplementary_data wiggle sra]) {
        my $get_func = "get_" . $parameter;
        $self->$get_func();	
    }
}

sub get_contributor {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $pfn = $accxml->{Contributor}->{Person}->{First};
     #my $pfm = $accxml->{Contributor}->{Person}->{Middle};
     my $pfl = $accxml->{Contributor}->{Person}->{Last};
     my $contributor = "$pfn $pfl";
     print "   Contributor: $contributor ";
     $contributor{ident $self} = $contributor;
}

sub get_lab {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $lab = $accxml->{Contributor}->{Laboratory};
     print "   Lab: $lab " if $lab;
     $lab{ident $self} = $lab;
}

sub get_title {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $title = $accxml->{Sample}->{Title};
     $title =~ s/^\s*//; $title =~ s/\s*$//; 
     print "   Title: $title ";
     $title{ident $self} = $title;
}

sub get_submission_date {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $date = $accxml->{Sample}->{Status}->{'Submission-Date'};
     print "   Submission date: $date ";
     $submission_date{ident $self} = $date;
}

sub get_type {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $type = $accxml->{Sample}->{Type};
     print "   Type: $type ";
     $type{ident $self} = $type;
}

sub get_strategy {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $strategy = $accxml->{Sample}->{'Library-Strategy'};
    print "   Strategy: $strategy\n";
    $strategy{ident $self} = $strategy;
}

sub get_supplementary_data {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $datal = $accxml->{Sample}->{'Supplementary-Data'};
    $supplementary_data{ident $self} = $datal;
}

sub get_bed {
    my ($self) = @_;
    my $type = 'BED';
    my @files = $self->get_datafiles($type);
    $bed{ident $self} = \@files;    
}

sub get_wiggle {
    my ($self) = @_;
    my $type = 'WIG';
    my @files = $self->get_datafiles($type);
    $wiggle{ident $self} = \@files;
}

sub get_sra {
    my ($self) = @_;
    my $type = 'SRA Experiment';
    my @files = $self->get_datafiles($type);
    $sra{ident $self} = \@files;
}

sub get_datafiles {
    my ($self, $type) = @_;
    my @files;
    my $datal = $supplementary_data{ident $self};
    if (ref($datal) eq 'ARRAY') {
	for my $data (@$datal) {
	    if ($data->{'type'} eq $type) {
		my $file = $data->{'content'};
		$file =~ s/^\s*//; $file =~ s/\s*$//;
		push @files, $file;
	    }
	}
    }
    if (ref($datal) eq 'HASH') {
	if ($datal->{'type'} eq $type) {
	    my $file = $datal->{'content'};
	    $file =~ s/^\s*//; $file =~ s/\s*$//;
	    push @files, $file;
	}	
    }
    return @files;
}

sub get_miniml {
    my ($self) = @_;
    my $ini = $config{ident $self};
    my $gsm_id = $gsm{ident $self};
    my $acc_url = $ini->{acc}{acc_url} . $gsm_id . "&targ=$ini->{acc}{targ}" . "&view=$ini->{acc}{view}" . "&form=$ini->{acc}{form}" ;
    my $accfile = fetch($acc_url);
    my $xsacc = new XML::Simple;
    my $accxml = $xsacc->XMLin($accfile);
    $miniml{ident $self} = $accxml;
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
    $request->is_success or die "$search_url: " . $request->message;
    print $fh $request->content();
    close $fh;
    return $file;
}


1;
