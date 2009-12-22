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
my %source      :ATTR( :set<source>         :default<undef>);
my %organism      :ATTR( :set<organism>         :default<undef>);
my %strain      :ATTR( :set<strain>         :default<undef>);
my %devstage      :ATTR( :set<devstage>         :default<undef>);
my %antibody      :ATTR( :set<antibody>         :default<undef>);
my %supplementary_data  :ATTR( :set<supplementary_data>         :default<undef>);
my %bed             :ATTR( :set<bed>         :default<[]>);
my %wiggle         :ATTR( :set<wiggle>         :default<[]);
my %sra             :ATTR( :set<sra>         :default<[]>);
my %characteristics  :ATTR( :set<characteristics>         :default<undef>);

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
    for my $parameter (qw[miniml contributor lab title submission_date type strategy source organism devstage antibody supplementary_data wiggle sra ]) {
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

sub get_source {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $source = $accxml->{Sample}->{'Library-Source'};
    print "   Source: $source\n";
    $source{ident $self} = $source;    
}

sub get_organism {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $organism = $accxml->{Sample}->{'Library-Organism'};
    print "   Organism: $organism\n";
    $organism{ident $self} = $organism;
}

sub get_characteristics {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $charact = $accxml->{Sample}->{'Characteristics'};
    $characteristics{ident $self} = $charact;
}

sub get_strain {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'strain');
    $strain{ident $self} = $contents[0];
}

sub get_devstage {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'growth stage');
    $devstage{ident $self} = $contents[0];
}

sub get_antibody {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'antibody');
    $antibody{ident $self} = $contents[0];
}


sub get_supplementary_data {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $datal = $accxml->{Sample}->{'Supplementary-Data'};
    $supplementary_data{ident $self} = $datal;
}

sub get_bed {
    my ($self) = @_;
    my @files = $self->get_content('supplementary_data', 'type', 'BED');
    $bed{ident $self} = \@files;    
}

sub get_wiggle {
    my ($self) = @_;
    my @files = $self->get_content('supplementary_data', 'type', 'WIG');
    $wiggle{ident $self} = \@files;
}

sub get_sra {
    my ($self) = @_;
    my @files = $self->get_content('supplementary_data', 'type', 'SRA Experiment');;
    $sra{ident $self} = \@files;
}

sub get_content {
    my ($self, $ele, $attr_name, $attr_value) = @_;
    my @contents;
    my $contentl = ${$ele}{ident $self};
    if (ref($contentl) eq 'ARRAY') {
	for my $data (@$contentl) {
	    if ($data->{$attr_name} eq $attr_value) {
		my $content = $data->{'content'};
		$content =~ s/^\s*//; $content =~ s/\s*$//;
		push @contents, $content;
	    }
	}
    }
    if (ref($contentl) eq 'HASH') {
	if ($contentl->{'attr'} eq $attr) {
	    my $content = $contentl->{'content'};
	    $content =~ s/^\s*//; $content =~ s/\s*$//;
	    push @contents, $content;
	}	
    }
    return @contents;
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
    $request->is_success or die "$url: " . $request->message;
    print $fh $request->content();
    close $fh;
    return $file;
}


1;
