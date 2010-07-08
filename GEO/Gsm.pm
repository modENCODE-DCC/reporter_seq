
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
my %lib_source      :ATTR( :get<lib_source>         :default<undef>);
my %source       :ATTR( :get<source>          :default<undef>);
my %organism      :ATTR( :get<organism>         :default<undef>);
my %strain      :ATTR( :get<strain>         :default<undef>);
my %cellline      :ATTR( :get<cellline>         :default<undef>);
my %devstage      :ATTR( :get<devstage>         :default<undef>);
my %antibody      :ATTR( :get<antibody>         :default<undef>);
my %supplementary_data  :ATTR( :get<supplementary_data>         :default<undef>);
my %general_data   :ATTR( :get<general_data>   :default<[]>);
my %bed             :ATTR( :get<bed>         :default<[]>);
my %wiggle         :ATTR( :get<wiggle>         :default<[]>);
my %sra             :ATTR( :get<sra>         :default<[]>);
my %characteristics  :ATTR( :get<characteristics>         :default<undef>);
my %tissue           :ATTR( :get<tissue>            :default<undef>);
my %timepoint        :ATTR( :get<timepoint>         :default<undef>);
my %num_channel      :ATTR( :get<num_channel>       :default<undef>);

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
    my $self = shift;
    for my $parameter (qw[miniml contributor lab title submission_date type strategy lib_source num_channel organism source characteristics strain devstage antibody supplementary_data wiggle sra tissue timepoint]) {
        my $set_func = "set_" . $parameter;
        $self->$set_func();
    }
}

sub set_contributor {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $pfn = $accxml->{Contributor}->{Person}->{First};
     #my $pfm = $accxml->{Contributor}->{Person}->{Middle};
     my $pfl = $accxml->{Contributor}->{Person}->{Last};
     my $contributor = "$pfn $pfl";
#     print "   Contributor: $contributor \n";
     $contributor{ident $self} = $contributor;
}

sub set_lab {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $lab = $accxml->{Contributor}->{Laboratory};
     $lab =~ s/^\s*//; $lab =~ s/\s*$//; 
#     print "   Lab: $lab \n" if $lab;
     $lab{ident $self} = $lab;
}

sub set_title {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $title = $accxml->{Sample}->{Title};
     $title =~ s/^\s*//; $title =~ s/\s*$//; 
#     print "   Title: $title \n";
     $title{ident $self} = $title;
}

sub set_submission_date {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $date = $accxml->{Sample}->{Status}->{'Submission-Date'};
     $date =~ s/^\s*//; $date =~ s/\s*$//; 
#     print "   Submission date: $date \n";
     $submission_date{ident $self} = $date;
}

sub set_type {
     my ($self) = @_;
     my $accxml = $miniml{ident $self};
     my $type = $accxml->{Sample}->{Type};
     $type =~ s/^\s*//; $type =~ s/\s*$//; 
#     print "   Type: $type \n";
     $type{ident $self} = $type;
}

sub set_strategy {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $strategy = $accxml->{Sample}->{'Library-Strategy'};
    $strategy =~ s/^\s*//; $strategy =~ s/\s*$//; 
#    print "   Strategy: $strategy\n";
    $strategy{ident $self} = $strategy;
}

sub set_lib_source {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $source = $accxml->{Sample}->{'Library-Source'};
    $source =~ s/^\s*//; $source =~ s/\s*$//; 
#    print "   Library Source: $source\n";
    $lib_source{ident $self} = $source;    
}

sub set_source {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $num_ch = $num_channel{ident $self};
    my $source;
    if ($num_ch == 1) {
	$source = $accxml->{Sample}->{Channel}->{Source};
    } else {
	$source = $accxml->{Sample}->{Channel}->[0]->{Source};
    }
    $source{ident $self} = $source;
}

sub set_num_channel {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $num_ch = $accxml->{Sample}->{'Channel-Count'};
#    print "   number of channels is $num_ch\n";
    $num_channel{ident $self} = $num_ch;
}

sub set_organism {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $num_ch = $num_channel{ident $self};
    my $organism;
    #my $organism = $accxml->{Sample}->{'Library-Organism'};
    if ($num_ch == 1) {
	$organism = $accxml->{Sample}->{Channel}->{Organism};
    } else {
	$organism = $accxml->{Sample}->{Channel}->[0]->{Organism};
    }
#    print "   Organism: $organism\n";
    $organism{ident $self} = $organism;
}

sub set_characteristics {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $num_ch = $num_channel{ident $self};
    my $charact = {};
    if ($num_ch == 1) {    
	$charact->{0} = $accxml->{Sample}->{Channel}->{Characteristics};
    } else {
	for (my $i=0; $i<$num_ch; $i++) {
	    $charact->{$i} = $accxml->{Sample}->{Channel}->[$i]->{Characteristics};
	}
    }
#    print Dumper($charact);
    $characteristics{ident $self} = $charact;
}

sub set_strain {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'strain');
#    print "strain is $contents[0] \n";
    $strain{ident $self} = $contents[0];
}

sub set_cellline {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'cell line');
#    print "cell line is $contents[0] \n";
    $cellline{ident $self} = $contents[0];
}

sub set_devstage {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'development stage');
#    print "devstage is $contents[0] \n";
    $devstage{ident $self} = $contents[0];
}

sub set_antibody {
    my ($self) = @_;
    my @contents;
    @contents = $self->get_content('characteristics', 'tag', 'antibody');
    @contents = $self->get_content('characteristics', 'tag', 'antibody', 1) if $contents[0] eq 'input';
#    print "antibody is $contents[0] \n";
    $antibody{ident $self} = $contents[0];
}

sub set_tissue {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'tissue');
#    print "tissue is $contents[0] \n";
    $tissue{ident $self} = $contents[0];    
}

sub set_timepoint {
    my ($self) = @_;
    my @contents = $self->get_content('characteristics', 'tag', 'time point');
#    print "time point is $contents[0] \n";
    $timepoint{ident $self} = $contents[0];      
}

sub set_supplementary_data {
    my ($self) = @_;
    my $accxml = $miniml{ident $self};
    my $datal = $accxml->{Sample}->{'Supplementary-Data'};
#    print Dumper($datal);
    $supplementary_data{ident $self} = $datal;
}

sub set_general_data {
    my ($self) = @_;
    my @files = ();
    @files = $self->get_content('supplementary_data', 'type', 'txt');
    $general_data{ident $self} = \@files;
}

sub set_bed {
    my ($self) = @_;
    my @files = ();
    @files = $self->get_content('supplementary_data', 'type', 'BED');
    $bed{ident $self} = \@files;
}

sub set_wiggle {
    my ($self) = @_;
    my @files = ();
    @files = $self->get_content('supplementary_data', 'type', 'WIG');
    $wiggle{ident $self} = \@files;
}

sub set_sra {
    my ($self) = @_;
    my @files = ();
    @files = $self->get_content('supplementary_data', 'type', 'SRA Experiment');
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
    my ($self, $ele, $attr_name, $attr_value, $channel) = @_;
    my @contents = ();
    my $contentl;
    #no strict 'refs';
    #my $contentl = ${"$ele"}{ident $self};
    if ($ele eq 'characteristics') {
	$contentl = $characteristics{ident $self};
	$contentl = $self->set_characteristics() unless $contentl;
	$contentl = $contentl->{0};
	$contentl = $contentl->{$channel} if $channel;
    }
    if ($ele eq 'supplementary_data') {
	$contentl = $supplementary_data{ident $self};
	$contentl = $self->set_supplementary_data() unless $contentl;
    }    

    if (ref($contentl) eq 'ARRAY') {
	for my $data (@$contentl) {
	    if (ref($data) eq 'HASH' && $data->{$attr_name} eq $attr_value) {
		my $content = $data->{'content'};
		$content =~ s/^\s*//; $content =~ s/\s*$//;
		push @contents, $content;
	    }
	}
    }
    if (ref($contentl) eq 'HASH') {
	print "it is a hash!!!";
	print Dumper($contentl);
	if ($contentl->{$attr_name} eq $attr_value) {
	    my $content = $contentl->{'content'};
	    $content =~ s/^\s*//; $content =~ s/\s*$//;
	    push @contents, $content;
	}
	print Dumper(@contents);
    }
    return @contents;
}

sub set_miniml {
    my ($self, $refresh) = @_;
    my $ini = $config{ident $self};
    my $gsm_id = $gsm{ident $self};
    my $acc_url = $ini->{acc}{acc_url} . $gsm_id . "&targ=$ini->{acc}{targ}" . "&view=$ini->{acc}{view}" . "&form=$ini->{acc}{form}" ;
    my $accfile = $xmldir{ident $self} . $gsm_id . '.xml';
#    print "miniml $accfile exists. use cache...\n" if -e $accfile;
    unless (-e $accfile && !$refresh) { 
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
