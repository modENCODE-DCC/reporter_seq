package GEO::Annotator;

use strict;
use Carp;
use Class::Std;
use Data::Dumper;
use ModENCODE::Parser::LWChado;

my %geo                    :ATTR( :name<geo>                   :default<undef>);
my %config                 :ATTR( :name<config>                :default<undef>);
my %unique_id              :ATTR( :name<unique_id>             :default<undef>);
my %seriesFH               :ATTR( :name<seriesFH>              :default<undef>);
my %reader                 :ATTR( :name<reader>                :default<undef>);
my %experiment             :ATTR( :name<experiment>            :default<undef>);
my %normalized_slots       :ATTR( :get<normalized_slots>       :default<undef>);
my %denorm_slots           :ATTR( :get<denorm_slots>           :default<undef>);
my %project                :ATTR( :get<project>                :default<undef>);
my %lab                    :ATTR( :get<lab>                    :default<undef>);
my %contributors           :ATTR( :get<contributors>           :default<undef>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    for my $parameter (qw[geo config unique_id seriesFH reader experiment]) {
	my $value = $args->{$parameter};
	defined $value || croak "can not find required parameter $parameter"; 
	my $set_func = "set_" . $parameter;
	$self->$set_func($value);
    }
    return $self;
}

sub set_all {
    my $self = shift;
    for my $parameter (qw[normalized_slots denorm_slots]) {
	my $set_func = "set_" . $parameter;
	$self->$set_func();	
    }
    for my $parameter (qw[project lab contributors]) {
	my $set_func = "set_" . $parameter;
	$self->$set_func();
    }
}

sub chado2series {
    my $self = shift;
    my $seriesFH = $seriesFH{ident $self};
    my $uniquename = $experiment{ident $self}->get_uniquename();
    my $project_announcement = 'This submission comes from a modENCODE project of ' . $project{ident $self} . '. For full list of modENCODE projects, see http://www.genome.gov/26524648 ';
    my $data_use_policy = 'For data usage terms and conditions, please refer to http://www.genome.gov/27528022 and http://www.genome.gov/Pages/Research/ENCODE/ENCODEDataReleasePolicyFinal2008.pdf';
    
    my @pubmed;
    my ($investigation_title, $project_goal);
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
	my ($name, $value, $rank, $type) = ($property->get_name(), 
					    $property->get_value(), 
					    $property->get_rank(), 
					    $property->get_type());
	$investigation_title = $value if $name =~ /Investigation\s*Title/i ;
	$project_goal = $value if $name =~ /Experiment\s*Description/i ;
	push @pubmed, $value if $name =~ /Pubmed_id/i;
    }

    print $seriesFH "^Series = ", $uniquename, "\n";
    print $seriesFH "!Series_title = " . substr($investigation_title, 0, 120), "\n";
    for my $summary (($project_announcement, $project_goal, $data_use_policy)) {
	print $seriesFH "!Series_summary = ", $summary, "\n";
    }
    if (scalar @pubmed) {
	for my $pubmed_id (@pubmed) {
	    print $seriesFH "!Series_pubmed_id = ", $pubmed_id, "\n";
	}
    }
    print $seriesFH "!Series_overall_design = ", $self->get_overall_design, "\n";

    my %contributors = %{$contributors{ident $self}};
    foreach my $rank (sort keys %contributors) {
	my $firstname = $contributors{$rank}{'first'};
	my $str = $firstname . ",";
	if ($contributors{$rank}{'mid'}) {
	    $str .= $contributors{$rank}{'mid'}[0] . ",";
	}
	my $lastname = $contributors{$rank}{'last'};
	$str .= $lastname;
	print $seriesFH "!Series_contributor = ", $str, "\n";
    }

    my @samples = $self->get_geo_id();
    for my $geoid (@samples) {
	print $seriesFH "!Series_sample_id = ", $geoid, "\n";
    }
}

sub set_normalized_slots {
    my $self = shift;
    $normalized_slots{ident $self} = $reader{ident $self}->get_normalized_protocol_slots();
}

sub set_denorm_slots {
    my $self = shift;
    $denorm_slots{ident $self} = $reader{ident $self}->get_denormalized_protocol_slots();
}

sub set_project {
    my $self = shift;
    my %projects = ('lieb' => 'Jason Lieb',
                   'celniker' => 'Susan Celniker',
                   'henikoff' => 'Steven Henikoff',
                   'karpen' => 'Gary Karpen',
                   'lai' => 'Eric Lai',
                   'macalpine' => 'David MacAlpine',
                   'piano' => 'Fabio Piano',
                   'snyder' => 'Michael Snyder',
                   'waterston' => 'Robert Waterston',
		    'white' => 'Kevin White');   
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
        my ($name, $value, $rank, $type) = ($property->get_name(), 
                                            $property->get_value(), 
                                            $property->get_rank(), 
                                            $property->get_type());
        if (lc($name) eq 'project' && defined($value) && $value ne '') {
            $project{ident $self} = $projects{lc($value)};
            last;
        }
    }
}

sub set_lab {
    my ($self, $experiment) = @_;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
        my ($name, $value, $rank, $type) = ($property->get_name(), 
                                            $property->get_value(), 
                                            $property->get_rank(), 
                                            $property->get_type());
        if (lc($name) eq 'lab' && defined($value) && $value ne '') {
            $lab{ident $self} = $value;
            last;
        }
    }    
}

sub set_contributors {
    my $self = shift;    
    my %person;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
        my ($name, $value, $rank, $type) = ($property->get_name(), 
                                            $property->get_value(), 
                                            $property->get_rank(), 
                                            $property->get_type());
        
        $person{$rank}{'affiliation'} = $value if $name =~ /Person\s*Affiliation/i;
        $person{$rank}{'address'} = $value if $name =~ /Person\s*Address/i;
        $person{$rank}{'phone'} = $value if $name =~ /Person\s*Phone/i;
        $person{$rank}{'first'} = $value if $name =~ /Person\s*First\s*Name/i;
        $person{$rank}{'last'} = $value if $name =~ /Person\s*Last\s*Name/i;
        $person{$rank}{'middle'} = $value if $name =~ /Person\s*Mid\s*Initials/i;
        $person{$rank}{'email'} = $value if $name =~ /Person\s*Email/i;
        $person{$rank}{'roles'} = $value if $name =~ /Person\s*Roles/i;
    }
    $contributors{ident $self} = \%person;
}

sub get_overall_design {
    my $self = shift;
    my $overall_design = '';
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[0];
	my $desc = $ap->get_protocol->get_description;
	$desc =~ s/\s+/_/g;
	$desc =~ s/\W+/ /;
	$desc =~ s/_/ /g;
	$overall_design .= $desc . " ";
    }
    return $overall_design;
}

sub get_geo_id {
    my $self = shift;
    my @affiliates = $self->get_affiliate_submissions();
    map {print "affiliate submission $_\n"} @affiliates;
    my %geo = $self->get_all_geo_id();
    my @ids;
    for my $aff (@affiliates) {
	print $aff, ":", @{$geo{$aff}}, "\n";
	push @ids, grep {$_ =~ /^GSM/} @{$geo{$aff}};
    }
    return @ids;
}

sub get_affiliate_submissions {
    my $self = shift;
    my @aff;
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}->[0]}; $i++) {
	my $ap = $denorm_slots{ident $self}->[0]->[$i];
	for my $datum (@{$ap->get_input_data()}) {
	    for my $attr (@{$datum->get_attributes()}) {
		if (lc($attr->get_type()->get_name()) eq 'reference' && lc($attr->get_type()->get_cv()->get_name()) eq 'modencode') {
		    my $t = $attr->get_value;
		    my @tt = split ":", $t;
		    push @aff, $tt[0];
		}
	    }
	}
    }
    return @aff;
}

sub get_all_geo_id {
    my $self = shift;
    my %idh;
    my $fh = $geo{ident $self};
    while(my $line = <$fh>) {
	chomp $line;
	next if $line =~ /^\s*$/;
	next if $line =~ /^#/;
	my @fields = split /\t/, $line;
	my @ids = split /,\s*/, $fields[2];
	#print "submission " . $fields[0] . " has geo id ";
	#map {print $_} @ids;
	#print "\n";
	$idh{$fields[0]} = \@ids;
    }
    return %idh;
}

1;
