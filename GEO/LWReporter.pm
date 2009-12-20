package GEO::Reporter;

use strict;
use Carp;
use Class::Std;
use Data::Dumper;
use File::Basename;
use URI::Escape;
use HTML::Entities;


my %unique_id              :ATTR( :name<unique_id>             :default<undef>);
my %reader                 :ATTR( :name<reader>                :default<undef>);
my %experiment             :ATTR( :name<experiment>            :default<undef>);
my %normalized_slots       :ATTR( :set<normalized_slots>       :default<undef>);
my %denorm_slots           :ATTR( :set<denorm_slots>           :default<undef>);
my %num_of_rows            :ATTR( :set<num_of_rows>            :default<undef>);
my %ap_slots               :ATTR( :set<ap_slots>               :default<undef>);
my %project                :ATTR( :set<project>                :default<undef>);
my %lab                    :ATTR( :set<lab>                    :default<undef>);
my %contributors           :ATTR( :set<contributors>           :default<undef>);


sub BUILD {
    my ($self, $ident, $args) = @_;
    for my $parameter (qw[unique_id reader experiment]) {
	my $value = $args->{$parameter};
	defined $value || croak "can not find required parameter $parameter"; 
	my $set_func = "set_" . $parameter;
	$self->$set_func($value);
    }
    return $self;
}

sub get_all {
    my $self = shift;
    for my $parameter (qw[normalized_slots denorm_slots num_of_rows ap_slots project lab contributors]) {
        my $get_func = "get_" . $parameter;
        print "try to find $parameter ...";
        $self->$get_func();
        print " done\n";
    }
}

sub get_fastq_files {
    my $self = shift;
    my @fastqfiles = ();
    if ( defined($ap_slots{ident $self}->{'raw'}) ) {
	for my $ap (@{$normalized_slots{ident $self}->[$ap_slots{ident $self}->{'raw'}]}) {
	    for my $datum (@{$ap->get_output_data()}) {
		my ($name, $heading, $value) = ($datum->get_name(), $datum->get_heading(), $datum->get_value());
		push @fastqfiles, $value and last if ($name =~ /^fastq$/i and $value !~ /^\s*$/);
	    }
	}
    }
    return @fastqfiles;
}

sub get_geo_ids {
    my $self = shift;
    my @geo_ids = ();
    for my $ap (@{$normalized_slots{ident $self}->[$ap_slots{ident $self}->{'normalization'}]}) {
	for my $datum (@{$ap->get_output_data()}) {
            my ($name, $heading, $value) = ($datum->get_name(), $datum->get_heading(), $datum->get_value());
	    push @geo_ids, $value and last if ($name =~ /^geo\s*record$/i and $value !~ /^\s*$/) ;
	}
    }
    return @geo_ids;
}

sub get_wiggle_files {
    my $self = shift;
    my @wiggle_files = ();
    for my $ap (@{$normalized_slots{ident $self}->[$ap_slots{ident $self}->{'normalization'}]}) {
	for my $datum (@{$ap->get_output_data()}) {
            my ($value, $type) = ($datum->get_value(), $datum->get_type());
	    push @wiggle_files, $value and last if ($type->get_name() eq 'WIG') ;
	}
    }
    return @wiggle_files;    
}

sub get_normalized_slots {
    my $self = shift;
    $normalized_slots{ident $self} = $reader{ident $self}->get_normalized_protocol_slots();
}

sub get_denorm_slots {
    my $self = shift;
    $denorm_slots{ident $self} = $reader{ident $self}->get_denormalized_protocol_slots();
}

sub get_num_of_rows {
    my $self = shift;
    $num_of_rows{ident $self} = scalar @{$denorm_slots{ident $self}->[0]};
}

sub get_ap_slots {
    my $self = shift;
    my %slots;
    $slots{'seq'} = $self->get_slotnum_seq();
    print "found sequencing protocol at slot $slots{'seq'}..." if defined($slots{'seq'});
    $slots{'normalization'} = $self->get_slotnum_normalize();
    print "found normalization protocol at slot $slots{'normalization'}..." if defined($slots{'normalization'});
    $slots{'raw'} = $self->get_slotnum_raw();
    print "found raw protocol at slot $slots{'raw'}..." if defined($slots{'raw'});
    $slots{'immunoprecipitation'} = $self->get_slotnum_ip();
    $ap_slots{ident $self} = \%slots;
}

sub get_project {
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
        if ($name =~ /^\s*Project\s*$/i) {
            $value =~ s/\n//g;
            $value =~ s/^\s*//;
            $value =~ s/\s*$//;
            $project{ident $self} = $projects{lc($value)};
        }
    }
}

sub get_lab {
    my ($self, $experiment) = @_;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
        my ($name, $value, $rank, $type) = ($property->get_name(), 
                                            $property->get_value(), 
                                            $property->get_rank(), 
                                            $property->get_type());
        $lab{ident $self} = $value if ($name =~ /^\s*Lab\s*$/i); 
    }    
}

sub get_contributors {
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

sub get_slotnum_seq {
    my $self = shift;
    my $type = "sequencing";
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    if (scalar(@aps) > 1) {
        croak("you confused me with more than 1 sequencing protocols.");
    } elsif (scalar(@aps) == 0) {
        return -1;
    } else {
        return $aps[0];
    }    
}

sub get_slotnum_normalize {
    my $self = shift;
    my @types = ('WIG');
    for my $type (@types) {
        my @aps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
        return $aps[0] if scalar(@aps);
    }
    croak("can not find the normalization protocol");
}

sub get_slotnum_raw {
    my $self = shift;
    my @types = ('FASTQ');
    for my $type (@types) {
        my @aps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
        return $aps[0] if scalar(@aps);
    }
    return undef;
}

sub get_slotnum_ip {
    my $self = shift;
    my $type = 'immunoprecipitation';
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    return $aps[-1] if scalar(@aps);
    return undef;
}

sub get_slotnum_by_datum_property {#this could go into a subclass of experiment 
    #direction for input/output, field for heading/name, value for the text of heading/name
    my ($self, $direction, $isattr, $field, $fieldtext, $value) = @_;
    my $experiment = $experiment{ident $self};
    my @slots = ();
    my $found = 0;
    for (my $i=0; $i<scalar(@{$experiment->get_applied_protocol_slots()}); $i++) {
        for my $applied_protocol (@{$experiment->get_applied_protocol_slots()->[$i]}) {
            last if $found;
	    my $func = 'get_' . $direction . '_data';
	    for my $datum (@{$applied_protocol->$func()}) {
		if ($isattr) {
		    for my $attr (@{$datum->get_attributes()}) {
			if (_get_attr_value($attr, $field, $fieldtext) =~ /$value/i) {
			    push @slots, $i;
			    $found = 1 and last;
			}
		    }                       
		} else {
		    if (_get_datum_info($datum, $field) =~ /$value/i) {
			push @slots, $i;
			$found = 1 and last;
		    }
		}		
	    }
        }
        $found = 0;
    }
    return @slots;
}

sub get_slotnum_by_protocol_property {
    my ($self, $isattr, $field, $fieldtext, $value) = @_;
    my @slots = ();
    my $found = 0;
    for (my $i=0; $i<scalar(@{$experiment{ident $self}->get_applied_protocol_slots()}); $i++) {
        for my $ap (@{$experiment{ident $self}->get_applied_protocol_slots()->[$i]}) {
            last if $found;
            if ($isattr) {#protocol attribute
                for my $attr (@{$ap->get_protocol()->get_attributes()}) {
                    if (_get_attr_value($attr, $field, $fieldtext) =~ /$value/i) {
                        push @slots, $i;
                        $found = 1 and last;
                    }
                }
            } else {#protocol
                if (_get_protocol_info($ap->get_protocol(), $field) =~ /$value/i) {
                    push @slots, $i;
                    $found = 1 and last;
                }
            }
        }
        $found = 0;
    }    
    return @slots;
}

sub _get_protocol_info {
    my ($protocol, $field) = @_;
    my $func = "get_$field";
    return $protocol->$func();
}

sub _get_attr_value {
    my ($attr, $field, $fieldtext) = @_;
    return $attr->get_value() if (($field eq 'name') && ($attr->get_name() =~ /$fieldtext/i));
    return $attr->get_value() if (($field eq 'heading') && ($attr->get_heading() =~ /$fieldtext/i));
    return undef;
}

sub _get_datum_info {
    my ($datum, $field) = @_;
    return $datum->get_name() if $field eq 'name';
    return $datum->get_heading() if $field eq 'heading';
    return $datum->get_type()->get_name() if $field eq 'type';
    return $datum->get_termsource()->get_db()->get_name() . ":" . $datum->get_termsource()->get_accession() if $field eq 'dbxref';
}


1;
