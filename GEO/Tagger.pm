package GEO::Tagger;

use strict;
use Carp;
use Class::Std;
use Data::Dumper;
use File::Basename;
use URI::Escape;
use HTML::Entities;
use ModENCODE::Parser::LWChado;
use constant Filename_separator => ';';
use constant Filename_separator_replacement => ' ';
use constant Tag_value_separator => '_';
use constant Tag_value_separator_replacement => '-';

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
my %label_slot             :ATTR( :get<label_slot>             :default<undef>);
my %raw_slot               :ATTR( :get<raw_slot>               :default<undef>);
my %norm_slot              :ATTR( :get<norm_slot>              :default<undef>);
my %platform               :ATTR( :get<platform>               :default<undef>);
my %sample_name_slot       :ATTR( :get<sample_name_slot>       :default<undef>);
my %source_name_slot       :ATTR( :get<source_name_slot>       :default<undef>);
my %extract_name_slot      :ATTR( :get<extract_name_slot>   :default<undef>);
my %hybridization_name_slot :ATTR( :get<hybridization_name_slot>   :default<undef>);
my %replicate_group_slot   :ATTR( :get<replicate_group_slot>    :default<undef>);
my %last_extraction_slot   :ATTR( :get<last_extraction_slot>   :deafult<undef>);
my %strain                 :ATTR( :get<strain>                 :default<undef>);
my %cellline               :ATTR( :get<cellline>               :default<undef>);
my %devstage               :ATTR( :get<devstage>               :default<undef>);
my %tissue                 :ATTR( :get<tissue>                 :default<undef>);
my %sex                    :ATTR( :get<sex>                    :default<undef>);
my %antibody               :ATTR( :get<antibody>               :default<undef>);
my %groups                 :ATTR( :get<groups>                 :default<undef>);
#my %dup                    :ATTR( :get<dup>                    :default<undef>);
my %tgt_gene               :ATTR( :get<tgt_gene>               :default<undef>);
my %level1                 :ATTR( :get<level1>                 :default<undef>);
my %level2                 :ATTR( :get<level2>                 :default<undef>);
my %level3                 :ATTR( :get<level3>                 :default<undef>);

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

    my $aff = $self->affiliate_submission();
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
        
#    for my $parameter (qw[num_of_rows num_of_cols title description organism project lab factors data_type assay_type hyb_slot seq_slot ip_slot label_slot raw_slot norm_slot platform sample_name_slot source_name_slot extract_name_slot hybridization_name_slot replicate_group_slot last_extraction_slot strain cellline devstage tissue sex antibody tgt_gene level1 level2 level3]) {
    for my $parameter (qw[num_of_rows num_of_cols title description organism project lab factors data_type assay_type hyb_slot seq_slot ip_slot label_slot raw_slot norm_slot platform sample_name_slot source_name_slot extract_name_slot hybridization_name_slot replicate_group_slot last_extraction_slot groups strain cellline devstage tissue sex antibody tgt_gene level1 level2 level3]) {
        my $set_func = "set_" . $parameter;
	my $get_func = "get_" . $parameter;
        print "try to find $parameter ...";
        $self->$set_func();
	my $t = $self->$get_func();
	if ( defined($t) ) {
	    if ($parameter eq 'antibody') {
		print antibody_to_string($t);
	    } elsif ($parameter eq 'factors') {
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

sub set_label_slot {
    my $self = shift;
    my $slot = $self->get_slotnum_label();
    $label_slot{ident $self} = $slot if defined($slot);
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

sub set_platform {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
	my $p = $self->get_platform_row($row);
	$platform{ident $self} = $p and last if defined($p);
    }
}

sub set_strain {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
	my $s = $self->get_strain_row($row);
	$strain{ident $self} = $s and last if defined($s);
    }
}

sub strain {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
        my $s = $self->get_strain_row($row, 1);
	return $s and last if defined($s);
    }
    return undef;
}

sub set_cellline {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
        my $c = $self->get_cellline_row($row);
	$cellline{ident $self} = $c and last if defined($c);
    }
}

sub cellline {
    my $self = shift;
    for my $row ((0..$num_of_rows{ident $self}-1)) {
        my $c = $self->get_cellline_row($row, 1);
	return $c and last if defined($c);
    }
    return undef;
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
    my $real_ab = 0;
    my $probable_ab = undef;
    if ($ip_slot{ident $self}) {
	for my $row (0..$num_of_rows{ident $self}-1) {	    
            my $ab = $self->get_antibody_row($row);
	    if ($ab) {
		my $is_ab = is_antibody($ab);
		if ($is_ab == 1) {
		    $antibody{ident $self} = $ab;
		    $real_ab = 1;
		    last;
		}
		if ($is_ab == 0) {
		    $probable_ab = $ab;
		}
	    }
        }
    }
    $antibody{ident $self} = $probable_ab if $real_ab == 0 && defined($probable_ab);
}

sub set_groups {
    my $self = shift;
    my $denorm_slots = $denorm_slots{ident $self};
    my ($nr_grp, $all_grp);
    my ($last_extraction_slot, $method) = @{$self->group_by_this_ap_slot()};
    if ( $method eq 'protocol' ) {
	($nr_grp, $all_grp) = $self->group_applied_protocols($denorm_slots->[$last_extraction_slot], 1);
    } elsif ($method eq 'replicate[\s_]*group') {
	eval { $all_grp = $self->group_applied_protocols_by_attr($denorm_slots->[$last_extraction_slot], 'name', $method) };
	$all_grp = $self->group_applied_protocols_by_protocol_attr($denorm_slots->[$last_extraction_slot], 'name', $method) unless defined($all_grp);
    } elsif  ($method eq 'Source\s*Name') {
	$all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'input', 'heading', $method);
    } elsif ($method eq '[Sample|Hybridization]\s*Name'){
	if ($last_extraction_slot == 0) {
	    $all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'input', 'heading', $method);
	} else {
	    $all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'output', 'heading', $method);
	}
    } elsif ($method eq 'Extract\s*Name') {
	$all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'output', 'heading', $method);
    } elsif ($method eq 'raw') {
	$all_grp = $self->group_applied_protocols($denorm_slots->[$last_extraction_slot], 1);
    }
    print Dumper($all_grp);
#    my $all_grp_by_seq_array;
#    my %all_grp_by_seq_array;
#    if ( defined ($self->get_seq_slot()) ) {
#	%all_grp_by_seq_array = map {$_ => 0} (0..$num_of_rows{ident $self}-1);
#	$all_grp_by_seq_array = \%all_grp_by_seq_array;
#    }
#    if ( defined( $self->get_hyb_slot() ) ) {
#	eval { %all_grp_by_seq_array = $self->group_applied_protocols_by_data($denorm_slots->[$self->get_hyb_slot()], 'input', 'name', '\s*array\s*')};
#	if ($@) {
#	    $all_grp_by_seq_array = $self->group_applied_protocols_by_data($denorm_slots->[$self->get_hyb_slot()], 'input', 'name', 'adf');
#	}
#    }	
#    my %combined_grp;
#    my %duplicate;
#    foreach my $row (sort {$a<=>$b} keys %$all_grp) {
#	my $extract_grp = $all_grp->{$row};
#	my $array_grp = $all_grp_by_seq_array->{$row};
#	if (exists $combined_grp{$extract_grp}{$array_grp}) {
#            my $this_extract_ap = $denorm_slots->[$last_extraction_slot]->[$row];
#            my $this_hyb_seq_ap;
#	    if (defined($self->get_hyb_slot())) {
#		$this_hyb_seq_ap = $denorm_slots->[$self->get_hyb_slot()]->[$row];
#	    } elsif (defined($self->get_seq_slot())) {
#		$this_hyb_seq_ap = $denorm_slots->[$self->get_seq_slot()]->[$row];
#	    }
#	    my $ignore = 0; #possible validator bug might cause repeats of rows in denormalized ap slots
#	    for my $that_row (@{$combined_grp{$extract_grp}{$array_grp}}) {
#                my $that_extract_ap = $denorm_slots->[$last_extraction_slot]->[$that_row];
#                my $that_hyb_seq_ap;
#		if (defined($self->get_hyb_slot())) {
#		    $that_hyb_seq_ap = $denorm_slots->[$self->get_hyb_slot()]->[$that_row];
#		} elsif (defined($self->get_seq_slot())) {
#		    $that_hyb_seq_ap = $denorm_slots->[$self->get_seq_slot()]->[$that_row];
#		}
#                $ignore = 1 and $duplicate{$row} = $that_row and print "ignored $row!\n" and last if ($this_extract_ap->equals_except_anonymous($that_extract_ap) && $this_hyb_seq_ap->equals_except_anonymous($that_hyb_seq_ap));
#	    }
#	    push @{$combined_grp{$extract_grp}{$array_grp}}, $row unless $ignore;
#	} else {
#	    $combined_grp{$extract_grp}{$array_grp} = [$row]; 
#	}
#    }
#    $groups{ident $self} = \%combined_grp;    
#    $dup{ident $self} = \%duplicate;
    $groups{ident $self} = $all_grp;
}

sub set_tgt_gene {
    my $self = shift;
    my $found = 0;
    #from IDF Experimental Factors
    my $factors = $factors{ident $self};
    my $strain = $self->strain();
    my $cellline = $self->cellline();
    my $ab = $self->get_antibody();
    my $header;
    for my $rank (keys %$factors) {
        my $type = $factors->{$rank}->[1];
        $header = $factors->{$rank}->[0] and last if $type eq 'gene';
    }
    if ($header) {
        my $tgt_gene = $self->_get_value_by_info(0, 'name', $header);
        $tgt_gene{ident $self} = $tgt_gene;
	$found = 1;
    }
    unless ($found) {
	#from Strain dbfield info.
	if ( defined($strain) ) {
	    my @attr = grep {lc($_->get_heading()) eq 'target id'} @{$strain->get_attributes()};
	    if (scalar @attr) {
		my $x = $attr[0]->get_value();	
		$tgt_gene{ident $self} = $x;
		$found = 1;
	    }
	}	
    }
    unless ($found) {
	#from Cell line dbfield info
	if ( defined($cellline) ) {
	    my @attr = grep {lc($_->get_heading()) eq 'target id'} @{$cellline->get_attributes()};
	    if (scalar @attr) {
		my $x = $attr[0]->get_value();	
		$tgt_gene{ident $self} = $x;
		$found = 1;
	    }
	}
    }
    unless ($found) {
	#from antibody dbfield info
	if ( defined($ab) ) {
	    my @attr = grep {lc($_->get_heading()) eq 'target name'} @{$ab->get_attributes()};
	    if (scalar @attr) {
		my $x = $attr[0]->get_value();
		$tgt_gene{ident $self} = $x;
		$tgt_gene{ident $self} = 'No Antibody Control' if $x eq 'Not Appicable';
		$found = 1;
	    }
	}
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
        #croak("you confused me with more than 1 sequencing protocols.");
	return $aps[-1];
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

sub get_slotnum_label {
    my $self = shift;
    my $type = "label";
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    return $aps[-1] if scalar(@aps);
    return undef;
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
    my ($self, $row, $rpt_obj) = @_;
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $datum (@{$ap->get_input_data()}) {
            my ($name, $heading, $value, $type) = ($datum->get_name(), $datum->get_heading(), $datum->get_value(), $datum->get_type());
            if (lc($name) =~ /^\s*strain\s*$/ || $type->get_name() eq 'strain_or_line') {
		return $datum if $rpt_obj;
                if ($value =~ /[Fly|Worm]?[Ss]train:(.*)&/) {
		    #return $value;
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
		    #return $value;
                    $value =~ /(.*)&/ ;
                    my $tmp = uri_unescape($1);
                    $tmp =~ s/_/ /g;
                    return $tmp;
                }
            }
            for my $attr (@{$datum->get_attributes()}) {
                my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                if (lc($aname) =~ /^\s*strain\s*$/ || lc($aheading) =~ /^\s*strain\s*$/) {
		    return $datum if $rpt_obj;
		    #return $avalue;
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
    my ($self, $row, $rpt_obj) = @_;
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $datum (@{$ap->get_input_data()}) {
            my ($name, $heading, $value, $type) = ($datum->get_name(), $datum->get_heading(), $datum->get_value(), $datum->get_type());
            if (lc($name) =~ /^\s*cell[_\s]*line\s*$/ || $type->get_name() eq 'cell_line') {
		return $datum if $rpt_obj;
		#return $value;
		if ( $value =~ /[Cc]ell[Ll]ine:(.*?):/ ) {
                    my $tmp = uri_unescape($1);
                    $tmp =~ s/_/ /g;
                    return $tmp;
                }
            }
            for my $attr (@{$datum->get_attributes()}) {
                my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                if (lc($aname) =~ /^cell[_\s]*line/ || lc($aheading) =~ /^cell[_\s]*line/) {
		    return $datum if $rpt_obj;
		    #return $avalue;
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
		    #return uri_unescape($value);
                }
            }
            for my $attr (@{$datum->get_attributes()}) {
                my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                if (lc($aname) =~ /dev.*stage/ || lc($aheading) =~ /dev.*stage/) {
                    if ( $avalue =~ /[Dd]ev[Ss]tage(Worm|Fly)?:(.*?):/ ) {
                        my $tmp = uri_unescape($2);
                        $tmp =~ s/_/ /g;
                        return $tmp;
			#return uri_unescape($avalue);
                   }
		    else {
			$avalue =~ s/_/ /g;
			return uri_unescape($avalue);
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
		#return $value;
                if ( $value =~ /[Tt]issue:(.*?):/ ) {
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
    #print "antibody is $antibody\n";
    my @special_antibodies = ('No_Antibody_Control', 'AB46540_NIgG');
    return 0 if scalar grep {$antibody eq $_} @special_antibodies;
    return 1;
}

sub antibody_to_string {
    my $ab = shift;
    return $ab->get_value();
    #my @t = grep {$_->get_heading() eq 'target name'} @{$ab->get_attributes()};
    #return $t[0]->get_value();
}

sub get_platform_row {
    my ($self, $row) = @_;
    my $hyb_slot = $self->get_hyb_slot();
    my $seq_slot = $self->get_seq_slot();
    if ( defined($hyb_slot) ) {
	return $self->get_array_row($row);
    }
    if ( defined($seq_slot) ) {
	return $self->get_seqmachine_row($row);
    }
}

sub get_array_row {
    my ($self, $row, $return_object) = @_;
    my $hyb_ap = $denorm_slots{ident $self}->[$hyb_slot{ident $self}]->[$row];
    my ($array, $platform);
    for my $data (@{$hyb_ap->get_input_data()}) {
	if ($data->get_type()->get_name() eq 'ADF') {
	    $array = $data;
	    last;
	}
    }
    if ( defined($array) ) {
	for my $attr (@{$array->get_attributes()}) {
	    return $return_object ? $array : $attr->get_value() if $attr->get_heading() eq 'platform';
	}
    } else {
	croak("could not find array info for a hybridization experiment.");
    }
}

sub get_seqmachine_row {
    my ($self, $row, $return_object) = @_;
    my $seq_ap = $denorm_slots{ident $self}->[$seq_slot{ident $self}]->[$row];
    my $machine;
    eval {
        $machine = _get_datum_by_info($seq_ap, 'input', 'name', '\s*sequencing\s*platform\s*');
    };
    if ($@) {
	my $p = $seq_ap->get_protocol();
	#print "protocol name: ", $p->get_name(), "\n";
	#print "protocol description: ", $p->get_description(), "\n";
	#for my $data (@{$ap->get_input_data()}) {
	    
	#}
	return 'Illumina' if $p->get_name() =~ /illumina/i || $p->get_description =~ /illumina/i;
    } 
    else {
	return $machine->[0]->get_value();
    }
}

sub get_label_row {
    my ($self, $row) = @_;   
    my $denorm_slots = $denorm_slots{ident $self} ;
    my $label_slot = $label_slot{ident $self};
    my $label_ap = $denorm_slots->[$label_slot]->[$row];
    my $labels;
    eval { $labels = _get_datum_by_info($label_ap, 'input', 'name', '\s*label\s*') } ;
    return undef if ($@ && !defined($labels));
    return $labels->[0];
}

sub get_data {
    my ($self, $type_map) = @_;
    my $ip = $self->get_ip_slot();
    my $label_slot = $self->get_label_slot();
    my $project = $self->get_project();
    my $platform = $self->get_platform();
    my $all_grps = $self->get_groups();
    my @files = ();
    my @file_types = ();
    #my @file_rows = ();
    my @grps = ();
    my @anti = ();
    my @label = ();
    my @nr = ();
    my @types = keys %{$type_map};
    for my $row (0..$num_of_rows{ident $self}-1) {
	my $grp = $all_grps->{$row};
	my $ab = $self->get_antibody_row($row);
	for my $col (0..$num_of_cols{ident $self}-1) {
	    my $ap = $denorm_slots{ident $self}->[$col]->[$row];
            for my $datum (@{$ap->get_output_data()}) {
                my ($value, $type) = ($datum->get_value(), $datum->get_type());
		#print $value, " ", $type->get_name, "\n";
		if ( $value ne '' && (scalar(grep {$type->get_name() eq $_} @types) || scalar(grep {lc($type->get_name()) eq $_} @types)) && !scalar(grep {$value eq $_} @nr) ) {
		    push @file_types, $type_map->{$type->get_name()} || $type_map->{lc($type->get_name())}; 
		    push @files, $value;
		    #push @file_rows, $row;
		    push @grps, $grp;
		    push @nr, $value;
		    if (defined($ip)) {
			if (defined($ab)) {
			    if (is_antibody($ab)) {
				push @anti, 'ChIP';
			    } else {
				push @anti, 'input';
			    }
			} else {
			    push @anti, 'input';
			}
		    }
		    if (defined($label_slot)) {
			my $t = $self->get_label_row($row);
			if (defined($t)) {
			    push @label, $t->get_value();
			}
			else {
			    if ($project eq 'Kevin White' && lc($platform) eq 'agilent') {
				if (defined($ab) && is_antibody($ab)) {
				    push @label, 'cy3';
				} else {
				    push @label, 'cy5';
				}
			    }
			}
		    }
		}
            }
        }
    }
    return (\@files, \@file_types, \@grps, \@anti, \@label);
}

sub get_raw_data {
    my ($self, $rpt_ncbi_id) = @_;
    my %type_map = ('nimblegen_microarray_data_file (pair)' => 'raw-arrayfile_pair', 
		    'CEL' => 'raw-arrayfile_CEL',
		    'agilent_raw_microarray_data_file' => 'raw-arrayfile-agilent_txt', 
		    'raw_microarray_data_file' => 'raw-arrayfile-agilent_txt',
		    'fastq' => 'raw-seqfile_fastq',
		    'sff' => 'raw-seqfile_sff',
		    'qseq'=> 'raw-seqfile_qseq',
		    'prb' => 'raw-seqfile_prb',
		    'seq' => 'raw-seqfile_seq');
    my %ncbi_id = ('GEO_record' => 'GEO_record',
		   'ShortReadArchive_project_ID (SRA)' => 'ShortReadArchive_record',
		   'TraceArchive_record' => 'TraceArchive_record');
    %type_map = (%type_map, %ncbi_id) if $rpt_ncbi_id;
    return $self->get_data(\%type_map);
}

sub get_intermediate_data {
    my ($self, $rpt_ncbi_id) = @_;
    my %type_map =  ('WIG' => $self->get_hyb_slot() ? 'normalized-arrayfile_wiggle' : 'coverage-graph_wiggle',
		     'BED' => $self->get_hyb_slot() ? 'normalized-arrayfile_bed' : 'coverage-graph_bed', 
		     'Sequence_Alignment/Map (SAM)' => 'alignment_sam', 
		     'Signal_Graph_File' => 'normalized-arrayfile_wiggle');
    my %ncbi_id = ('GEO_record' => 'GEO_record');
    %type_map = (%type_map, %ncbi_id) if $rpt_ncbi_id;
    return $self->get_data(\%type_map);    
}

sub get_interprete_data {
    my $self = shift;
    my %type_map =  ('GFF3' => $self->get_ip_slot() ? 'computed-peaks_gff3' : 'gene-model_gff3', 
		  'GFF' => $self->get_ip_slot() ? 'computed-peaks_gff3' : 'gene-model_gff3');
    return $self->get_data(\%type_map);       
}

sub get_other_factors {
    my $self = shift;
    my $f = $factors{ident $self};
    my %of;
    my @exclude_types = ('strain', 'strain_or_line', 'cell line', 'cell_line', 'developmental_stage', 'tissue', 'organism_part', 'sex', 'antibody', 'gene');
    for my $rank (keys %$f) {
        my $type = $f->{$rank}->[1];
	unless ( scalar grep {/$type/i} @exclude_types ) {
            my $factor_type = $f->{$rank}->[1];
            my $factor_value = $self->_get_value_by_info(0, 'name', $f->{$rank}->[0]);
	    $factor_value =~ s/&\S*//g;
	    $of{$factor_type} = uri_unescape($factor_value);
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

sub group_by_this_ap_slot {
    my $self = shift;
    my $hyb_col = $self->get_hyb_slot();
    my $seq_col = $self->get_seq_slot();
    my $project = $self->get_project();
    my $lab = $self->get_lab();
    my $replicate_group_col = $replicate_group_slot{ident $self};
    my $source_name_col = $source_name_slot{ident $self};
    my $sample_name_col = $sample_name_slot{ident $self};
    my $extract_name_col = $extract_name_slot{ident $self};
    my $hyb_name_col = $hybridization_name_slot{ident $self};
    my $last_extract_col = $last_extraction_slot{ident $self};
    print $project, "\n";
    #if (defined($replicate_group_col)) {
	#print "group by replicate group info.\n" and return [$replicate_group_col, 'replicate[\s_]*group'];
    #}
    if ($project eq 'Susan Celniker' || $project eq 'Eric Lai' || $project eq 'Fabio Piano' || $project eq 'Robert Waterston' || $lab eq 'Oliver') {
	print "group by last extraction protocol.\n" and return [$last_extract_col, 'protocol'];
    } 
    if ($project eq 'Jason Lieb') {
	if (defined($replicate_group_col)) {
	    print "group by replicate group info.\n" and return [$replicate_group_col, 'replicate[\s_]*group'];
	} else {
	    print "group by sample name.\n" and return [$sample_name_col, 'Sample\s*Name'];
	}
    }
    if ($project eq 'Gary Karpen' || $project eq 'Michael Snyder') {
	print "group by sample name.\n" and return [$sample_name_col, 'Sample\s*Name'];
    }
    if ($project eq 'David MacAlpine') {
	if (defined($replicate_group_col)) {                                                                                                                                    
            print "group by replicate group info.\n" and return [$replicate_group_col, 'replicate[\s_]*group'];                                                                 
        } 
	print "group by sample name.\n" and return [$sample_name_col, 'Sample\s*Name'];
    }
    if ($project eq 'Steven Henikoff') {
	if (defined($replicate_group_col)) {
            print "group by replicate group info.\n" and return [$replicate_group_col, 'replicate[\s_]*group'];
	}
	print "group by extract name.\n" and return [$extract_name_col, 'Extract\s*Name'];
    }
    if ($project eq 'Kevin White') {
	if (defined($extract_name_col)) {
	    print "group by extract name.\n" and return [$extract_name_col, 'Extract\s*Name'];
	}
	print "group by Sample/Hyb name.\n" and return [$sample_name_col, '[Sample|Hybridization]\s*Name'] if defined($sample_name_col);
	print "group by Hyb name.\n" and return [$hyb_name_col, 'Hybridization\s*Name'] if defined($hyb_name_col);
	print "group by last extraction protocol.\n" and return [$last_extract_col, 'protocol'];
    }
}

sub set_replicate_group_slot {
    my $self = shift;
    my $text = 'replicate[\s_]*group';
    my $slot;
    $slot = $self->get_ap_slot_by_attr_info('input', 'name', $text);
    $replicate_group_slot{ident $self} = $slot if defined($slot);
    $replicate_group_slot{ident $self} = $self->get_ap_slot_by_protocol_attr('name', $text) unless defined($slot);
}

sub get_ap_slot_by_protocol_attr {
    my ($self, $field, $fieldtext) = @_;
    for (my $i=0; $i<scalar(@{$denorm_slots{ident $self}}); $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[0];
	for my $attr (@{$ap->get_protocol->get_attributes()}) {
	    my $func = "get_$field";
	    return $i if $attr->$func =~ /$fieldtext/i ;
	}
    }
    return undef;
}

sub set_source_name_slot {
    my $self = shift;
    my @aps = $self->get_slotnum_by_datum_property('input', 0, 'heading', undef, 'Source\s*Name');
    $source_name_slot{ident $self} = $aps[0] if scalar(@aps);
}

sub set_sample_name_slot {
    my $self = shift;
    my $text = 'Sample\s*Name';
    my $slot = $self->get_ap_slot_by_datum_info('output', 'heading', $text);
    if ( defined($slot) and $slot > 0 ) {
	$sample_name_slot{ident $self} = $slot;
    } else {
	my $text = '[Sample|Hybridization]\s*Name';
	my $islot = $self->get_ap_slot_by_datum_info('input', 'heading', $text);
	if ( defined($islot) and $islot == 0 ) {
	    $sample_name_slot{ident $self} = $islot;
	}
    }
}

sub get_ap_slot_by_datum_info {
    my ($self, $direction, $field, $fieldtext) = @_;
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[0];
	eval { _get_datum_by_info($ap, $direction, $field, $fieldtext) };
 	return $i unless $@;
	next if $@;
    }
    return undef;
}

sub get_ap_slot_by_attr_info {
    my ($self, $direction, $field, $fieldtext) = @_;
    for (my $i=0; $i<scalar @{$denorm_slots{ident $self}}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[0];
        if ( $direction eq 'input' ) {
            for my $datum (@{$ap->get_input_data()}) {
                eval { _get_attr_by_info($datum, $field, $fieldtext) };
                return $i unless $@;
                next if $@;
            }
        } else {
            for my $datum (@{$ap->get_output_data()}) {
                eval { _get_attr_by_info($datum, $field, $fieldtext) };
                return $i unless $@;
                next if $@;
            }
        }
    }
    return undef;
}

sub set_extract_name_slot {
    my $self = shift;
    my @aps = $self->get_slotnum_by_datum_property('output', 0, 'heading', undef, 'Extract\s*Name');
    $extract_name_slot{ident $self} = $aps[0] if scalar(@aps);
}

sub set_hybridization_name_slot {
    my $self = shift;
    my @aps = $self->get_slotnum_by_datum_property('input', 0, 'heading', undef, 'Hybridization\s*Name');
    $hybridization_name_slot{ident $self} = $aps[0] if scalar(@aps);
}

sub group_applied_protocols {
    my ($self, $ap_slot, $rtn) = @_; #these applied protocols are simple obj from AppliedProtocol.pm
    return _group($ap_slot, $rtn);
}

sub group_applied_protocols_by_data {
    my ($self, $ap_slot, $direction, $field, $fieldtext, $rtn) = @_;
    my $data = _get_data_by_info($ap_slot, $direction, $field, $fieldtext);
    return _group($data, $rtn);
}

sub group_applied_protocols_by_protocol_attr {
    my ($self, $ap_slot, $field, $fieldtext, $rtn) = @_;
    my @attrs;
    my $get_func = "get_$field";
    for my $ap (@$ap_slot) {
	for my $attr (@{$ap->get_protocol->get_attributes}) {
	    push @attrs, $attr if $attr->$get_func() =~ /$fieldtext/;
	}
    }
    croak("can not get applied protocol that has PROTOCOL attribute with field $field equals to fieldtext $fieldtext") unless scalar @attrs;
    return _group(\@attrs, $rtn);
}

sub group_applied_protocols_by_attr {
    my ($self, $ap_slot, $field, $fieldtext, $rtn) = @_;
    my @attrs;
    my $get_func = "get_$field";
    for my $ap (@$ap_slot) {
        for my $datum (@{$ap->get_input_data}) {
	    for my $attr (@{$datum->get_attributes()}) {
		push @attrs, $attr if $attr->$get_func() =~ /$fieldtext/;
            }
        }
	for my $datum (@{$ap->get_output_data}) {
            for my $attr (@{$datum->get_attributes()}) {
                push @attrs, $attr if $attr->$get_func() =~ /$fieldtext/;
            }
        }
    }
    croak("can not get applied protocol that has attribute with field $field equals to fieldtext $fieldtext") unless scalar @attrs;
    return _group(\@attrs, $rtn);
}

sub _group {
    my ($alist, $rtn) = @_;
    my $x = $alist->[0];

    my @nr = (0);
    my %grp = ();
    for (my $i=0; $i<scalar(@$alist); $i++) {
	my $o = $alist->[$i];
	my $found = 0;
	for (my $j=0; $j<scalar(@nr); $j++) {
	    my $nro = $alist->[$nr[$j]];
	    if (ref($o)) {
		if ($o->equals($nro)) {
		    $grp{$i} = $j;
		    $found = 1;
		    last;
		}
	    } else {
		if ($o == $nro) {
		    $grp{$i} = $j;
		    $found = 1;
		    last;		    
		}
	    }
	}
	if (! $found) {
	    push @nr, $i;
	    $grp{$i} = $#nr; 
	}		
    }
    return (\@nr, \%grp) if $rtn;
    return \%grp;    
}

sub set_last_extraction_slot {
    my $self = shift;
    $last_extraction_slot{ident $self} = $self->get_slotnum_extract('group');
}

sub get_slotnum_extract {
    my ($self, $option) = @_;
    my $type = "extract";
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    if (scalar(@aps) > 1) {
	print "ok1\n";
        if ($option eq 'group') { #report this one to group rows in SDRF to GEO samples=extraction+array
            #return $self->check_complexity(\@aps);
	    return $aps[-1];
        } elsif ($option eq 'protocol') { #report this one to write out all extraction protocols and in between
            if (defined($extract_name_slot{ident $self}) and $extract_name_slot{ident $self} != -1) {
                return $aps[0] > $extract_name_slot{ident $self} ? $extract_name_slot{ident $self} : $aps[0] ;
            } else {
                return $aps[0];
            }
        }
    } elsif (scalar(@aps) == 0) { #oops, we have no protocol with protocol type equals regex to 'extract'
        my $type = "purify";
        my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
        if (scalar(@aps) > 1) {
            if ($option eq 'group') {
                return $self->check_complexity(\@aps);
            } elsif ($option eq 'protocol') {#tricky SDRF error could cause extract name ap slot < real extraction protocol defined by protocol type
                return $aps[0];
            }
        }
        elsif (scalar(@aps) == 0) { #oops, we have no protocol with protocol type equals regex to 'purify'
            my $type = 'biosample_preparation_protocol';
            my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
            if (scalar(@aps) > 1) {
                if ($option eq 'group') {
                    return $self->check_complexity(\@aps);
                } elsif ($option eq 'protocol') {
                    return $aps[0];
                }
            } elsif (scalar(@aps) == 0) {#oops, we have no protocol with protocol type equals regex to 'biosample_preparation_protocol'
                my $type = 'organism_purification_protocol';
                my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
                if (scalar(@aps) > 1) {
                    if ($option eq 'group') {
                        return $self->check_complexity(\@aps);
                    } elsif ($option eq 'protocol') {
                        return $aps[0];
                    }
                }
                elsif (scalar(@aps) == 1) {
                    return $aps[0];
                }
                else {
                    my @itypes = ('whole_organism', 'multi-cellular organism', 'organism_part', 'DNA', 'genomic_DNA'); #input type of a protocol
                    my @iaps;
                    for my $type (@itypes) {
                        my @xaps = $self->get_slotnum_by_datum_property('input', 0, 'type', undef, $type);
                        @iaps = merge_two_lists(\@iaps, \@xaps);
                    }
                    my @otypes = ('DNA', 'genomic_DNA', 'chromatin', 'mRNA', '\s*RNA'); #output type of a protocol
                    my @oaps;
                    for my $type (@otypes) {
                        my @xaps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
                        @oaps = merge_two_lists(\@oaps, \@xaps);
                    }
                    my @aps = union_two_lists(\@iaps, \@oaps);
                    if (scalar(@aps) > 1) {
                        if ($option eq 'group') {
                            return $self->check_complexity(\@aps);
                        } elsif ($option eq 'protocol') {
                            return $aps[0];
                        }
                    } elsif (scalar(@aps) == 1) {
                        return $aps[0];
                    } else {
			# I paniced, obviously no protocol with type like extract.
			my @types = ('grow');
			for my $type (@types) {
			    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
			    if (scalar @aps >= 1) {
				return $aps[0];
			    }
			}
                        croak("Every experiment must have at least one extraction protocol. Maybe you omitted this protocol in SDRF?");
                    }
                }
            } else {#found 'biosample_preparation_protocol'
                return $aps[0];
            }
        } 
        else {#found 'purify'
            return $aps[0];
        }
    } else {#found 'extract'
        return $aps[0];
    }
}

sub check_complexity {
    my ($self, $slots) = @_;
    my $xap_slots = $normalized_slots{ident $self};
    my $slot = $slots->[0];
    my $num_norm_ap = scalar @{$xap_slots->[$slot]};
    for my $aslot (@$slots) {
        my $this_num_norm_ap = scalar @{$xap_slots->[$aslot]};
        if ( $this_num_norm_ap > $num_norm_ap) {
            $num_norm_ap = $this_num_norm_ap;
            $slot = $aslot;
        } elsif ($this_num_norm_ap == $num_norm_ap) {
            if ($aslot > $slot) {
                $num_norm_ap = $this_num_norm_ap;
                $slot = $aslot;
            }
        }
    }
    return $slot;
}


sub merge_two_lists {#stupid one
    my ($a, $b) = @_;
    my @c;
    for my $y (@$b) {
        push @c, $y;
    }
    for my $x (@$a) {
        my $in = 0;
        for my $z (@c) {
            $in = 1 and last if $x == $z;
        }
        push @c, $x unless $in;
    }
    sort @c;
    return @c;
}

sub union_two_lists {
    my ($a, $b) = @_;
    my @c;
    for my $x (@$a) {
        for my $y (@$b) {
            push @c, $x if $x == $y;
        }
    }
    sort @c;
    return @c;
}

sub _get_attr_by_info {
    my ($obj, $field, $fieldtext) = @_;
    my @attributes = ();
    my $func = "get_$field";
    for my $attr (@{$obj->get_attributes()}) {
        push @attributes, $attr if $attr->$func() =~ /$fieldtext/i;
    }
    croak("can not find attribute with field $field like $fieldtext.") unless (scalar @attributes);
    return \@attributes;
}

sub _get_data_by_info {
    my ($aps, $direction, $field, $fieldtext) = @_;
    my @data = ();
    for my $ap (@$aps) {
        push @data, @{_get_datum_by_info($ap, $direction, $field, $fieldtext)};
    }
    croak("can not find data with field $field and fieldtext $fieldtext") unless scalar @data;
    return \@data;
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

################################################################################################
# end of helper functions for extracting information from denorm_slots.                        # 
################################################################################################

sub set_level1 {
    my $self = shift;
    my $org = $self->get_organism();
    my $s;
    if ($org eq 'Caenorhabditis elegans') {
	#change to WS220;
	$s = 'Cele_WS220';
	#$s = 'Cele_WS190';    
    } elsif ($org eq 'Drosophila melanogaster') {
	#change to r5.32
	$s = 'Dmel_r5.32';
	#$s = 'Dmel_r5.4';    
    } elsif ($org =~ /Drosophila\s*pseudoobscura/) {
	$s = 'Dpse_r2.4';    
    } elsif ($org eq 'Drosophila mojavensis') { 
	$s = 'Dmoj_r1.3';
    }
    $level1{ident $self} = $s;
}

sub set_level2 {
    my $self = shift;
    my $at = $self->get_assay_type();
    my $dt = $self->get_data_type();
    my $project = $self->get_project();
    my $lab = $self->get_lab();
    my $desc = $self->get_description();
    my $gene = $self->get_tgt_gene();
    my @histone_variants = ('HTZ-1', 'HCP-3');
    my @dosage_compensation = ('DPY-27');
    my @histone_modification = ('H3K27Ac', 'H3K27me3', 'H3K9me2');
    my @non_tf_factor = ('nejire', 'RNA Polymerase II');
    my @mrna_groups = ('Susan Celniker', 'Kevin White', 'Robert Waterston', 'Steven Henikoff');
    my $l1 = $self->get_level1();
    if ( defined($at) && defined($dt) ) {
        $level2{ident $self} =  'mRNA' if $dt eq 'Gene Structure - mRNA';
	$level2{ident $self} = 'small-RNA' if $dt eq 'Gene Structure - ncRNA';
        $level2{ident $self} =  'mRNA' if $dt eq 'RNA expression profiling' and scalar grep {$project eq $_} @mrna_groups;
	$level2{ident $self} =  'mRNA' if $dt eq 'RNA expression profiling' and ($l1 eq 'Dpse_r2.4' || $l1 eq 'Dmoj_r1.3' || $lab eq 'Oliver');
        $level2{ident $self} =  'Transcriptional-Factor' if $dt eq 'TF binding sites';
	if ($dt eq 'Histone modification and replacement') {
	    if (scalar grep {$gene eq $_} @histone_variants) {
		$level2{ident $self} = 'Chromatin-Structure'; 
	    } elsif (scalar grep {$gene eq $_} @dosage_compensation) {
                $level2{ident $self} = 'Non-TF-Chromatin-binding-factor';
	    } else {
		$level2{ident $self} =  'Histone-Modification';
	    }
	}
        $level2{ident $self} =  'Non-TF-Chromatin-binding-factor' if $dt eq 'Other chromatin binding sites';
        $level2{ident $self} =  'DNA-Replication' if $dt eq 'Replication Factors' || $dt eq 'Replication Timing' || $dt eq 'Origins of Replication';
        $level2{ident $self} =  'Chromatin-Structure' if $dt eq 'Chromatin structure';
        $level2{ident $self} =  'small-RNA' if $dt eq 'RNA expression profiling' and $project eq 'Eric Lai' || $project eq 'Fabio Piano';
        $level2{ident $self} =  'Copy-Number-Variation' if $dt eq 'Copy Number Variation';
	$level2{ident $self} =  'small-RNA' if $dt eq 'RNA expression profiling' and $project eq 'Robert Waterston' and $desc =~ /mirna/i and $desc =~/small rna/i;
    }
    else {
	$level2{ident $self} = 'Copy-Number-Variation' if $desc =~ /comparative genomic hybridization/;
	if ( !defined($at) and !defined($dt) ) {
	    $level2{ident $self} = 'mRNA' if $project eq 'Robert Waterston';
	    $level2{ident $self} = 'mRNA' if $project eq 'Fabio Piano';
	    $level2{ident $self} = 'Histone-Modification' if $project eq 'Kevin White' and $self->get_hyb_slot() > 0 and defined($self->get_antibody()) and scalar grep {antibody_to_string($self->get_antibody()) eq $_} @histone_modification;
	    $level2{ident $self} = 'Non-TF-Chromatin-binding-factor' if $project eq 'Kevin White' and $self->get_hyb_slot() > 0 and defined($self->get_antibody()) and scalar grep {antibody_to_string($self->get_antibody()) eq $_} @non_tf_factor;
	}
    }

}

sub set_level3 {
    my $self = shift;
    my %map = ('Alignment' => 'RNA-seq',
               'CAGE' => 'CAGE',
               'cDNA sequencing' => 'cDNA-sequencing',
               'ChIP-chip' => 'ChIP-chip',
               'ChIP-seq' => 'ChIP-seq',
               'Computational annotation' => 'integrated-gene-model',
               'DNA-seq' => 'DNA-seq',
               'Mass spec' => 'Mass-spec',
               'RACE' => 'RACE',
               'RNA-seq' => 'RNA-seq',
               'RNA-seq, RNAi' => 'RNA-seq',
               'RTPCR' => 'RT-PCR',
               'tiling array: DNA' => 'DNA-tiling-array',
               'tiling array: RNA' => 'RNA-tiling-array',
	       'tiling array:RNA' => 'RNA-tiling-array',
        );
    my $at = $self->get_assay_type;
    my $l2 = $self->get_level2();
    my $project = $self->get_project();
    my $found = 0;
    if (defined($at)) {
        $found = 1 and $level3{ident $self} = $map{$at} if exists $map{$at};
	$level3{ident $self} = 'DNA-tiling-array' if $at eq 'ChIP-chip' and $project eq 'Steven Henikoff';
    } else {
	$level3{ident $self} = 'RACE' if $project eq 'Fabio Piano';
    }
    $level3{ident $self} = 'CGH' if $l2 eq 'Copy-Number-Variation' and defined($self->get_hyb_slot);
    $level3{ident $self} = 'CNV-seq' if $l2 eq 'Copy-Number-Variation' and defined($self->get_seq_slot);
    $level3{ident $self} = 'RNA-seq' if $l2 eq 'mRNA' and $self->get_seq_slot() > 0 and $found = 0;
    $level3{ident $self} = 'ChIP-chip' if $project eq 'Kevin White' and $self->get_hyb_slot() > 0 and defined($self->get_antibody()); 
}

sub lvl4_factor {
    my $self = shift;
    my $p = $self->get_project();
    my $desc = $self->get_description();
    my $dt = $self->get_data_type();
    my $l2 = $self->get_level2();
    my $l3 = $self->get_level3();
    my $gene = $self->get_tgt_gene();
    my @mol = ('mRNA', 'small-RNA');
    #my @tech = ('CAGE', 'cDNA-sequencing', 'Mass-spec', 'RACE', 'RNA-seq', 'RT-PCR', 'RNA-tiling-array', 'integrated-gene-model');
    if (scalar grep {$l2 eq $_} @mol) {
	return '5-prime-UTR' if $l3 eq 'CAGE';
	return 'small-RNA' if $l2 eq 'small-RNA';
	if ( $p eq 'Fabio Piano') {
	    return '3-prime-UTR';
	}
	return 'UTR' if ($l3 eq 'cDNA-sequencing' || $l3 eq 'RACE') && $p eq 'Susan Celniker';
	if ($l3 eq 'integrated-gene-model') {
	    if ( $desc =~ /splice[\s_-]*junction/ ) {
		return 'splice-junction';
	    } else {
		return 'transfrag';
	    }
	}
	if ($desc =~ /poly[ ]?a[+]?[-_\s]?rna/i) {#polyA
	    return 'PolyA-RNA';
	}
	return 'total-RNA';
    }
    else {
	if ( defined($gene) ) {
	    #$gene =~ s/_/-/g;
	    return $gene;
	} else {
	    return 'Nucleosome' if $p eq 'Steven Henikoff' || $p eq 'Jason Lieb';
	}
    }
    return 'Replication-Timing' if $dt eq 'Replication Timing';
    return 'Replication-Origin' if $dt eq 'Origins of Replication';
    return 'Replication-Copy-Number' if $l2 eq 'Copy-Number-Variation';
}

sub lvl4_condition {
    my $self = shift;
    my $strain = $self->get_strain(); $strain =~ s/_/-/g; 
    my $cellline = $self->get_cellline(); $cellline =~ s/_/-/g;
    my $devstage = $self->get_devstage(); $devstage =~ s/_/-/g;
    my $tissue = $self->get_tissue(); $tissue =~ s/_/-/g;
    my %of = $self->get_other_factors();
    my @exclude_factors = ('CellLine');
    my @c = ();
    if ( defined($strain) ) {
	#$strain =~ s/Filename_separator/Filename_separator_replacement/g;
	#$strain =~ s/Tag_value_separator/Tag_value_separator_replacement/g;
	$strain =~ s/;/ /g;
	$strain =~ s/_/-/g;
	push @c, 'Strain' . Tag_value_separator . $strain;
    }
    if ( defined($cellline) ) {
	#$cellline =~ s/Filename_separator/Filename_separator_replacement/g;
	#$cellline =~ s/Tag_value_separator/Tag_value_separator_replacement/g;
	$cellline =~ s/;/ /g;
	$cellline =~ s/_/-/g;
	push @c, 'Cell-Line' . Tag_value_separator . $cellline;
    }
    if ( defined($tissue) ) {
	#$tissue =~ s/Filename_separator/Filename_separator_replacement/g;
	#$tissue =~ s/Tag_value_separator/Tag_value_separator_replacement/g;
	$tissue =~ s/;/ /g;
	$tissue =~ s/_/-/g;
	push @c, 'Tissue' . Tag_value_separator . $tissue;
    }
    if ( defined($devstage) ) {
	#$devstage =~ s/Filename_separator/Filename_separator_replacement/g;
	#$devstage =~ s/Tag_value_separator/Tag_value_separator_replacement/g;
	$devstage =~ s/;/ /g;
	$devstage =~ s/_/-/g;
	push  @c, 'Developmental-Stage' . Tag_value_separator . $devstage;
    }
    #push @c, 'Strain_' . $strain if defined($strain);
    #push @c, 'Cell-Line_' . $cellline if defined($cellline);
    #push @c, 'Tissue_' . $tissue if defined($tissue);
    #push @c, 'Developmental-Stage_' . $devstage if defined($devstage);
    for my $k (sort keys %of) {
	next if scalar grep {$k eq $_} @exclude_factors;
	my $v = $of{$k};
	#$k =~ s/Filename_separator/Filename_separator_replacement/g;
	#$v =~ s/Filename_separator/Filename_separator_replacement/g;
	#$k =~ s/Tag_value_separator/Tag_value_separator_replacement/g;
	#$v =~ s/Tag_value_separator/Tag_value_separator_replacement/g;
	$k =~ s/;/ /g;
	$v =~ s/;/ /g;
	$k =~ s/_/-/g;
	$v =~ s/_/-/g;
	push @c, $k . Tag_value_separator . $v;
    }
    return join(Filename_separator, @c);
}

sub lvl4_algorithm {
    
}


sub well_format {
    my $s = shift;
    
}


sub _data_groups {
    my ($groups, $rows) = @_;
    my @data_groups;
    for my $row (@$rows) {
	push @data_groups, $groups->{$row};
    }
    return \@data_groups;
}


1;

#  LocalWords:  func
