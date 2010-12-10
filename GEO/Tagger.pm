package GEO::Tagger;

use strict;
use Carp;
use Class::Std;
use Data::Dumper;
use File::Basename;
use URI::Escape;
use HTML::Entities;
use ModENCODE::Parser::LWChado;

my %config                 :ATTR( :name<config>                :default<undef>);
my %unique_id              :ATTR( :name<unique_id>             :default<undef>);
my %reader                 :ATTR( :name<reader>                :default<undef>);
my %experiment             :ATTR( :name<experiment>            :default<undef>);
my %normalized_slots       :ATTR( :get<normalized_slots>       :default<undef>);
my %denorm_slots           :ATTR( :get<denorm_slots>           :default<undef>);
my %num_of_rows            :ATTR( :get<num_of_rows>            :default<undef>);
my %num_of_cols            :ATTR( :get<num_of_cols>            :default<undef>);
my %title                  :ATTR( :get<title>                  :default<undef>);
my %description            :ATTR( :get<description>            :default<undef>);
my %organism               :ATTR( :get<organism>               :default<undef>);
my %project                :ATTR( :get<project>                :default<undef>);
my %lab                    :ATTR( :get<lab>                    :default<undef>);
my %factors                :ATTR( :get<factors>                :default<undef>);
my %data_type              :ATTR( :get<data_type>              :default<undef>);
my %assay_type             :ATTR( :get<assay_type>             :default<undef>);
my %hyb_slot               :ATTR( :get<hyb_slot>               :default<undef>);
my %seq_slot               :ATTR( :get<seq_slot>               :default<undef>);
my %ip_slot                :ATTR( :get<ip_slot>                :default<undef>);
my %raw_slot               :ATTR( :get<raw_slot>               :default<undef>);
my %norm_slot              :ATTR( :get<norm_slot>              :default<undef>);
my %strain                 :ATTR( :get<strain>                 :default<undef>);
my %cellline               :ATTR( :get<cellline>               :default<undef>);
my %devstage               :ATTR( :get<devstage>               :default<undef>);
my %tissue                 :ATTR( :get<tissue>                 :default<undef>);
my %sex                    :ATTR( :get<sex>                    :default<undef>);
my %antibody               :ATTR( :get<antibody>               :default<undef>);
my %tgt_gene               :ATTR( :get<tgt_gene>               :default<undef>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    for my $parameter (qw[unique_id reader experiment config]) {
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

    my $aff = $self->affiliate_submission;
    if (scalar @$aff) {
	#my $trans_self_normalized_slots = _trans($self->get_normalized_slots);
	my $trans_self_denorm_slots = _trans($self->get_denorm_slots); #like sdrf now
	my $reporters = {};
	for (my $i=0; $i<scalar @$aff; $i++) {
	    my $attr = $aff->[$i]->[0];
	    my @fields = split ':', $attr->get_value;
	    my $id = $fields[0];
	    my $datum = $aff->[$i]->[1];
	    my $row = $aff->[$i]->[2]; #the row in self sdrf
	    my $reporter;
	    if ( exists $reporters->{$id} ) {
		$reporter = $reporters->{$id}->[0];
	    } else {
		$reporter = $self->affiliate_submission_reporter($id);
		$reporters->{$id}->[0] = $reporter;
		$reporters->{$id}->[1] = _trans($reporter->get_denorm_slots);
	    }
	    my $ap_row = $reporter->get_ap_row_by_data($datum->get_name, $datum->get_value); #the row in reporter sdrf
	    #merge row from reporter and row from self
	    #$trans_self_normalized_slots->[$row] = [@{$reporters->{$id}->[1]->[$ap_row]}, @{$trans_self_normalized_slots->[$row]}];
	    $trans_self_denorm_slots->[$row] = [@{$reporters->{$id}->[1]->[$ap_row]}, @{$trans_self_denorm_slots->[$row]}];
	}
	#$normalized_slots{ident $self} = _trans($trans_self_normalized_slots);
	$denorm_slots{ident $self} = _trans($trans_self_denorm_slots);
    }        
    for my $parameter (qw[num_of_rows num_of_cols title description project lab factors data_type assay_type hyb_slot seq_slot ip_slot raw_slot norm_slot strain cellline devstage tissue sex antibody tgt_gene]) {
        my $set_func = "set_" . $parameter;
	my $get_func = "get_" . $parameter;
        print "try to find $parameter ...";
        $self->$set_func();
	my $t = $self->$get_func();
	if ( defined($t) ) {
	    if ($parameter eq 'antibody') {
		my @ab = grep {$_->get_heading() eq 'target name'} @{$t->get_attributes()};
		print $ab[0]->get_value();
	    } elsif ($parameter eq 'factors') {
		#map {print $t->{$_}->[0], " "} (keys %$t);
		my %of = $self->get_other_factors();
		while (my ($k, $v) = each %of) {print " $k : $v"}
	    } else {
		print $t;
	    }
	} else {
	    print "NA";
	}
	print " done\n";
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

################################################################################################
# the following functions are helper ones to merge a submission with its affiliate submission. #
# sometimes, biological sample preparation is submitted individually to DCC and then referred  #
# in another submission using array or seq.                                                    #
# begin of helpers...                                                                          #
################################################################################################
sub affiliate_submission {
    my $self = shift;
    my $aff = [];
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}->[0]}; $i++) {
        my $ap = $denorm_slots{ident $self}->[0]->[$i];
	for my $datum (@{$ap->get_input_data()}) {
	    for my $attr (@{$datum->get_attributes()}) {
		if (lc($attr->get_type()->get_name()) eq 'reference' && lc($attr->get_type()->get_cv()->get_name()) eq 'modencode') {
		    print join(" ", ($datum->get_value, $attr->get_value, $i, "\n"));
		    push @$aff, [$attr, $datum, $i]; #attr has affiliate submission id, datum has affiliate submission relevant row value, $i is row in self.
		}
	    }
	}
    }
    return $aff;
}

sub _trans {
    my $matrix = shift;
    my $trans = [[]];
    for (my $i=0; $i<scalar @$matrix; $i++) {
	for (my $j=0; $j<scalar @{$matrix->[$i]}; $j++) {
	    $trans->[$j]->[$i] = $matrix->[$i]->[$j];
	}
    }
    return $trans;
}

sub affiliate_submission_reporter {
    my ($self, $id) = @_;
    my $ini = $self->get_config();
    my $dbname = $ini->{database}{dbname};
    my $dbhost = $ini->{database}{host};
    my $dbusername = $ini->{database}{username};
    my $dbpassword = $ini->{database}{password};
    #search path for this dataset, this is fixed by modencode chado db
    my $schema = $ini->{database}{pathprefix}. $id . $ini->{database}{pathsuffix} . ',' . $ini->{database}{schema};

    #start read chado
    print "connecting to database ...";
    my $reader = new ModENCODE::Parser::LWChado({
        'dbname' => $dbname,
        'host' => $dbhost,
        'username' => $dbusername,
        'password' => $dbpassword,
						});
    my $experiment_id = $reader->set_schema($schema);
    print "database connected.\n";
    print "loading experiment ...";
    $reader->load_experiment($experiment_id);
    my $experiment = $reader->get_experiment();
    my $reporter = new GEO::Tagger({
        'config' => $ini,
        'unique_id' => $id,
        'reader' => $reader,
        'experiment' => $experiment,
				 });
    for my $parameter (qw[normalized_slots denorm_slots]) {
        my $set_func = "set_" . $parameter;
        $reporter->$set_func();
    }
    return $reporter;
}

sub get_ap_row_by_data {
    my ($self, $name, $value) = @_;
    my $last_ap_slot = $self->get_denorm_slots->[-1];
    for (my $i=0; $i<scalar @$last_ap_slot; $i++) {
	my $ap = $last_ap_slot->[$i];
	for my $data (@{$ap->get_output_data()}) {
	    if ($data->get_name() eq $name && $data->get_value() =~ /$value/) {
		return $i;
	    }
	}
    }
}
################################################################################################
# end of helpers                                                                               # 
################################################################################################
 
sub set_num_of_rows {
    my $self = shift;
    $num_of_rows{ident $self} = scalar @{$denorm_slots{ident $self}->[0]};
}

sub set_num_of_cols {
    my $self = shift;
    $num_of_cols{ident $self} = scalar @{$denorm_slots{ident $self}};
}

sub set_title {
    my $self = shift;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
        my ($name, $value) = ($property->get_name(), $property->get_value());
	$title{ident $self} = $value and last if $name eq 'Investigation Title';
    }
}

sub set_description {
    my $self = shift;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
        my ($name, $value) = ($property->get_name(), $property->get_value());
        $description{ident $self} = $value and last if $name eq 'Experiment Description';
    }
}

sub set_organism {
    my $self = shift;
    my $protocol = $denorm_slots{ident $self}->[0]->[0]->get_protocol();
    for my $attr (@{$protocol->get_attributes()}) {
        $organism{ident $self} = $attr->get_value() if $attr->get_heading() =~ /species/i;
    }
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

sub set_factors {
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
    $factors{ident $self} = \%factor;
}

sub set_data_type {
    my ($self, $experiment) = @_;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
        my ($name, $value, $rank, $type) = ($property->get_name(),
                                            $property->get_value(),
                                            $property->get_rank(),
                                            $property->get_type());
        if (lc($name) eq 'data type' && defined($value) && $value ne '') {
            $data_type{ident $self} = $value;
            last;
        }
    }
}

sub set_assay_type {
    my ($self, $experiment) = @_;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
        my ($name, $value, $rank, $type) = ($property->get_name(),
                                            $property->get_value(),
                                            $property->get_rank(),
                                            $property->get_type());
        if (lc($name) eq 'assay type' && defined($value) && $value ne '') {
            $assay_type{ident $self} = $value;
            last;
        }
    }
}

sub set_hyb_slot {
    my $self = shift;
    my $slot = $self->get_slotnum_hyb();
    $hyb_slot{ident $self} = $slot if $slot != -1;
}

sub set_seq_slot {
    my $self = shift;
    my $slot = $self->get_slotnum_seq();
    $seq_slot{ident $self} = $slot if $slot != -1;
}

sub set_ip_slot {
    my $self = shift;
    my $slot = $self->get_slotnum_ip();
    $ip_slot{ident $self} = $slot if defined($slot) && $slot != -1;
}

sub set_raw_slot {
    my $self = shift;
    $raw_slot{ident $self} = $self->get_slotnum_raw_array() if defined($hyb_slot{ident $self});
    if (defined($seq_slot{ident $self})) {
	my $slot = $self->get_slotnum_raw_seq();
	$raw_slot{ident $self} = $slot if defined($slot);
    }
}

sub set_norm_slot {
    my $self = shift;
    $norm_slot{ident $self} = $self->get_slotnum_normalize();
}

sub set_strain {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
	my $s = $self->get_strain_row($row);
	$strain{ident $self} = $s and last if defined($s);
    }
}

sub set_cellline {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
        my $c = $self->get_cellline_row($row);
	$cellline{ident $self} = $c and last if defined($c);
    }
}

sub set_devstage {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
        my $d = $self->get_devstage_row($row);
	$devstage{ident $self} = $d and last if defined($d);
    }
}

sub set_tissue {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
	my $t = $self->get_tissue_row(0);
	$tissue{ident $self} = $t and last if defined($t);
    }
}

sub set_sex {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
	my $sex = $self->get_sex_row($row);
	$sex{ident $self} = $sex and last if defined($sex);
    }
}

sub set_antibody {
    my $self = shift;
    if ($ip_slot{ident $self}) {
	for my $row (0..$num_of_rows{ident $self}-1) {	    
            my $ab = $self->get_antibody_row($row);
	    if ($ab) {
		if (is_antibody($ab) != -1) {
		    $antibody{ident $self} = $ab;
		    last;
		}
	    }
        }
    }
}

sub set_tgt_gene {
    my $self = shift;
    my $factors = $factors{ident $self};
    my $header;
    for my $rank (keys %$factors) {
        my $type = $factors->{$rank}->[1];
        $header = $factors->{$rank}->[0] and last if $type eq 'gene';
    }
    if ($header) {
        my $tgt_gene = $self->_get_value_by_info(0, 'name', $header);
        $tgt_gene{ident $self} = $tgt_gene;
    }
}

sub get_slotnum_hyb {
    my $self = shift;
    my $type = "hybrid";
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    if (scalar(@aps) > 1) {
        croak("you confused me with more than 1 hybridization protocols.");
    } elsif (scalar(@aps) == 0) {
        return -1;
    } else {
        return $aps[0];
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

sub get_slotnum_ip {
    my $self = shift;
    my $type = 'immunoprecipitation';
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    return $aps[-1] if scalar(@aps);
    return undef;
}

sub get_slotnum_raw_array {
    my $self = shift;
    my @types = ('nimblegen_microarray_data_file (pair)', 'CEL', 'agilent_raw_microarray_data_file', 'agilent_raw_microarray_data_file (TXT)', 'raw_microarray_data_file');
    for my $type (@types) {
        my @aps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
        #even there are more than 1 raw-data-generating protocols, choose the first one since it is the nearest to hyb protocol
        return $aps[0] if scalar(@aps);
    }
    croak("can not find the protocol that generates raw data"); #raw array data must have been given to us.
}

sub get_slotnum_raw_seq {
    my $self = shift;
    my @types = ('FASTQ', 'SFF', 'QSEQ');
    for my $type (@types) {
        my @aps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
        return $aps[0] if scalar(@aps);
    }
    return undef; #seq data might not linked in SDRF, or the link does not exist any more. need to fetch it somewhere else.
}

sub get_slotnum_normalize {
    my $self = shift;
    my @types = ('WIG', 'BED', 'Sequence_Alignment/Map (SAM)', 'Signal_Graph_File');
    for my $type (@types) {
        my @aps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
        return $aps[0] if scalar(@aps);
    }
    return undef; #RT-PCR
}

sub get_strain_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $datum (@{$ap->get_input_data()}) {
            my ($name, $heading, $value, $type) = ($datum->get_name(), $datum->get_heading(), $datum->get_value(), $datum->get_type());
            if (lc($name) =~ /^\s*strain\s*$/ || $type->get_name() eq 'strain_or_line') {
                if ($value =~ /[Fly|Worm]?[Ss]train:(.*)&/) {
                    my $name = $1;
                    if ($name =~ /(.*?):/) {
                        my $tmp = uri_unescape($1);
                        $tmp =~ s/_/ /g;
                        return $tmp;
                    } else {
                        my $tmp = uri_unescape($name);    
                        $tmp =~ s/_/ /g;
                        return $tmp;
                    }
                } else { #old fly strain info
                    $value =~ /(.*)&/ ;
                    my $tmp = uri_unescape($1);
                    $tmp =~ s/_/ /g;
                    return $tmp;
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
                            return $tmp;
                        }
                    } else {
                        $value =~ /(.*)&/ ;
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

sub get_cellline_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
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

sub get_devstage_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $datum (@{$ap->get_input_data()}) {
            my ($name, $heading, $value, $type) = ($datum->get_name(), $datum->get_heading(), $datum->get_value(), $datum->get_type());
            if (lc($name) =~ /^\s*stage\s*$/ || $type->get_name() eq 'developmental_stage') {
                if ( $value =~ /[Dd]ev[Ss]tage(Worm|Fly)?:(.*?):/ ) {
                    my $tmp = uri_unescape($2);
                    $tmp =~ s/_/ /g;
                    return $tmp;
                }
            }
            for my $attr (@{$datum->get_attributes()}) {
                my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                if (lc($aname) =~ /dev.*stage/) {
                    if ( $avalue =~ /[Dd]ev[Ss]tage(Worm|Fly)?:(.*?):/ ) {
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

sub get_tissue_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $datum (@{$ap->get_input_data()}) {
            my ($name, $heading, $value) = ($datum->get_name(), $datum->get_heading(), $datum->get_value());
            if (lc($name) =~ /^\s*tissue\s*$/) {
                if ( $value =~ /[Tt]issue:(.*?):/ ) {
		    print "regex is $1";
                    my $tmp = uri_unescape($1);
                    $tmp =~ s/_/ /g;
                    return $tmp;
                }
            }
            for my $attr (@{$datum->get_attributes()}) {
                my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                if (lc($aheading) =~ /^\s*tissue\s*$/) {
		    my $tmp = uri_unescape($avalue);
		    $tmp =~ s/_/ /g;
		    return $tmp;
                }
	    }
        }
    }
    return undef;
}

sub get_sex_row {
    my ($self, $row) = @_;
    my %sex = ('M' => 'Male', 
	       'F' => 'Female', 
	       'U' => 'Unknown', 
	       'H' => 'Hermaphrodite', 
	       'M+H' => 'mixed Male and Hermaphrodite population',
	       'F+H' => 'mixed Female and Hermaphrodite population');
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[$row];
	for my $datum (@{$ap->get_input_data()}) {
	    for my $attr (@{$datum->get_attributes()}) {
		my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
		if (lc($aheading) =~ /^\s*sex\s*$/) {
		    return $sex{uri_unescape($avalue)};
		}
	    }
	}
    }
    return undef;
}

sub get_antibody_row { #keep it as a datum object
    my ($self, $row) = @_;
    my $denorm_slots = $denorm_slots{ident $self} ;
    my $ip = $ip_slot{ident $self};
    my $ip_ap = $denorm_slots->[$ip]->[$row];
    my $antibodies;
    eval { $antibodies = _get_datum_by_info($ip_ap, 'input', 'name', 'antibody') } ;
    unless ($@) {
	if (defined($antibodies)) {
	    return $antibodies->[0] if $antibodies->[0]->get_value();
	}
    }
    return undef;
}

sub is_antibody {
    my $ab = shift;
    my $antibody = $ab->get_value();
    return -1 unless $antibody;
    $antibody =~ /[Aa][Bb]:([\w ]*?):/;
    $antibody = $1;
    $antibody =~ s/ +/ /g;
    $antibody =~ s/ /_/g;
    my @special_antibodies = ('No Antibody Control', 'No_Antibody_Control', 'AB46540_NIgG');
    my $is_control = 0;
    for my $control (@special_antibodies) {
	$is_control = 1 and last if $antibody eq $control;
    }
    return 0 if $is_control;
    return 1;
}

sub get_data {
    my ($self, $types) = @_;
    my @files = ();
    my @nr = ();
    for my $col (0..$num_of_cols{ident $self}) {
        for my $ap (@{$denorm_slots{ident $self}->[$col]}) {
            for my $datum (@{$ap->get_output_data()}) {
                my ($value, $type) = ($datum->get_value(), $datum->get_type());
		print $value, " ", $type->get_name(), "\n" if $value ne '';
                push @files, $value and push @nr, $value if $value ne '' && scalar(grep {$type->get_name() eq $_} @$types) && !scalar(grep {$value eq $_} @nr);
            }
        }
    }
    return @files;
}

sub get_raw_data {
    my $self = shift;
    my @types = ('nimblegen_microarray_data_file (pair)', 
		 'CEL', 
		 'agilent_raw_microarray_data_file', 
		 'raw_microarray_data_file',
		 'fastq',
		 'sff',
		 'qseq',
		 'GEO_record',
		 'ShortReadArchive_project_ID (SRA)',
		 'TraceArchive_record');
    return $self->get_data(\@types);
}

sub get_intermediate_data {
    my $self = shift;
    my @types =  ('WIG', 'BED', 'Sequence_Alignment/Map (SAM)', 'Signal_Graph_File', 'GEO_record');
    return $self->get_data(\@types);    
}

sub get_interprete_data {
    my $self = shift;
    my @types =  ('GFF3', 'GFF');
    return $self->get_data(\@types);       
}

sub get_other_factors {
    my $self = shift;
    my $f = $factors{ident $self};
    my %of;
    my @exclude_types = ('strain', 'strain_or_line', 'cell line', '[developmental_stage', 'tissue', 'organism_part', 'sex', 'antibody', 'gene');
    for my $rank (keys %$f) {
        my $type = $f->{$rank}->[1];
	unless ( scalar grep {/$type/i} @exclude_types ) {
            my $factor_name = $f->{$rank}->[0];
            my $factor_value = $self->_get_value_by_info(0, 'name', $f->{$rank}->[0]);
	    $of{$factor_name} = $factor_value;
	}
    }
    return %of;
}

################################################################################################
# the following are helper functions for extracting information from denorm_slots, which is    #
# a representation of regenerated SDRF from chado database.                                    #
################################################################################################
sub get_slotnum_by_protocol_property {
    my ($self, $isattr, $field, $fieldtext, $value) = @_;
    my @slots = ();
    my $found = 0;
    for (my $i=0; $i<scalar(@{$denorm_slots{ident $self}}); $i++) {
        for my $ap (@{$denorm_slots{ident $self}->[$i]}) {
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

sub get_slotnum_by_datum_property { 
    my ($self, $direction, $isattr, $field, $fieldtext, $value) = @_;
    my $experiment = $experiment{ident $self};
    my @slots = ();
    my $found = 0;
    for (my $i=0; $i<scalar(@{$denorm_slots{ident $self}}); $i++) {
        for my $applied_protocol (@{$denorm_slots{ident $self}->[$i]}) {
            last if $found;
	    my $func = 'get_' . $direction . '_data';
	    for my $datum (@{$applied_protocol->$func()}) {
		if ($isattr) {
		    for my $attr (@{$datum->get_attributes()}) {
                        if ($field eq 'type') {
                            if (_get_attr_value($attr, $field, $fieldtext) eq $value ) {
                                push @slots, $i;
                                $found = 1 and last;
                            }
                        } else {
                            if (_get_attr_value($attr, $field, $fieldtext) =~ /$value/i) { # no regex escape character allowed!!!!
                                push @slots, $i;
                                $found = 1 and last;
                            }
                        }
                    } 
		} else {
                    if ($field eq 'type') {
                        if (_get_datum_info($datum, $field) eq $value ) {
                            push @slots, $i;
                            $found = 1 and last;
                        }
                    } else {
                        if (_get_datum_info($datum, $field) =~ /$value/i) { # no regex escape character allowed!!!
                            push @slots, $i;
                            $found = 1 and last;
                        }
                    }
		}		
	    }
        }
        $found = 0;
    }
    return @slots;
}

#called by get_slotnum_by_protocol_property
sub _get_protocol_info {
    my ($protocol, $field) = @_;
    my $func = "get_$field";
    return $protocol->$func();
}

#called by get_slotnum_by_datum_property
sub _get_datum_info {
    my ($datum, $field) = @_;
    return $datum->get_name() if $field eq 'name';
    return $datum->get_heading() if $field eq 'heading';
    return $datum->get_type()->get_name() if $field eq 'type';
    return $datum->get_termsource()->get_db()->get_name() . ":" . $datum->get_termsource()->get_accession() if $field eq 'dbxref';
}

#called by get_slotnum_by_protocol_property, get_slotnum_by_datum_property
sub _get_attr_value {
    my ($attr, $field, $fieldtext) = @_;
    return $attr->get_value() if (($field eq 'name') && ($attr->get_name() =~ /$fieldtext/i));
    return $attr->get_value() if (($field eq 'heading') && ($attr->get_heading() =~ /$fieldtext/i));
    return undef;
}

#called by get_antibody_row
sub _get_datum_by_info { 
    my ($ap, $direction, $field, $fieldtext) = @_;
    my @data = ();
    my $f = "get_" . $direction . "_data";
    for my $datum (@{$ap->$f}) {
	my $of = "get_" . $field;
	push @data, $datum if $datum->$of =~ /$fieldtext/i;
    }
    croak("can not find data that has fieldtext like $fieldtext in field $field in chado.data table") unless (scalar @data);
    return \@data;
}

#called by get_other_factors, set_tgt_gene
sub _get_value_by_info {
    my ($self, $row, $field, $fieldtext) = @_;
    for (my $i=0; $i<$num_of_cols{ident $self}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $direction (('input', 'output')) {
            my $func = "get_" . $direction . "_data";
            for my $datum (@{$ap->$func()}) {
                my ($name, $heading, $value) = ($datum->get_name(), $datum->get_heading(), $datum->get_value());
                if ($field eq 'name') {
                    if ($name =~ /$fieldtext/) {
                        my $v = $value;
                        for my $attr (@{$datum->get_attributes()}) {
                            my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                            $v .= " $avalue" if lc($aheading) eq 'unit';
                        }
                        return $v;
                    }
                }
                if ($field eq 'heading') {
                    if ($heading =~ /$fieldtext/) {
                        my $v =$value;
                        for my $attr (@{$datum->get_attributes()}) {
                            my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                            $v .= " $avalue" if lc($aheading) eq 'unit';
                        }
                        return $v;
                    }
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

################################################################################################
# end of helper functions for extracting information from denorm_slots.                        # 
################################################################################################


1;
