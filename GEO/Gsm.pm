package GEO::Gsm;

use strict;
use Carp;
use Class::Std;
use Data::Dumper;
use File::Temp;
use XML::Simple;
use LWP::UserAgent;
use LWP::Simple;

my %config                 :ATTR( :name<config>                :default<undef>);
my %gsm                 :ATTR( :name<gsm>                :default<undef>);
my %xmldir                 :ATTR( :name<xmldir>                :default<undef>);
my %miniml              :ATTR( :get<miniml>              :default<undef>);
my %contributor         :ATTR( :get<contributor>         :default<undef>);
my %lab                :ATTR( :get<lab>         :default<undef>);
my %title              :ATTR( :get<title>         :default<undef>);
my %submission_date    :ATTR( :get<submission_date>         :default<undef>); 
my %type         :ATTR( :get<type>         :default<undef>);
my %strategy      :ATTR( :get<strategy>         :default<undef>);
my %source      :ATTR( :get<source>         :default<undef>);
my %organism      :ATTR( :get<organism>         :default<undef>);
my %strain      :ATTR( :get<strain>         :default<undef>);
my %cellline      :ATTR( :get<cellline>         :default<undef>);
my %devstage      :ATTR( :get<devstage>         :default<undef>);
my %antibody      :ATTR( :get<antibody>         :default<undef>);
my %supplementary_data  :ATTR( :get<supplementary_data>         :default<undef>);
my %bed             :ATTR( :get<bed>         :default<[]>);
my %wiggle         :ATTR( :get<wiggle>         :default<[]);
my %sra             :ATTR( :get<sra>         :default<[]>);
my %characteristics  :ATTR( :get<characteristics>         :default<undef>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    for my $parameter (qw[config gsm xmldir]) {
	my $value = $args->{$parameter};
	defined $value || croak "can not find required parameter $parameter"; 
	my $set_func = "set_" . $parameter;
	$self->$set_func($value);
    }
    return $self;
}

sub set_all {
    my ($self) = @_;
    for my $parameter (qw[miniml contributor lab title submission_date type strategy source organism characteristics strain devstage antibody supplementary_data wiggle sra ]) {
        my $set_func = "set_" . $parameter;
        $self->$set_func();
	print $parameter, " ok\n";
    }
}

sub set_contributor {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $pfn = $accxml->{Contributor}->{Person}->{First};
     #my $pfm = $accxml->{Contributor}->{Person}->{Middle};
     my $pfl = $accxml->{Contributor}->{Person}->{Last};
     my $contributor = "$pfn $pfl";
     print "   Contributor: $contributor ";
     $contributor{ident $self} = $contributor;
}

sub set_lab {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $lab = $accxml->{Contributor}->{Laboratory};
     print "   Lab: $lab " if $lab;
     $lab{ident $self} = $lab;
}

sub set_title {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $title = $accxml->{Sample}->{Title};
     $title =~ s/^\s*//; $title =~ s/\s*$//; 
     print "   Title: $title ";
     $title{ident $self} = $title;
}

sub set_submission_date {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $date = $accxml->{Sample}->{Status}->{'Submission-Date'};
     print "   Submission date: $date ";
     $submission_date{ident $self} = $date;
}

sub set_type {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $type = $accxml->{Sample}->{Type};
     print "   Type: $type ";
     $type{ident $self} = $type;
}

sub set_strategy {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $strategy = $accxml->{Sample}->{'Library-Strategy'};
    print "   Strategy: $strategy\n";
    $strategy{ident $self} = $strategy;
}

sub set_source {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $source = $accxml->{Sample}->{'Library-Source'};
    print "   Source: $source\n";
    $source{ident $self} = $source;    
}

sub set_organism {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $organism = $accxml->{Sample}->{Channel}->{Organism};
    #my $organism = $accxml->{Sample}->{'Library-Organism'};
    print "   Organism: $organism\n";
    $organism{ident $self} = $organism;
}

sub set_characteristics {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $charact = $accxml->{Sample}->{Channel}->{'Characteristics'};
    $characteristics{ident $self} = $charact;
}

sub set_strain {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'strain');
    print $contents[0];
    $strain{ident $self} = $contents[0];
}

sub set_cellline {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'cell line');
    print $contents[0];
    $cellline{ident $self} = $contents[0];
}

sub set_devstage {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'development stage');
    print $contents[0];
    $devstage{ident $self} = $contents[0];
}

sub set_antibody {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'antibody');
    print $contents[0];
    $antibody{ident $self} = $contents[0];
}


sub set_supplementary_data {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $datal = $accxml->{Sample}->{'Supplementary-Data'};
    print Dumper($datal);
    $supplementary_data{ident $self} = $datal;
}

sub set_bed {
    my ($self) = @_;
    my @files = $self->get_content('supplementary_data', 'type', 'BED');
    $bed{ident $self} = \@files;
}

sub set_wiggle {
    my ($self) = @_;
    my @files = $self->get_content('supplementary_data', 'type', 'WIG');
    $wiggle{ident $self} = \@files;
}

sub set_sra {
    my ($self) = @_;
    my @files = $self->get_content('supplementary_data', 'type', 'SRA Experiment');
    $sra{ident $self} = \@files;
}

sub valid_sra {
    my ($self) = @_;
    my $valid = 1;
    for my $sra (@{$sra{ident $self}}) {
	$valid = 0 unless LWP::Simple::head($sra);
    }
    return $valid;
}

sub get_content {
    my ($self, $ele, $attr_name, $attr_value) = @_;
    my @contents;
    my $contentl;
    #no strict 'refs';
    #my $contentl = ${"$ele"}{ident $self};
    if ($ele eq 'characteristics') {
	$contentl = $characteristics{ident $self};
	$contentl = $self->set_characteristics() unless $contentl;
    }
    if ($ele eq 'supplementary_data') {
	$contentl = $supplementary_data{ident $self};
	$contentl = $self->set_supplementary_data() unless $contentl;
    }    

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
	if ($contentl->{$attr_name} eq $attr_value) {
	    my $content = $contentl->{'content'};
	    $content =~ s/^\s*//; $content =~ s/\s*$//;
	    push @contents, $content;
	}	
    }
    return @contents;
}

sub set_miniml {
    my ($self) = @_;
    my $ini = $config{ident $self};
    my $gsm_id = $gsm{ident $self};
    my $acc_url = $ini->{acc}{acc_url} . $gsm_id . "&targ=$ini->{acc}{targ}" . "&view=$ini->{acc}{view}" . "&form=$ini->{acc}{form}" ;
    my $accfile = $xmldir{ident $self} . $gsm_id . '.xml';
    print "miniml $accfile exists. use cache...\n" if -e $accfile;
    unless (-e $accfile) { 
	$accfile = fetch($acc_url, $accfile);
    }
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
