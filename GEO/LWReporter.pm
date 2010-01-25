package GEO::LWReporter;

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
my %organism               :ATTR( :set<organism>               :default<undef>);
my %strain                 :ATTR( :set<strain>                 :default<undef>);
my %cellline               :ATTR( :set<cellline>               :default<undef>);
my %devstage               :ATTR( :set<devstage>               :default<undef>);
my %antibody               :ATTR( :set<antibody>               :default<undef>);
my %factors                :ATTR( :set<factors>                :default<undef>);
my %tgt_gene               :ATTR( :set<tgt_gene>               :default<undef>);

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
    for my $parameter (qw[normalized_slots denorm_slots num_of_rows ap_slots project lab contributors factors organism strain cellline devstage tgt_gene antibody]) {
        my $get_func = "get_" . $parameter;
        print "try to find $parameter ...";
        $self->$get_func();
        print " done\n";
    }
}

sub get_organism {
    my $self = shift;
    my $protocol = $denorm_slots{ident $self}->[0]->[0]->get_protocol();
    for my $attr (@{$protocol->get_attributes()}) {
        print $attr->get_value() and $organism{ident $self} = $attr->get_value() if $attr->get_heading() eq 'species';
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
            my ($type, $heading, $value) = ($datum->get_type(), $datum->get_heading(), $datum->get_value());
	    push @geo_ids, $value and last if ($type->get_name() =~ /^geo_record$/i and $value !~ /^\s*$/) ;
	}
    }
    return @geo_ids;
}

sub get_sra_ids {
    my $self = shift;
    my @sra_ids = ();
    my $rtype = 'ShortReadArchive_project_ID (SRA)';
    for my $ap (@{$normalized_slots{ident $self}->[$ap_slots{ident $self}->{'seq'}]}) {
	for my $datum (@{$ap->get_output_data()}) {
            my ($type, $heading, $value) = ($datum->get_type(), $datum->get_heading(), $datum->get_value());
	    push @sra_ids, $value and last if ($type->get_name() =~ /^$rtype$/i and $value !~ /^\s*$/) ;
	}
    }
    return @sra_ids;
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
    print Dumper($reader{ident $self}->get_normalized_protocol_slots());
    $normalized_slots{ident $self} = $reader{ident $self}->get_normalized_protocol_slots();
}

sub get_denorm_slots {
    my $self = shift;
    print Dumper($reader{ident $self}->get_denormalized_protocol_slots());
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

sub get_factors {
    my $self = shift;
    my %factor;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
	my ($name, $value, $rank, $type) = ($property->get_name(), 
					    $property->get_value(), 
					    $property->get_rank(), 
					    $property->get_type());
	if ($name =~ /Experimental\s*Factor\s*Name/i) {
	    $factor{$rank} = [$value];
	}
	if ($name =~ /Experimental\s*Factor\s*Type/i) {
	    push @{$factor{$rank}}, $value;
	    if (defined($property->get_termsource())) {
		push @{$factor{$rank}} , ($type->get_cv()->get_name(), 
					  $property->get_termsource()->get_accession());
	    }
	}
    }
    print Dumper(%factor);
    $factors{ident $self} = \%factor;
}

sub get_tgt_gene {
    my $self = shift;
    my $factors = $factors{ident $self};
    my $header;
    for my $rank (keys %$factors) {
	my $type = $factors->{$rank}->[1];
	$header = $factors->{$rank}->[0] and last if $type eq 'gene';
    }
    if ($header) {
        my $tgt_gene = $self->get_value_by_info(0, 'name', $header);
        print "tgt gene is:", $tgt_gene;
        $tgt_gene{ident $self} = $tgt_gene;
    }
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
    my @types = ('WIG', 'Sequence_Alignment\/Map \(SAM\)');
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

sub get_strain {
    my $self = shift;
    #for my $row (@{$groups{ident $self}->{0}->{0}}) {
    for my $row ((0..$num_of_rows{ident $self}-1)) {
        my $strain = $self->get_strain_row($row);
        print "strain $strain\n" and $strain{ident $self} = $strain and last if defined($strain);
    }
}

sub get_strain_row {
    my ($self, $row) = @_;
    my ($strain, $tgt_gene, $tag);
    for (my $i=0; $i<scalar @{$normalized_slots{ident $self}}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        print $ap->get_protocol->get_name, "\n";
        for my $datum (@{$ap->get_input_data()}) {
            my ($name, $heading, $value, $type) = ($datum->get_name(), $datum->get_heading(), $datum->get_value(), $datum->get_type());
            print "$name, $heading, $value\n";
            if (lc($name) =~ /^\s*strain\s*$/ || $type->get_name() eq 'strain_or_line') {
                if ($value =~ /[Ss]train:(.*)&/) {
                    my $name = $1;
                    if ($name =~ /(.*?):/) {
                        my $tmp = uri_unescape($1);
                        $tmp =~ s/_/ /g;
                        $strain .= $tmp;
                    } else {
                        my $tmp = uri_unescape($name);    
                        $tmp =~ s/_/ /g;
                        $strain .= $tmp;
                    }
                } else { #fly strain
                    $value =~ /(.*)&/ ;
                    my $tmp = uri_unescape($1);
                    $tmp =~ s/_/ /g;
                    $strain .= $tmp;
                }
            }
            for my $attr (@{$datum->get_attributes()}) {
                my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                if (lc($aname) =~ /^\s*strain\s*$/) {
                    if ( $avalue =~ /[Ss]train:(.*)&/ ) {
                        my $name = $1;
                        if ($name =~ /(.*?):/) {
                            my $tmp = uri_unescape($1);
                            $tmp =~ s/_/ /g;
                            $strain .= $tmp;
                        }
                    } else {
                        $value =~ /(.*)&/ ;
                        my $tmp = uri_unescape($1);
                        $tmp =~ s/_/ /g;
                        $strain .= $tmp;                        
                    }
                }
                if (lc($aheading =~ /^target\s*id$/)) {
                    $tgt_gene = uri_unescape($avalue);
                }
                if (lc($aheading =~ /^\s*tags\s*$/)) {
                    $tag = uri_unescape($avalue);
                }               
            }
        }
    }
    if ( defined($strain) ) {
        $strain .= " (engineered, target gene $tgt_gene" if defined($tgt_gene);
        $strain .= " tagged by $tag)" if defined($tag);
        return $strain;
    }
    return undef;
}


sub get_cellline {
    my $self = shift;
    #for my $row (@{$groups{ident $self}->{0}->{0}}) {
    for my $row ((0..$num_of_rows{ident $self}-1)) {
        my $cellline = $self->get_cellline_row($row);
        print "cell line $cellline\n" and $cellline{ident $self} = $cellline and last if defined($cellline);
    }
}

sub get_cellline_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<scalar @{$normalized_slots{ident $self}}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $datum (@{$ap->get_input_data()}) {
            my ($name, $heading, $value, $type) = ($datum->get_name(), $datum->get_heading(), $datum->get_value(), $datum->get_type());
            if (lc($name) =~ /^\s*cell[_\s]*line\s*$/ || $type->get_name() eq 'cell_line') {
                if ( $value =~ /[Cc]ell[Ll]ine:(.*?):/ ) {
                    my $tmp = uri_unescape($1);
                    $tmp =~ s/_/ /g;
                    return $tmp;
                }
            }
            for my $attr (@{$datum->get_attributes()}) {
                my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                if (lc($aname) =~ /^cell[_\s]*line/) {
                    if ( $avalue =~ /[Cc]ell[Ll]ine:(.*?):/ ) {
                        my $tmp = uri_unescape($1);
                        $tmp =~ s/_/ /g;
                        return $tmp;
                    }
                }
            }
        }
    }
    return undef;
}

sub get_devstage {
    my $self = shift;
    #for my $row (@{$groups{ident $self}->{0}->{0}}) {
    for my $row ((0..$num_of_rows{ident $self}-1)) {
        my $devstage = $self->get_devstage_row($row);
        print "dev stage $devstage\n" and $devstage{ident $self} = $devstage and last if defined($devstage);
    }
}

sub get_devstage_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<scalar @{$normalized_slots{ident $self}}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $datum (@{$ap->get_input_data()}) {
            my ($name, $heading, $value, $type) = ($datum->get_name(), $datum->get_heading(), $datum->get_value(), $datum->get_type());
            if (lc($name) =~ /^\s*stage\s*$/ || $type->get_name() eq 'developmental_stage') {
                if ( $value =~ /[Dd]ev[Ss]tage(Worm|Fly):(.*?):/ ) {
                    my $tmp = uri_unescape($2);
                    $tmp =~ s/_/ /g;
                    return $tmp;
                }
            }
            for my $attr (@{$datum->get_attributes()}) {
                my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                if (lc($aname) =~ /dev.*stage/) {
                    if ( $avalue =~ /[Dd]ev[Ss]tage(Worm|Fly):(.*?):/ ) {
                        my $tmp = uri_unescape($2);
                        $tmp =~ s/_/ /g;
                        return $tmp;
                    }
                }               
            }
        }
    }
    return undef;
}

sub get_antibody {
    my $self = shift;
    if ($ap_slots{ident $self}->{'immunoprecipitation'}) {
        #for my $row (@{$groups{ident $self}->{0}->{0}}) {
	for my $row ((0..$num_of_rows{ident $self}-1)) {	    
            my $ab = $self->get_antibody_row($row);
	    if ($ab) {
		if (is_antibody($ab) != -1) {
		    print "antibody", $ab->get_value and $antibody{ident $self} = $ab;
		}
	    }
        }
    }
}

sub is_antibody {
    my $ab = shift;
    my $antibody = $ab->get_value();
    return -1 unless $antibody;
    $antibody =~ /[Aa][Bb]:([\w ]*?):/;
    $antibody = $1;
    $antibody =~ s/ +/ /g;
    print $antibody;
    my @special_antibodies = ('No Antibody Control', 'AB46540_NIgG');
    my $is_control = 0;
    for my $control (@special_antibodies) {
	$is_control = 1 and last if $antibody eq $control;
    }
    return 0 if $is_control;
    return 1;
}

sub get_antibody_row { #keep it as a datum object
    my ($self, $row) = @_;
    print "row $row";
    my $denorm_slots = $denorm_slots{ident $self} ;
    my $ap_slots = $ap_slots{ident $self} ;
    my $ip_ap = $denorm_slots->[$ap_slots->{'immunoprecipitation'}]->[$row];
    my $antibodies;
    eval { $antibodies = _get_datum_by_info($ip_ap, 'input', 'name', 'antibody') } ;
    print Dumper($antibodies->[0]);
    return $antibodies->[0] unless $@;
    print "antibody not found.";
    return undef;
}

sub get_value_by_info {
    my ($self, $row, $field, $fieldtext) = @_;
    for (my $i=0; $i<scalar @{$normalized_slots{ident $self}}; $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[$row];
	for my $direction (('input', 'output')) {
	    my $func = "get_" . $direction . "_data";
	    for my $datum (@{$ap->$func()}) {
		my ($name, $heading, $value) = ($datum->get_name(), $datum->get_heading(), $datum->get_value());
		if ($field eq 'name') {
		    return $value if $name =~ /$fieldtext/;
		}
		if ($field eq 'heading') {
		    return $value if $heading =~ /$fieldtext/;
		}
		for my $attr (@{$datum->get_attributes()}) {
		    my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
		    if ($field eq 'name') {
			return $avalue if $aname =~ /$fieldtext/;		    
		    }
		    if ($field eq 'heading') {
			return $avalue if $aheading =~ /$fieldtext/;
		    }	    
		}
	    }
	}
    }
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

sub _get_datum_by_info { 
    my ($ap, $direction, $field, $fieldtext) = @_;
    my @data = ();

    if ($direction eq 'input') {
        for my $datum (@{$ap->get_input_data()}) {
            if ($field eq 'name') {push @data, $datum if $datum->get_name() =~ /$fieldtext/i;}
            if ($field eq 'heading') {push @data, $datum if $datum->get_heading() =~ /$fieldtext/i;}        
        }
    }
    if ($direction eq 'output') {
        for my $datum (@{$ap->get_output_data()}) {
            if ($field eq 'name') {push @data, $datum if $datum->get_name() =~ /$fieldtext/i;}
            if ($field eq 'heading') {push @data, $datum if $datum->get_heading() =~ /$fieldtext/i;}
        }
    }
    croak("can not find data that has fieldtext like $fieldtext in field $field in chado.data table") unless (scalar @data);
    return \@data;
}

1;
