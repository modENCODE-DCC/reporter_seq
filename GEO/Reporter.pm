package GEO::Reporter;

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
my %sampleFH               :ATTR( :name<sampleFH>              :default<undef>);
my %seriesFH               :ATTR( :name<seriesFH>              :default<undef>);
my %report_dir             :ATTR( :name<report_dir>            :default<undef>);
my %reader                 :ATTR( :name<reader>                :default<undef>);
my %experiment             :ATTR( :name<experiment>            :default<undef>);
my %long_protocol_text     :ATTR( :name<long_protocol_text>    :default<undef>);
my %split_seq_group        :ATTR( :name<split_seq_group>       :default<undef>);
my %normalized_slots       :ATTR( :get<normalized_slots>       :default<undef>);
my %denorm_slots           :ATTR( :get<denorm_slots>           :default<undef>);
my %num_of_rows            :ATTR( :get<num_of_rows>            :default<undef>);
my %ap_slots               :ATTR( :get<ap_slots>               :default<undef>);
my %sample_name_ap_slot    :ATTR( :get<sample_name_ap_slot>    :default<undef>);
my %source_name_ap_slot    :ATTR( :get<source_name_ap_slot>    :default<undef>);
my %extract_name_ap_slot   :ATTR( :get<extract_name_ap_slot>   :default<undef>);
my %replicate_group_ap_slot :ATTR( :get<replicate_group_ap_slot>    :default<undef>);
my %first_extraction_slot  :ATTR( :get<first_extraction_slot>  :deafult<undef>);
my %last_extraction_slot   :ATTR( :get<last_extraction_slot>   :deafult<undef>);
my %groups                 :ATTR( :get<groups>                 :default<undef>);
my %dup                    :ATTR( :get<dup>                    :default<undef>);
my %project                :ATTR( :get<project>                :default<undef>);
my %lab                    :ATTR( :get<lab>                    :default<undef>);
my %contributors           :ATTR( :get<contributors>           :default<undef>);
my %experiment_design      :ATTR( :get<experiment_design>      :default<undef>);
my %experiment_type        :ATTR( :get<experiment_type>        :default<undef>);
my %organism               :ATTR( :get<organism>               :default<undef>);
my %strain                 :ATTR( :get<strain>                 :default<undef>);
my %cellline               :ATTR( :get<cellline>               :default<undef>);
my %devstage               :ATTR( :get<devstage>               :default<undef>);
my %genotype               :ATTR( :get<genotype>               :default<undef>);
my %transgene              :ATTR( :get<transgene>              :default<undef>);
my %tissue                 :ATTR( :get<tissue>                 :default<undef>);
my %sex                    :ATTR( :get<sex>                    :default<undef>);
my %molecule_type          :ATTR( :get<molecule_type>          :default<undef>);
my %factors                :ATTR( :get<factors>                :default<undef>);
my %antibody               :ATTR( :get<antibody>               :default<undef>);
my %tgt_gene               :ATTR( :get<tgt_gene>               :default<undef>);
my %lib_strategy       :ATTR( :get<lib_strategy>       :default<undef>);
my %lib_selection      :ATTR( :get<lib_selection>      :default<undef>);
my %affiliate_submission   :ATTR( :get<affiliate_submission>   :default<undef>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    for my $parameter (qw[config unique_id sampleFH seriesFH report_dir reader experiment long_protocol_text split_seq_group]) {
	my $value = $args->{$parameter};
	defined $value || croak "can not find required parameter $parameter"; 
	my $set_func = "set_" . $parameter;
	$self->$set_func($value);
    }
    return $self;
}

sub set_all {
    my $self = shift;
    for my $parameter (qw[normalized_slots denorm_slots num_of_rows organism ap_slots source_name_ap_slot sample_name_ap_slot extract_name_ap_slot replicate_group_ap_slot first_extraction_slot last_extraction_slot groups project lab contributors factors experiment_design experiment_type strain cellline devstage genotype transgene tissue sex molecule_type antibody tgt_gene lib_strategy lib_selection]) {
	my $set_func = "set_" . $parameter;
	$self->$set_func();
    }
    for my $parameter (qw[normalized_slots denorm_slots num_of_rows organism ap_slots source_name_ap_slot sample_name_ap_slot extract_name_ap_slot replicate_group_ap_slot first_extraction_slot last_extraction_slot groups project lab contributors factors experiment_design experiment_type strain cellline devstage genotype transgene tissue sex molecule_type antibody tgt_gene lib_strategy lib_selection]) {
	my $get_func = "get_" . $parameter;
	print "find $parameter ";
	print $self->$get_func();
	print "done.\n";
    }
    if (defined($self->affiliate_submission)) {
	$self->set_affiliate_submission($self->affiliate_submission);
    }
}

sub set_affiliate_submission {
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
    my $reporter = new GEO::Reporter({
        'config' => $ini,
        'unique_id' => $id,
        'sampleFH' => $self->get_sampleFH,
        'seriesFH' => $self->get_seriesFH,
        'report_dir' => $self->get_report_dir,
        'reader' => $reader,
        'experiment' => $experiment,
	'long_protocol_text' => 0, 
	'split_seq_group' => 0
				     });
    for my $parameter (qw[normalized_slots denorm_slots num_of_rows organism ap_slots groups strain cellline devstage genotype transgene tissue sex molecule_type antibody tgt_gene]) {
        my $set_func = "set_" . $parameter;
        $reporter->$set_func();
    }
    $strain{ident $self} = $reporter->get_strain_row(0);
    $cellline{ident $self} = $reporter->get_cellline_row(0);
    $devstage{ident $self} = $reporter->get_devstage_row(0);
    $tissue{ident $self} = $reporter->get_tissue_row(0);
    $sex{ident $self} = $reporter->get_sex_row(0);
    $genotype{ident $self} = $reporter->get_genotype_row(0);
    $transgene{ident $self} = $reporter->get_transgene_row(0);
    $affiliate_submission{ident $self} = $reporter;
#    print "rescued strain ", $strain{ident $self};
#    print "rescued devstage ", $devstage{ident $self};
}


sub affiliate_submission {
    my $self = shift;
    for (my $i=0; $i<scalar @{$normalized_slots{ident $self}}; $i++) {
        my $ap = $normalized_slots{ident $self}->[$i]->[0];
	for my $datum (@{$ap->get_input_data()}) {
	    for my $attr (@{$datum->get_attributes()}) {
		if (lc($attr->get_type()->get_name()) eq 'reference' && lc($attr->get_type()->get_cv()->get_name()) eq 'modencode') {
		    my @info = split ':', $attr->get_value();
		    return $info[0];
		}
	    }
	}
	for my $datum (@{$ap->get_output_data()}) {
	    for my $attr (@{$datum->get_attributes()}) {
		if (lc($attr->get_type()->get_name()) eq 'reference' &&lc($attr->get_type()->get_cv()->get_name()) eq 'modencode') {
                    my @info = split ':', $attr->get_value();
                    return $info[0];
                }
            }
	}
    }
    return undef;
}

sub chado2series {
    my $self = shift;
    my $seriesFH = $seriesFH{ident $self};
    my $uniquename = $experiment{ident $self}->get_uniquename();
    my $internal_id = "modENCODE_submission_$unique_id{ident $self}";
    my $project_announcement = 'This submission comes from a modENCODE project of ' . $project{ident $self} . '. For full list of modENCODE projects, see http://www.genome.gov/26524648 ';
    my $data_use_policy = 'For data usage terms and conditions, please refer to http://www.genome.gov/27528022 and http://www.genome.gov/Pages/Research/ENCODE/ENCODEDataReleasePolicyFinal2008.pdf';
    #my $data_use_policy = 'DATA USE POLICY: This dataset was generated under the auspices of the modENCODE (http://www.modencode.org) project, which has a specific data release policy stating that the data may be used, but not published, until 9 months from the date of public release. If any data used for the analysis are derived from unpublished data prior to the expiration of the nine-month protected period, then the resource users should obtain the consent of respective resource producers prior to submission of a manuscript.';
    my ($investigation_title, $project_goal);
    my @pubmed;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
	my ($name, $value, $rank, $type) = ($property->get_name(), 
					    $property->get_value(), 
					    $property->get_rank(), 
					    $property->get_type());
	$investigation_title = $value if $name =~ /Investigation\s*Title/i ;
	$project_goal = "Project Goal: " . $value if $name =~ /Experiment\s*Description/i ;
	push @pubmed, $value if $name =~ /Pubmed_id/i;
    }

    print $seriesFH "^Series = ", $uniquename, "\n";
    print $seriesFH "!Series_title = " . substr($investigation_title, 0, 120), "\n";
    for my $summary (($internal_id, $project_announcement, $project_goal, $data_use_policy)) {
	print $seriesFH "!Series_summary = ", $summary, "\n";
    }
    if (scalar @pubmed) {
	for my $pubmed_id (@pubmed) {
	    print $seriesFH "!Series_pubmed_id = ", $pubmed_id, "\n";
	}
    }
    print $seriesFH "!Series_overall_design = ", $self->get_overall_design, "\n";
    print $seriesFH "!Series_type = ", $experiment_type{ident $self}, "\n";
    print $seriesFH "!Series_web_link = http://www.modencode.org\n";
    
    my %contributors = %{$contributors{ident $self}};
#    my $pi_already_in_contributors = 0;
    my $pi = $project{ident $self}; 
    foreach my $rank (sort keys %contributors) {
	my $firstname = $contributors{$rank}{'first'};
	my $str = $firstname . ",";
	if ($contributors{$rank}{'mid'}) {
	    $str .= $contributors{$rank}{'mid'}[0] . ",";
	}
	my $lastname = $contributors{$rank}{'last'};
	$str .= $lastname;
	print $str, "\n";
	print $seriesFH "!Series_contributor = ", $str, "\n";
	#my $name = ucfirst($firstname) . " " . ucfirst($lastname);
	#Mike Snyder == Michael Snyder
#	$pi_already_in_contributors = 1 if $pi =~ /$lastname/i; 
    }
    
    #add project PI as contributor as needed
#    if (not $pi_already_in_contributors) {
#	$pi =~ s/ /,/;
#	print $seriesFH "!Series_contributor = ", $pi, "\n";
#    }
}

sub chado2sample {
    my $self = shift;
    #sort out how many samples in this experiment. for GEO, one sample is defined by one array instance. 
    #this is done by grouping hybridization protocols first by extraction and then by array.
    my %combined_grp = %{$groups{ident $self}};
    my @raw_datafiles, ;
    my @normalize_datafiles;
    my @more_datafiles;

    for my $extraction (sort keys %combined_grp) {
	for my $array (sort keys %{$combined_grp{$extraction}}) {
	    print "\n##########extraction $extraction array $array\n";
	    sort @{$combined_grp{$extraction}{$array}};
	    unless ($split_seq_group{ident $self} == 1 and $ap_slots{ident $self}->{seq} >= 0) {
		$self->write_series_sample($extraction, $array);
		print "ok with write_series_sample\n";
	    }
	    for (my $channel=0; $channel<scalar(@{$combined_grp{$extraction}{$array}}); $channel++) {
		my $row = $combined_grp{$extraction}{$array}->[$channel];
		print $row, "\n";
		if ($split_seq_group{ident $self} == 1 and $ap_slots{ident $self}->{seq} >= 0) {
		    $self->write_series_sample_seq($extraction, $array, $channel);
		    print "ok with write_series_sample_seq\n";
		}
		$self->write_sample_source($extraction, $array, $row, $channel);
		print "ok with write_sample_source\n";
		$self->write_sample_organism($row, $channel);
		print "ok with write_sample_organism\n";
		$self->write_characteristics($row, $channel);
		print "ok with write_sample_characteristics\n";
		$self->write_sample_description($row, $channel);
		print "ok with write_sample_description\n";
		$self->write_sample_growth($row, $channel);
		print "ok with write_sample_growth\n";
		$self->write_sample_extraction($row, $channel);
		print "ok with write_sample_extraction\n";
		if ( defined($ap_slots{ident $self}->{'hybridization'}) and $ap_slots{ident $self}->{'hybridization'} != -1 ) {
		    if ( defined($ap_slots{ident $self}->{'labeling'}) ) {		
			$self->write_sample_label($row, $channel);
		    } else {
			$self->write_sample_label_without_labeling_protocol($row, $channel);
		    }
		    print "ok with write_sample_labeling\n";
		}
		if ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1 ) {
		    $self->write_sample_type($row);
		    print "ok with write_sample_type\n";
		    $self->write_sample_lib_strategy($row);
		    print "ok with write_sample_lib_strategy\n";
		    $self->write_sample_lib_source($row);
		    print "ok with write_sample_lib_source\n";
		    $self->write_sample_lib_selection($row);
		    print "ok with write_sample_lib_selection\n";
		    $self->write_sample_instrument_model($row);
		    print "ok with write_sample_instrument_model\n";
		    if ($split_seq_group{ident $self} == 1) {
			$self->write_sample_normalization($row);
		    }
		}
		push @raw_datafiles, $self->write_raw_data($row, $channel);
	    }
	    my $row = $combined_grp{$extraction}{$array}->[0];
	    if ( defined($ap_slots{ident $self}->{'hybridization'}) and $ap_slots{ident $self}->{'hybridization'} != -1 ) {	
		$self->write_sample_hybridization($row);
		print "ok with write_sample_hybridization\n";
	    }
	    if ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1 ) {	
		#$self->write_sample_seq($row);
	    }	    
	    if ( defined($ap_slots{ident $self}->{'scanning'}) and $ap_slots{ident $self}->{'scanning'} != -1 ) {		    
		$self->write_sample_scan($row);
		print "ok with write_sample_scan\n";
	    }
	    unless ($split_seq_group{ident $self} == 1 and $ap_slots{ident $self}->{seq} >= 0) {
		$self->write_sample_normalization($row);
		print "ok with write_sample_normalization\n";
	    }
	    if ( defined($ap_slots{ident $self}->{'hybridization'}) and $ap_slots{ident $self}->{'hybridization'} != -1 ) {
                $self->write_sample_normalization($row);
                print "ok with write_sample_normalization\n";	    
		$self->write_platform($row);
		print "ok with write_platform\n";
	    }
	    my @these_normalize_datafiles = $self->write_normalized_data($row);
	    push @normalize_datafiles, @these_normalize_datafiles;
	    print "ok with write_normalized_data with row $row\n";
	    if ($dup{ident $self}->{$row}) {
		my $that_row = $dup{ident $self}->{$row};
		print "get duplicated row $that_row\n";
		my @those_normalize_datafiles = $self->write_normalized_data_dup($that_row, \@these_normalize_datafiles);
		push @normalize_datafiles, @those_normalize_datafiles;
	    }
	    push @more_datafiles, $self->get_more_data($row);
	}
    }
    return (\@raw_datafiles, \@normalize_datafiles, \@more_datafiles);
}

sub write_series_sample_seq {
    my ($self, $extraction, $array, $channel) = @_;
    my $seriesFH = $seriesFH{ident $self};
    my $sampleFH = $sampleFH{ident $self};
    my $name = $self->get_sample_name_safe($extraction, $array);
    $channel += 1;
    $name .= " aliquote $channel";
    print $name, "\n";
    print $seriesFH "!Series_sample_id = GSM for ", $name, "\n";
    print $sampleFH "^Sample = GSM for ", $name, "\n";
    print $sampleFH "!Sample_title = ", $name, "\n";    
}

sub write_series_sample {
    my ($self, $extraction, $array) = @_;
    my $seriesFH = $seriesFH{ident $self};
    my $sampleFH = $sampleFH{ident $self};
    my $name = $self->get_sample_name_safe($extraction, $array);
    print $name, "\n";
    print $seriesFH "!Series_sample_id = GSM for ", $name, "\n";
    print $sampleFH "^Sample = GSM for ", $name, "\n";
    print $sampleFH "!Sample_title = ", $name, "\n";
}

sub write_sample_type {
    my ($self, $row) = @_;
    my $sampleFH = $sampleFH{ident $self};
    print $sampleFH "!Sample_type = ", "SRA", "\n";
}

sub write_sample_source {
    my ($self, $extraction, $array, $row, $channel) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ch = $channel+1;
    my $sample_name = $self->get_sample_sourcename_row_safe($extraction, $array, $row);
    if (defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1) {
	print $sampleFH "!Sample_source_name = ", $sample_name, " channel_$ch\n";
    } else {
	print $sampleFH "!Sample_source_name_ch$ch = ", $sample_name, " channel_$ch\n";
    }
}

sub write_sample_organism {
    my ($self, $row, $channel) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ch = $channel+1;
    if (defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1) {
	print $sampleFH "!Sample_organism = ", $organism{ident $self}, "\n";
    } else {
	print $sampleFH "!Sample_organism_ch$ch = ", $organism{ident $self}, "\n";
    }
}

sub write_characteristics {
    my ($self, $row, $channel) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ch = $channel+1;
    for my $biosource (@{$self->get_biological_source_row($row)}) {
	if (defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1) {
	    print $sampleFH  "!Sample_characteristics = ", $biosource, "\n";
	} else {
	    print $sampleFH  "!Sample_characteristics_ch$ch = ", $biosource, "\n";
	}
    }
}

sub write_sample_description {
    my ($self, $row, $channel) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ip_ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'immunoprecipitation'}]->[$row];
    my $antibodies;
    eval { $antibodies = _get_datum_by_info($ip_ap, 'input', 'name', 'antibody') };
    my $ch=$channel+1;
    if ($antibodies) {
	my @output_antibody_dbfields = ('official name', 'target name', 'host', 'antigen', 'clonal', 'purified', 'company', 'catalog', 'reference', 'short description');
	for my $antibody (@$antibodies) {
	    my $str = "!Sample_description = ";
	    my $info = get_dbfield_info($antibody);
	    
	    my $check = is_antibody($antibody);
	    if ( $check == 1 ) { #real antibody or antibody with Comment[IP]=0 column
		my $double_check = have_comment_IP_0($antibody);
		if ( $double_check == 0 ) {
		    $str .= "channel ch$ch is ChIP DNA; Antibody information listed below: ";
		    $str .= write_dbfield_info($info, \@output_antibody_dbfields);
		} else {
		    $str .= "channel ch$ch is input DNA;";
		}
	    }
	    elsif ( $check == 0 ) { #negative control
		$str .= "channel ch$ch is negative control for ChIP; Antibody information listed below: ";
		$str .= write_dbfield_info($info, \@output_antibody_dbfields);
	    }
	    else {
		$str .= "channel ch$ch is input DNA;" ;
	    }
	    print $sampleFH $str, "\n";
	}
    }
}

sub write_sample_growth {
    my ($self, $row, $channel) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ch = $channel+1;
    if (defined($affiliate_submission{ident $self})) {
	my $ds = $affiliate_submission{ident $self}->get_denorm_slots;
    for (my $i=0; $i<scalar @$ds; $i++) {
        my $ap = $ds->[$i]->[0];
        my $protocol_text = $affiliate_submission{ident $self}->get_protocol_text($ap);
        $protocol_text =~ s/\n//g; #one line                                                                                                 
        if ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1 ) {
            print $sampleFH "!Sample_growth_protocol = ", $protocol_text, "\n";
        } else {
            print $sampleFH "!Sample_growth_protocol_ch$ch = ", $protocol_text, "\n";
        }
    }
    }

    for (my $i=0; $i<$first_extraction_slot{ident $self}; $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[$row];
	my $protocol_text = $self->get_protocol_text($ap);
	$protocol_text =~ s/\n//g; #one line
	if ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1 ) {
	    print $sampleFH "!Sample_growth_protocol = ", $protocol_text, "\n";
	} else {
	    print $sampleFH "!Sample_growth_protocol_ch$ch = ", $protocol_text, "\n";
	}
    }
}

sub write_sample_extraction {
    my ($self, $row, $channel) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ch = $channel+1;
    print $sampleFH "!Sample_molecule_ch$ch = ", $self->get_molecule_type_row($row), "\n";
    my $final_slot;
    if ( defined($ap_slots{ident $self}->{'hybridization'}) and $ap_slots{ident $self}->{'hybridization'} != -1 ) {
	if ( defined($ap_slots{ident $self}->{'labeling'}) ) {
	    $final_slot = $ap_slots{ident $self}->{'labeling'};
	} else {
	    $final_slot = $ap_slots{ident $self}->{'hybridization'} - 1 ;
	}
    }
    elsif ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1 ) {
	$final_slot = $ap_slots{ident $self}->{'seq'}+1;
    }
    for (my $i=$first_extraction_slot{ident $self}; $i<$final_slot; $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[$row];
	my $protocol_text = $self->get_protocol_text($ap);
	$protocol_text =~ s/\n//g; #one line
	if ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1 ) {
	    print $sampleFH "!Sample_extract_protocol = ", $protocol_text, "\n";
	} else {
	    print $sampleFH "!Sample_extract_protocol_ch$ch = ", $protocol_text, "\n";
	}
    }
}
sub write_sample_label {
    my ($self, $row, $channel) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'labeling'}]->[$row];
    my $ch = $channel+1;
    print $sampleFH "!Sample_label_ch$ch = ", $self->get_label_row($row)->get_value(), "\n";    

    my $protocol_text = $self->get_protocol_text($ap);
    $protocol_text =~ s/\n//g; #one line
    print $sampleFH "!Sample_label_protocol_ch$ch = ", $protocol_text, "\n";
}

sub write_sample_label_without_labeling_protocol {
    my ($self, $row, $channel) = @_;
    my $sampleFH = $sampleFH{ident $self};

    #make sure this is a affy chip
    my $array = $self->get_array_row($row, 1);
    my $platform;
    for my $attr (@{$array->[0]->get_attributes()}) {
  	$platform = $attr->get_value() if (($attr->get_heading() =~ /platform/) and (defined($attr->get_value())));
    }
    unless (lc($platform) eq 'affymetrix') {
	die "this is not an affymetrix array experiment, yet there is no labeling protocol. suspicious submission.\n"
    }

    my $ch = $channel+1;
    print $sampleFH "!Sample_label_ch$ch = biotin\n";

    my $ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'hybridization'}]->[$row];
    my $protocol_text = $self->get_protocol_text($ap);
    $protocol_text =~ s/\n//g; #one line
    print $sampleFH "!Sample_label_protocol_ch$ch = ", $protocol_text, "\n";    
}

sub write_sample_hybridization {
    my ($self, $row, ) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'hybridization'}]->[$row];
    my $protocol_text = $self->get_protocol_text($ap);
    $protocol_text =~ s/\n//g; #one line
    print $sampleFH "!Sample_hyb_protocol = ", $protocol_text, "\n";
}

sub write_sample_lib_strategy {
    my ($self, $row) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $strategy = $self->get_lib_strategy();
    print $sampleFH "!Sample_library_strategy = ", $strategy, "\n";
}

sub write_sample_lib_source {
    my ($self, $row) = @_;
    my $sampleFH = $sampleFH{ident $self};
    print $sampleFH "!Sample_library_source = ", 'genomic', "\n";
}

sub write_sample_lib_selection {
    my ($self, $row) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $selection = $self->get_lib_selection();
    print $sampleFH "!Sample_library_selection = ", $selection, "\n";
}

sub write_sample_instrument_model {
    my ($self, $row) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my %machines = ('GPL9309' => 'Illumina Genome Analyzer', #worm
		    'GPL9058' => 'Illumina Genome Analyzer', #fly
		    'GPL6072' => 'Illumina Genome Analyzer', 
		    'GPL9269' => 'Illumina Genome Analyzer II', #worm
		    'GPL6664' => 'Illumina Genome Analyzer', #fly
	);
    my $gpl = $self->get_seqmachine_row($row);
    print $sampleFH "!Sample_instrument_model = ", $machines{$gpl}, "\n";   
}

sub set_lib_strategy {
    my ($self) = @_;
    my $strategy;
    if (defined($ap_slots{ident $self}->{'immunoprecipitation'}) and $ap_slots{ident $self}->{'immunoprecipitation'} != -1) {
	$strategy = "ChIP-Seq";
    }
    else {#default, whole genome shotgun
	$strategy = "WGS";
    }
    $lib_strategy{ident $self} = $strategy;
}

sub set_lib_selection {
    my ($self) = @_;
    my $selection;
    if (defined($ap_slots{ident $self}->{'immunoprecipitation'}) and $ap_slots{ident $self}->{'immunoprecipitation'} != -1) {
	$selection = "ChIP";   
    }
    else { #default random shearing only
	$selection = "RANDOM";
    }
    $lib_selection{ident $self} = $selection;
}

sub write_sample_seq {
    my ($self, $row, ) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'seq'}]->[$row];
    my $protocol_text = $self->get_protocol_text($ap);
    $protocol_text =~ s/\n//g; #one line
    print $sampleFH "!Sample_seq_protocol = ", $protocol_text, "\n";
}

sub write_sample_scan {
    my ($self, $row) = @_;    
    my $sampleFH = $sampleFH{ident $self};
    my $ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'scanning'}]->[$row];
    my $protocol_text = $self->get_protocol_text($ap);
    $protocol_text =~ s/\n//g; #one line
    print $sampleFH "!Sample_scan_protocol = ", $protocol_text, "\n";    
}

sub write_sample_normalization {
    my ($self, $row) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $genome_version_already_written = 0;
    print $sampleFH "!Sample_data_processing = ";
    my ($begin_slot, $end_slot);
    if (defined($ap_slots{ident $self}->{'hybridization'}) and $ap_slots{ident $self}->{'hybridization'} != -1) {
	$begin_slot = $ap_slots{ident $self}->{'scanning'}+1;
	$end_slot = $ap_slots{ident $self}->{'normalization'};
    }
    if (defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1) {
	$begin_slot = $ap_slots{ident $self}->{'seq'}+1;
	$end_slot = scalar(@{$denorm_slots{ident $self}})-1;
    }
    for (my $i=$begin_slot; $i<=$end_slot; $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[$row];
	my $protocol_text = $self->get_protocol_text($ap);
	my $protocol_name = $ap->get_protocol()->get_name() . ' protocol. ';
	$protocol_text =~ s/\n//g; #one line
	print $sampleFH $protocol_name, $protocol_text, " ";
	for my $datum (@{$ap->get_input_data()}) {
	    $genome_version_already_written = 1 if $datum->get_name() =~ /genome\s*version/i;
	    print $sampleFH " Processed data are obtained using following parameters: ", $datum->get_name(), " is ", $datum->get_value(), "   " if ($datum->get_heading() =~ /Parameter/i and $datum->get_value() !~ /^\s*$/);
	}	
    }
    #if (not $genome_version_already_written) {
	#my $organism = $organism{ident $self};
	#my $genome_version;
	#$genome_version = 'r5' if $organism eq "Drosophila melanogaster";
	#$genome_version = 'WS180' if $organism eq "Caenorhabditis elegans";
	#print $sampleFH "genome version is $genome_version";
    #}
    print $sampleFH "\n";
}

sub write_normalized_data_dup {
    my ($self, $row, $exist_normalize_datafiles) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $normalization_ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'normalization'}]->[$row];
    my $num_processed_data = scalar @$exist_normalize_datafiles + 1;
    for my $datum (@{$normalization_ap->get_output_data()}) {
        if (($datum->get_heading() =~ /Derived\s*Array\s*Data\s*File/i) || ($datum->get_heading() =~ /Result\s*File/i)) {
            my $path = $datum->get_value();
	    unless (scalar grep {$path eq $_} @$exist_normalize_datafiles) {
		my $type;
		$type = 'WIG' if ($path =~ /\.wig$/i);
		$type = 'GFF3' if ($path =~ /\.gff3$/i);
		print $sampleFH "!Sample_supplementary_file_", $num_processed_data, " = ", $path, "\n";
		print $sampleFH "!Sample_supplementary_file_type_", $num_processed_data, " = $type", "\n";
		$num_processed_data+=1;
	    }
	}
    }  
}

sub write_raw_data {
    my ($self, $row, $channel) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'raw'}]->[$row];
    my @raw_datafiles;
    my $num_raw_data = 1;
    my @suffixs = ('.bz2', '.z', '.gz', '.zip', '.rar');
    for my $datum (@{$ap->get_output_data()}) {
	if (($datum->get_heading() =~ /Array\s*Data\s*File/i) || ($datum->get_heading() =~ /Result\s*File/i)) {
	    my $path = $datum->get_value();
	    print "###raw data###", $path, "\n";
	    if ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1 ) {#assume there is just one fastq file per channel
		my ($file, $dir, $suffix) = fileparse($path);
		print $sampleFH "!Sample_raw_file_", "$num_raw_data = ", $file . $suffix, "\n";
		my $type;
		$type = 'FASTQ' if $file =~ /\.fastq/i;
		$type = 'WIG' if $file =~ /\.wig/i;
		print $sampleFH "!Sample_raw_file_type_", "$num_raw_data = ", $type, "\n";
		$num_raw_data += 1;
	    }
	    else {
		my ($file, $dir, $suffix) = fileparse($path, qr/\.[^.]*/);
		if (scalar grep {lc($suffix) eq $_} @suffixs) {
		    print $sampleFH "!Sample_supplementary_file = ", $file, "\n";
		    #print $sampleFH "!Sample_supplementary_file = ", $path, "\n";
		} else {
		    print $sampleFH "!Sample_supplementary_file = ", $file . $suffix, "\n";
		    #print $sampleFH "!Sample_supplementary_file = ", $path, "\n";
		}
	    }
	    push @raw_datafiles, $path;
	}
    }
    return @raw_datafiles;
}

sub write_platform {
    my ($self, $row) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $gpl = $self->get_array_row($row);
    print $sampleFH "!Sample_platform_id = ", $gpl, "\n";
}

sub write_normalized_data {
    my ($self, $row) = @_;
    my $sampleFH = $sampleFH{ident $self};
    my $normalization_ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'normalization'}]->[$row];
    my @normalization_datafiles;
    my @suffixs = ('.bz2', '.z', '.gz', '.zip', '.rar');
    my $num_processed_data = 1;
    for my $datum (@{$normalization_ap->get_output_data()}) {
	if (($datum->get_heading() =~ /Derived\s*Array\s*Data\s*File/i) || ($datum->get_heading() =~ /Result\s*File/i)) {
	    my $path = $datum->get_value();
	    if ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1 ) {
		my ($file, $dir, $suffix) = fileparse($path);
		my $type;
		$type = 'WIG' if ($file =~ /\.wig$/i);
		$type = 'GFF3' if ($file =~ /\.gff3$/i);
		#print $sampleFH "!Sample_supplementary_file_", $num_processed_data, " = ", $file . $suffix, "\n";
		print $sampleFH "!Sample_supplementary_file_", $num_processed_data, " = ", $path, "\n";
		print $sampleFH "!Sample_supplementary_file_type_", $num_processed_data, " = $type", "\n";
		$num_processed_data+=1;
	    } 
	    else {
		my ($file, $dir, $suffix) = fileparse($path, qr/\.[^.]*/);
		if (scalar grep {lc($suffix) eq $_} @suffixs) {
		    print $sampleFH "!Sample_supplementary_file = ", $file, "\n";
		    #print $sampleFH "!Sample_supplementary_file = ", $path, "\n";
		} else {
		    print $sampleFH "!Sample_supplementary_file = ", $file . $suffix, "\n";
		    #print $sampleFH "!Sample_supplementary_file = ", $path, "\n";
		}
	    }
	    push @normalization_datafiles, $path;
	}
    }
    return @normalization_datafiles;
}

sub get_more_data {
     my ($self, $row) = @_;
     my @more_datafiles;
     my $start_slot = $ap_slots{ident $self}->{'normalization'};
     $start_slot -= 1 if $start_slot == scalar($denorm_slots{ident $self})-1;
     for (my $i=$start_slot; $i<scalar(@{$denorm_slots{ident $self}}); $i++) {
	 my $ap = $denorm_slots{ident $self}->[$i]->[$row];
	 for my $datum (@{$ap->get_output_data()}) {
	     if ($datum->get_heading() =~ /Result\s*File/i) {
		 my $path = $datum->get_value();
		 push @more_datafiles, $path;
	     }
	 }
     }
     return @more_datafiles;
}

sub get_overall_design {
    my $self = shift;
    my $overall_design = "";
    $overall_design .= "EXPERIMENT TYPE: " . $experiment_type{ident $self} . ". ";
    my ($biological_source, $source);
    if ( $experiment_type{ident $self} eq 'CGH' ) {
	$biological_source = $self->get_biological_source_CGH();
	for (my $i=0; $i<scalar(@$biological_source); $i++) {
	    $source = join("; ", @{$biological_source->[$i]});
	    my $tmp = $i+1;
	    $overall_design .= "BIOLOGICAL SOURCE $tmp" . ": " . $source . "; ";
	}
    } else {
	$biological_source = $self->get_biological_source();
	print "ok";
	$source = join("; ", @$biological_source);
	$overall_design .= 'BIOLOGICAL SOURCE: ' . $source . "; ";
    }
    print $overall_design;
    if ( defined($ap_slots{ident $self}->{'hybridization'}) and $ap_slots{ident $self}->{'hybridization'} != -1 ) {
	$overall_design .= " " . $self->get_replicate_status();
	print $self->get_replicate_status();
	print "ok2";
    }
    print "####################\n";
    my $real_factors = $self->get_real_factors();
    my $factors = join("; ", @$real_factors);
    $overall_design .= " EXPERIMENTAL FACTORS: " . $factors;
    print "ok3";
    print $overall_design;
    return $overall_design;
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
	if ($name =~ /^\s*Project\s*$/i) {
	    $value =~ s/\n//g;
	    $value =~ s/^\s*//;
	    $value =~ s/\s*$//;
	    print "project: $value\n";
	    $project{ident $self} = $projects{lc($value)} if $value;
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
	print "lab: ", $value, "\n" and $lab{ident $self} = $value if ($name =~ /^\s*Lab\s*$/i); 
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
    print Dumper(%person);
    $contributors{ident $self} = \%person;
}

sub get_real_factors {
    my $self = shift;
    my $factors = $factors{ident $self};
    my @rfactors;
    print "#############here are factors: ", Dumper($factors);
    for my $rank (keys %$factors) {
	my $type = $factors->{$rank}->[1];
	my $rfactor = undef;
	if ($type =~ /strain/i) {
	    my $rfactor = 'Strain ' . $strain{ident $self};
	    push @rfactors, $rfactor if defined($strain{ident $self});
	}
	elsif ($type =~ /cell[\s_]*line/i) {
	    print $cellline{ident $self};
	    my $rfactor = 'Cell Line ' . $cellline{ident $self};
	    push @rfactors, $rfactor if defined($cellline{ident $self});
	}
	elsif ($type =~ /dev/i || $type =~ /stage/i) {
	    my $rfactor = 'Developmental Stage ' . $devstage{ident $self};
	    push @rfactors, $rfactor if defined($devstage{ident $self});
	}
	elsif ($type =~ /tissue/i) {
	    my $rfactor = 'Tissue ' . $tissue{ident $self};
	    push @rfactors, $rfactor if defined($tissue{ident $self});
	}
	elsif ($type =~ /sex/i) {
	    my $rfactor = 'Sex ' . $sex{ident $self};
	    push @rfactors, $rfactor if defined($sex{ident $self});
	}
	elsif ($type =~ /antibody/i) {
	    my $antibody_name = get_dbfield_info($antibody{ident $self})->{'official name'};
	    $antibody_name .= ' (target is ' . get_dbfield_info($antibody{ident $self})->{'target name'} . ')';
	    my $rfactor = 'Antibody ' . $antibody_name;
	    push @rfactors, $rfactor if defined($antibody{ident $self});
	}
	elsif ($type =~ /gene/i) {
	    my $gene = $tgt_gene{ident $self};
	    my $rfactor = 'Target gene ' . $gene;
	    push @rfactors, $rfactor if defined($gene);
	}
	else {
	    my $factor_name = $self->get_value_by_info(0, 'name', $factors->{$rank}->[0]);
	    $factor_name = $self->get_affiliate_submission->get_value_by_info(0, 'name', $factors->{$rank}->[0]) unless $factor_name;
	    my $rfactor = "$type $factor_name";
	    push @rfactors, $rfactor if defined($rfactor);
	}
	#$rfactor = 'Strain ' . $strain{ident $self} if $type =~ /strain/i ;
	#$rfactor = 'Cell Line ' . $cellline{ident $self} if $type =~ /cell\s*line/i;
	#$rfactor = 'Developmental Stage ' . $devstage{ident $self} if ( $type =~ /dev/i || $type =~ /stage/i);
	#$rfactor = 'Tissue ' . $tissue{ident $self} if $type =~ /tissue/i;
	#$rfactor = 'Sex ' . $sex{ident $self} if $type =~ /sex/i;
	#if ( $type =~ /antibody/i ) {
	#    my $antibody_name = get_dbfield_info($antibody{ident $self})->{'official name'};
	#    $rfactor = 'Antibody ' . $antibody_name;
	#}
	#$rfactor = 'Gene' . $factors->{$rank}->[0] if $type =~ /gene/i;
	#push @rfactors, $rfactor if defined($rfactor);
    }
    return \@rfactors;
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
    print Dumper(%factor);
    $factors{ident $self} = \%factor;
}

sub set_experiment_design {
    my $self = shift;
    my %design;
    foreach my $property (@{$experiment{ident $self}->get_properties()}) {
	my ($name, $value, $rank, $type) = ($property->get_name(), 
					    $property->get_value(), 
					    $property->get_rank(), 
					    $property->get_type());
	if ($name =~ /Experimental\s*Design/i) {
	    $design{$rank} = [$value];
	    if (defined($property->get_termsource())) {
		push @{$design{$rank}}, ($type->get_cv()->get_name(), 
					 $property->get_termsource()->get_accession());
	    }
	}
    }
    print Dumper(%design);
    $experiment_design{ident $self} = \%design;
}

sub set_experiment_type {
    my $self = shift;
    my $ap_slots = $ap_slots{ident $self};
    my $design = $experiment_design{ident $self};
    my $type;
    for my $rank (keys %$design) {
	my $dezn = $design->{$rank}->[0];
	$type = "CGH" if $dezn =~ /comparative_genome_hybridization/i ;
	if (($dezn =~ /transcript/i) or ($dezn =~/rna/i)) {
	    $type = "Transcript tiling array analysis" if  (defined($ap_slots->{'hybridization'}) and  $ap_slots->{'hybridization'} != -1);
	    $type = "RNA-seq" if (defined($ap_slots->{'seq'}) and  $ap_slots->{'seq'} != -1);
	}
    }
    if (defined($ap_slots->{'immunoprecipitation'}) and  $ap_slots->{'immunoprecipitation'} != -1) {
	if ( defined($ap_slots->{'rip'}) and $ap_slots->{'rip'} != -1  and $ap_slots->{'rip'} == $ap_slots->{'immunoprecipitation'}) {
	    #$type = "RIP-chip" if (defined($ap_slots->{'hybridization'}) and  $ap_slots->{'hybridization'} != -1);
	    $type = "RIP-seq" if (defined($ap_slots->{'seq'}) and  $ap_slots->{'seq'} != -1);	    
	} else {
	    $type = "CHIP-chip" if (defined($ap_slots->{'hybridization'}) and  $ap_slots->{'hybridization'} != -1);
	    $type = "CHIP-seq" if (defined($ap_slots->{'seq'}) and  $ap_slots->{'seq'} != -1);
	}
    }
    if ($type) {
	$experiment_type{ident $self} = $type;
    } else {
	$experiment_type{ident $self} = "tiling array analysis" if (defined($ap_slots->{'hybridization'}) and  $ap_slots->{'hybridization'} != -1);
	$experiment_type{ident $self} = "deep sequencing analysis" if (defined($ap_slots->{'seq'}) and  $ap_slots->{'seq'} != -1);
    }
}

sub set_normalized_slots {
    my $self = shift;
    $normalized_slots{ident $self} = $reader{ident $self}->get_normalized_protocol_slots();
}

sub set_denorm_slots {
    my $self = shift;
    $denorm_slots{ident $self} = $reader{ident $self}->get_denormalized_protocol_slots();
#    for my $ap_slot (@{$denorm_slots{ident $self}}) {
#	print "#####\n";
#	for my $ap (@$ap_slot) {
#	    print $ap->get_protocol()->get_name(), "\n";
#	}
#    }
}

sub set_num_of_rows {
    my $self = shift;
    $num_of_rows{ident $self} = scalar @{$denorm_slots{ident $self}->[0]};
}

sub get_biological_source {
    my $self = shift;
    return $self->get_biological_source_row(0);
}

sub get_biological_source_CGH {
    my $self = shift;
    my @biological_source_CGH;
    for my $row ( @{ $groups{ ident $self }->{0}->{0} } ) {
	print "####row:$row\n";
	for my $bio ( @{$self->get_biological_source_row($row)} ) {
	    print $bio, "\n";
	}
     	push @biological_source_CGH, $self->get_biological_source_row($row);
    }
    return \@biological_source_CGH;
}

sub get_biological_source_row {
    my ($self, $row) = @_;
    my @str;
    my $strain = $self->get_strain_row($row) || $self->get_strain();
    my $cellline = $self->get_cellline_row($row) || $self->get_cellline();
    my $tissue = $self->get_tissue_row($row) || $self->get_tissue();
    my $devstage = $self->get_devstage_row($row) || $self->get_devstage();
    my $genotype = $self->get_genotype_row($row) || $self->get_genotype();
    my $sex = $self->get_sex_row($row) || $self->get_sex();
    my $transgene = $self->get_transgene_row($row) || $self->get_transgene();
    push @str, "Strain: $strain" if $strain;
    push @str, "Cell Line: $cellline" if $cellline;
    push @str, "Tissue: $tissue" if $tissue;
    push @str, "Developmental Stage: $devstage" if $devstage;
    push @str, "Genotype: $genotype" if $genotype;
    push @str, "Sex: $sex" if $sex;
    push @str, "Transgene: $transgene" if $transgene;
    return \@str;
}

sub get_replicate_status {
    my $self = shift;
    my $str = '';
    $str .= "NUMBER OF REPLICATES: " . $self->get_number_of_replicates() . "; ";

    my $extraction_array = $self->get_extraction_array_status();
    my $dye_swap_status;
    unless ( $antibody{ident $self} ) { #no antibody info
	#$str .= 'Unknown dye swap status.'; #do not output 'Unknown'
	return $str;
    }
    #if ( $ap_slots{ident $self}->{'immunoprecipitation'} ) {
#	$dye_swap_status = $self->get_dye_swap_status();
#    }
#    my $no_dye_swap = 1;
#    for my $extraction (sort keys %$extraction_array) {
#	my $replica = $extraction+1;
#	#$str .= "Replicate $replica applied to " . $extraction_array->{$extraction} . " array(s), ";
#	if ( defined($dye_swap_status) ) {
#	    for my $array (sort keys %{$dye_swap_status->{$extraction}}) {
#		if ($dye_swap_status->{$extraction}->{$array} == 1) {
#		    my $sample = $self->get_sample_name_safe($extraction, $array);
#		    #$str .= "Replicate $replica (Sample $sample) is dye swap. ";
#		    $no_dye_swap = 0;
#		}
#	    }
#	}
#    }
    #$str .= 'No dye swap.' if $no_dye_swap;
    return $str;
}

sub get_number_of_replicates {
    my $self = shift;
    my $grps = $groups{ident $self};
    my $num_of_grps = keys %$grps;
    return $num_of_grps;
}

sub get_extraction_array_status {
    my $self = shift;
    my $grps = $groups{ident $self};
    my $num_of_grps = keys %$grps;
    my %extraction_array;
    for (my $extraction=0; $extraction<$num_of_grps; $extraction++) {
	my $num_of_array = keys %{$grps->{$extraction}};
	$extraction_array{$extraction} = $num_of_array;
    }
    return \%extraction_array ;
}

sub get_dye_swap_status { # an immunoprecipitation protocol must exist before call this function
    my $self = shift;
    my $grps = $groups{ident $self};
    my $num_of_grps = scalar(keys %$grps);
    my %dye_swap = ();
    for (my $extraction=0; $extraction<$num_of_grps; $extraction++) {
	my $num_of_array = scalar(keys %{$grps->{$extraction}});
	for (my $array=0; $array<$num_of_array; $array++) {
	    my $num_of_channel = scalar @{$grps->{$extraction}->{$array}};
	    $dye_swap{$extraction}{$array} = 0; 
	    next if $num_of_channel == 1;
	    my $cy5_without_antibody = 0;
	    my $cy3_with_antibody = 0;
	    for (my $channel=0; $channel<$num_of_channel; $channel++) {
		my $row = $grps->{$extraction}->{$array}->[$channel];
		my $antibody = $self->get_antibody_row($row);
		my $label = $self->get_label_row($row);
		if ( $antibody && (is_antibody($antibody) == 1) && ($label->get_value() =~ /cy3/i) ) { #antibody and cy3
		    $cy3_with_antibody = 1;
		}
		if ( $antibody && (is_antibody($antibody) != 1) && ($label->get_value() =~ /cy5/i) ) { #cy5 but not antibody
                    $cy5_without_antibody = 1;
                }
	    }
	    if ( $cy5_without_antibody && $cy3_with_antibody ) {
		$dye_swap{$extraction}{$array} = 1;
	    }
	}
    }
    return \%dye_swap;
}

sub set_organism {
    my $self = shift;
    my $protocol = $denorm_slots{ident $self}->[0]->[0]->get_protocol();
    for my $attr (@{$protocol->get_attributes()}) {
	print $attr->get_value(), "\n" and $organism{ident $self} = $attr->get_value() if $attr->get_heading() eq 'species';
    }
}

sub set_tgt_gene {
    my $self = shift;
    my $factors = $factors{ident $self};
    my $header;
    for my $rank (keys %$factors) {
	my $type = $factors->{$rank}->[1];
	print $type;
	$header = $factors->{$rank}->[0] and last if $type eq 'gene';
	print "header is $header";
    }
    if ($header) {
	my $tgt_gene = $self->get_value_by_info(0, 'name', $header);
	print "tgt gene is:", $tgt_gene;
	$tgt_gene{ident $self} = $tgt_gene;
    }
}



sub set_strain {
    my $self = shift;
    for my $row (@{$groups{ident $self}->{0}->{0}}) {
	my $strain = $self->get_strain_row($row);
	print "$strain\n" and $strain{ident $self} = $strain and last if defined($strain);
    }
}

sub get_strain_row {
    my ($self, $row) = @_;
    my ($strain, $tgt_gene, $tag);
    for (my $i=0; $i<=$last_extraction_slot{ident $self}; $i++) {
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
		my ($aname, $aheading, $avalue, $atype) = ($attr->get_name(), $attr->get_heading(), $attr->get_value(), $attr->get_type());
		if (lc($aname) =~ /^\s*strain\s*$/ || lc($atype->get_name()) eq 'strain_or_line') {
		    if ( $avalue =~ /[Ss]train:(.*)&/ ) {
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
	$strain{ident $self} = $strain;
    }
}

sub set_cellline {
    my $self = shift;
    for my $row (@{$groups{ident $self}->{0}->{0}}) {
	my $cellline = $self->get_cellline_row($row);
	print "$cellline\n" and $cellline{ident $self} = $cellline and last if defined($cellline);
    }
}

sub get_cellline_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<=$last_extraction_slot{ident $self}; $i++) {
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
		my ($aname, $aheading, $avalue, $atype) = ($attr->get_name(), $attr->get_heading(), $attr->get_value(), $attr->get_type());
		if (lc($aname) =~ /^cell[_\s]*line/ || $atype->get_name() eq 'cell_line') {
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

sub set_devstage {
    my $self = shift;
    for my $row (@{$groups{ident $self}->{0}->{0}}) {
	my $devstage = $self->get_devstage_row($row);
	print "$devstage\n" and $devstage{ident $self} = $devstage and last if defined($devstage);
    }
}

sub get_devstage_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<=$last_extraction_slot{ident $self}; $i++) {
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
		my ($aname, $aheading, $avalue, $atype) = ($attr->get_name(), $attr->get_heading(), $attr->get_value(), $attr->get_type());
		if (lc($aname) =~ /dev.*stage/ || $atype->get_name() eq 'developmental_stage') {
		    if ( $avalue =~ /[Dd]ev[Ss]tage(Worm|Fly)?:(.*?):/ ) {
			my $tmp = uri_unescape($2);
			$tmp =~ s/_/ /g;
			return $tmp;
		    }
		}
		if (lc($aheading =~ /dev.*stage/)) {
		    return uri_unescape($avalue);
		}
	    }
	}
    }
    return undef;
}

sub set_genotype {
    my $self = shift;
    for my $row (@{$groups{ident $self}->{0}->{0}}) {
	my $genotype = $self->get_genotype_row($row);
	print "$genotype\n" and $genotype{ident $self} = $genotype and last if defined($genotype);
    }
}

sub get_genotype_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<=$last_extraction_slot{ident $self}; $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[$row];
	for my $datum (@{$ap->get_input_data()}) {
	    for my $attr (@{$datum->get_attributes()}) {
		my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
		if (lc($aheading) =~ /^\s*genotype\s*$/) {
		    my $tmp = uri_unescape($avalue);
		    $tmp =~ s/_/ /g;
		    return $tmp;
		}
	    }
	}
    }
    return undef;
}

sub set_transgene {
    my $self = shift;
    for my $row (@{$groups{ident $self}->{0}->{0}}) {
	my $transgene = $self->get_transgene_row($row);
	print "$transgene\n" and $transgene{ident $self} = $transgene and last if defined($transgene);
    }
}

sub get_transgene_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<=$last_extraction_slot{ident $self}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $datum (@{$ap->get_input_data()}) {
            for my $attr (@{$datum->get_attributes()}) {
                my ($aname, $aheading, $avalue) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
                if (lc($aheading) =~ /^\s*transgene\s*$/) {
		    my $tmp = uri_unescape($avalue);
		    $tmp =~ s/_/ /g;
		    return $tmp;
                }
            }
        }
    }
    return undef;
}

sub set_sex {
    my $self = shift;
    for my $row (@{$groups{ident $self}->{0}->{0}}) {
	my $sex = $self->get_sex_row($row);
	print "$sex\n" and $sex{ident $self} = $sex if defined($sex);
    }
}

sub get_sex_row {
    my ($self, $row) = @_;
    my %sex = ('M' => 'Male', 
	       'F' => 'Female', 
	       'U' => 'Unknown', 
	       'H' => 'Hermaphrodite', 
	       'M+H' => 'mixed Male and Hermaphrodite population',
	       'F+H' => 'mixed Female and Hermaphrodite population');
    for (my $i=0; $i<=$last_extraction_slot{ident $self}; $i++) {
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

sub set_tissue {
    my $self = shift;
    for my $row (@{$groups{ident $self}->{0}->{0}}) {
	my $tissue = $self->get_tissue_row(0);
	print "$tissue\n" and $tissue{ident $self} = $tissue and last if defined($tissue);
    }
}

sub get_tissue_row {
    my ($self, $row) = @_;
    for (my $i=0; $i<=$last_extraction_slot{ident $self}; $i++) {
        my $ap = $denorm_slots{ident $self}->[$i]->[$row];
        for my $datum (@{$ap->get_input_data()}) {
            my ($name, $heading, $value) = ($datum->get_name(), $datum->get_heading(), $datum->get_value());
            if (lc($name) =~ /^\s*tissue\s*$/) {
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

sub set_molecule_type {
    my $self = shift;
    for my $row (@{$groups{ident $self}->{0}->{0}}) {
	my $molecule_type = $self->get_molecule_type_row($row);
	print "$molecule_type\n" and $molecule_type{ident $self} = $molecule_type if defined($molecule_type);
    }
}

sub get_molecule_type_row {
    my ($self, $row) = @_;
    my $molecule;
    my $last_extraction_slot = $last_extraction_slot{ident $self} < $extract_name_ap_slot{ident $self} ? $extract_name_ap_slot{ident $self} : $last_extraction_slot{ident $self};  
    for (my $i=0; $i<=$last_extraction_slot; $i++) {
	my $ap = $denorm_slots{ident $self}->[$i]->[$row];
	for my $datum (@{$ap->get_output_data()}) {
	    my $type = $datum->get_type()->get_name();
	    $molecule = 'genomic DNA' and last if ($type =~ /dna/i || $type =~ /chromatin/i);
	    if ($type =~ /rna/i) {
		$molecule = 'total RNA' and last if $type =~ /total/i;
		$molecule = 'polyA RNA' and last if $type =~ /polyA/i;
		$molecule = 'cytoplasmic RNA' and last if $type =~ /cyto/i;
		$molecule = 'nuclear RNA' and last if $type =~ /nuc/i;
		$molecule = 'total RNA' and last;
	    }
	    $molecule='protein' and last if ($type =~ /protein/i);	
	}
    }
    croak("is the type of extracted molecule a dna, total_rna, nucleic rna, ...?") unless $molecule;
    return $molecule;
}

sub set_antibody {
    my $self = shift;
    if ($ap_slots{ident $self}->{'immunoprecipitation'}) {
	if ( defined($ap_slots{ident $self}->{'hybridization'}) and $ap_slots{ident $self}->{'hybridization'} != -1 ) {
	    for my $row (@{$groups{ident $self}->{0}->{0}}) {
		my $ab = $self->get_antibody_row($row);
		if ($ab) {
		    if ( is_antibody($ab) != -1 ) { #negative control or real antibody 
			$antibody{ident $self} = $ab;
		    }
		}
	    }
	}
	elsif (defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1) {
	    for my $row (0..$num_of_rows{ident $self}-1) {
		my $ab = $self->get_antibody_row($row);
		if ($ab) {
		    if ( is_antibody($ab) != -1 ) { #negative control or real antibody
			$antibody{ident $self} = $ab;
		    }
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

sub have_comment_IP_0 { #antibody has a attribute Comment[IP] == 0
    my $antibody = shift;
    for my $attr (@{$antibody->get_attributes()}) {
	my ($name, $heading, $value) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
	if ( $heading =~ /^\s*comment\s*$/i && $name =~ /^\s*ip\s*$/i && $value == 0 ) {
	    return 1;
	}
    }
    return 0;
}

sub write_dbfield_info {
    # %info from get_dbfield_info function;
    # @fields order of fields for output
    my ($info, $fields) = @_;
    my $str;
    for my $fld (@$fields) {
	$str .= $fld . ": " . $info->{$fld} . ";" if exists($info->{$fld});
    }
    return $str;
}

sub get_dbfield_info { #concatenate rows of values with same heading and name, the phenomana is frequently caused by a bug/glitch? of EO's dbfields/XMLwriter code 
    my $obj = shift;
    my %info;
    for my $attr (@{$obj->get_attributes()}) {
	my ($name, $heading, $value) = ($attr->get_name(), $attr->get_heading(), $attr->get_value());
	my $s = $name ? "$heading [$name]" : $heading;
	my $t = uri_unescape($value);
	$t =~ s/_/ /g;
	if ( exists $info{$s} ) {
	    $info{$s} .= " $t";
	} else {
	    $info{$s} = $t;
	}
    }
    return \%info;
}


sub get_antibody_row { #keep it as a datum object
    my ($self, $row) = @_;
    my $denorm_slots = $denorm_slots{ident $self} ;
    my $ap_slots = $ap_slots{ident $self} ;
    my $ip_ap = $denorm_slots->[$ap_slots->{'immunoprecipitation'}]->[$row];
    my $antibodies;
    eval { $antibodies = _get_datum_by_info($ip_ap, 'input', 'name', 'antibody') } ;
    return $antibodies->[0] unless $@;
    return undef;
}

sub get_label_row { #keep it as a datum object
    my ($self, $row) = @_;   
    my $denorm_slots = $denorm_slots{ident $self} ;
    my $ap_slots = $ap_slots{ident $self} ;
    my $label_ap = $denorm_slots->[$ap_slots->{'labeling'}]->[$row];
    my $labels = _get_datum_by_info($label_ap, 'input', 'name', '\s*label\s*');
    return $labels->[0];
}

sub get_seqmachine_row {
    my ($self, $row) = @_;
    my $seq_ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'seq'}]->[$row];
    my $gd;
    eval {
	my $gd = _get_datum_by_info($seq_ap, 'input', 'name', '\s*sequencing\s*platform\s*');
    };
    if ($@) {
	if ($organism{ident $self} eq 'Drosophila melanogaster') {
	    print 'GPL9058';
	    return 'GPL9058';
	}
	if ($organism{ident $self} eq 'Caenorhabditis elegans') {
	    print 'GPL9309';
	    return 'GPL9309';
	}
    }
    else {
	my $gpl = $gd->[0]->get_value();
	print $gpl;
	return $gpl;
    }
}

sub get_array_row {
    my ($self, $row, $return_object) = @_;
    my $hyb_ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'hybridization'}]->[$row];
    my $array;
    my $ok1 = eval { $array = _get_datum_by_info($hyb_ap, 'input', 'name', '\s*array\s*') } ;
    if (not $ok1) {
        $array = _get_datum_by_info($hyb_ap, 'input', 'name', '\s*adf\s*');
    }
    my $gpl;
    if (scalar(@$array)) {
	my $attr;
	my $ok2 = eval { $attr = _get_attr_by_info($array->[0], 'heading', '\s*adf\s*') } ;
	if ($ok2) {
	    $gpl = $1 if $attr->[0]->get_value() =~ /(GPL\d*)\s*$/;
	} else {
	    croak("can not find the array dbfield heading adf, probably dbfields did not populate correctly.");
	}
    }
    if ($gpl eq '') {croak("can not find the array GPL number\n");};
    return $array if $return_object;
    return $gpl;
}

sub set_source_name_ap_slot {
    my $self = shift;
    my @aps = $self->get_slotnum_by_datum_property('input', 0, 'heading', undef, 'Source\s*Name');
    $source_name_ap_slot{ident $self} = $aps[0] if scalar(@aps);
}

sub set_extract_name_ap_slot {
    my $self = shift;
    my @aps = $self->get_slotnum_by_datum_property('output', 0, 'heading', undef, 'Extract\s*Name');
    print @aps;
    $extract_name_ap_slot{ident $self} = $aps[0] if scalar(@aps);
}

sub get_sample_name_safe {
    my ($self, $extraction, $array) = @_;
    my $row = $groups{ident $self}->{$extraction}->{$array}->[0];
    return $self->get_sample_name_row_safe($extraction, $array, $row);
}

sub get_sample_name_row_safe {
    my ($self, $extraction, $array, $row) = @_;
    my $extrac = $extraction+1;
    my $arry = $array+1;
    if ( defined($ap_slots{ident $self}->{'hybridization'}) and $ap_slots{ident $self}->{'hybridization'} != -1) {
	return $self->get_sample_name_row($extraction, $array, $row) . ' extraction' . $extrac . "_array" . $arry;
    }
    if ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1) {
	return $self->get_sample_name_row($extraction, $array, $row) . ' extraction' . $extrac . "_seq" . $arry;
    }    
}

sub get_sample_name_row {
    my ($self, $extraction, $array, $row) = @_;
    my ($sourcename, $autogenerate) = $self->get_sample_sourcename_row($extraction, $array, $row);
    my ($hyb_ap, $hyb_data, $ok);
    my @hyb_names;
    if ($autogenerate) {
	$hyb_ap = $denorm_slots{ident $self}->[$ap_slots{ident $self}->{'hybridization'}]->[$row];
	$ok = eval { $hyb_data = _get_datum_by_info($hyb_ap, 'input', 'heading', 'Hybridization\s*Name') };
	if ($ok) {
	    @hyb_names = map {$_->get_value()} @$hyb_data;
	    return $hyb_names[0];
	} else {
	    return $sourcename;
	}
    } else {
	return $sourcename;
    }
}

sub get_sample_sourcename_row_safe {
    my ($self, $extraction, $array, $row) = @_;
    my ($sourcename, $autogenerate) = $self->get_sample_sourcename_row($extraction, $array, $row);
    my $extrac = $extraction+1;
    my $arry = $array+1;
    if ( defined($ap_slots{ident $self}->{'hybridization'}) and $ap_slots{ident $self}->{'hybridization'} != -1) {
	return $sourcename . ' extraction' . $extrac . "_array" . $arry;
    }
    if ( defined($ap_slots{ident $self}->{'seq'}) and $ap_slots{ident $self}->{'seq'} != -1) {
	return $sourcename . ' extraction' . $extrac . "_seq" . $arry;
    }
}

sub get_sample_sourcename_row {
    my ($self, $extraction, $array, $row) = @_;
    my $extract_ap = $denorm_slots{ident $self}->[$last_extraction_slot{ident $self}]->[$row];
    my $first_ap = $denorm_slots{ident $self}->[0]->[$row];
    my ($sample_data, $sample_attributes, $source_data, $source_attributes);
    my (@sample_names, @more_sample_names, @source_names, @more_source_names);
    my ($ok1, $ok2, $ok21, $ok3, $ok4, $ok41);
    my $autogenerate = 0;
    $ok1 = eval { $sample_data = _get_datum_by_info($extract_ap, 'input', 'heading', '[Extract|Sample]\s*Name') } ;
    if ($ok1) {
        @sample_names = map {$_->get_value()} @$sample_data;
	return ($sample_names[0], $autogenerate);
    } else {
        $ok2 = eval { $sample_data = _get_datum_by_info($extract_ap, 'output', 'heading', 'Result') };
	if ($ok2) {
	    @sample_names = map {$_->get_value()} @$sample_data;
	    $ok21 = eval { $sample_attributes = _get_attr_by_info($sample_data->[0], 'heading', 'Cell\s*Type') } ;
	    if ($ok21) {
		@more_sample_names = map {$_->get_value()} @$sample_attributes;
		my $tmp = join(",", @more_sample_names);
		$tmp = uri_unescape($tmp);
		$tmp =~ s/_/ /g;
		my $return_name = $tmp . " (" . $sample_names[0] . ")";
		return ($return_name, $autogenerate);
	    } else {
		return ($sample_names[0], $autogenerate);
	    }
	}
    }
    
    if  ($first_extraction_slot{ident $self} != 0) {
	$ok3 = eval { $source_data = _get_datum_by_info($first_ap, 'input', 'heading', '[Hybrid|Source][A-Za-z]*\s*Name') };
	if ($ok3) {
            @source_names = map {$_->get_value()} @$source_data;
	    return ($source_names[0], $autogenerate);
	}
	else {
	    $ok4 = eval { $source_data = _get_datum_by_info($first_ap, 'output', 'heading', 'Result') };
	    if ($ok4) {
		@source_names = map {$_->get_value()} @$source_data;
		$ok41 = eval { $source_attributes = _get_attr_by_info($source_data->[0], 'heading', 'Cell\s*Type') } ;
		if ($ok41) {
		    @more_source_names = map {$_->get_value()} @$source_attributes;
		    my $tmp = join(",", @more_sample_names);
		    $tmp = uri_unescape($tmp);
		    $tmp =~ s/_/ /g;
		    my $return_name = $tmp . " (" . $sample_names[0] . ")";
		    return ($return_name, $autogenerate);
		} else {
		    return ($source_names[0], $autogenerate);
		}
	    }
	}
    }
    else {
	$autogenerate = 1;
	return (join(";", @{$self->get_real_factors()}) , $autogenerate);
    }
}

sub set_ap_slots {
    my $self = shift;
    my %slots;
    $slots{'hybridization'} = $self->get_slotnum_hyb();
    $slots{'seq'} = $self->get_slotnum_seq();
    print "found sequencing protocol at slot $slots{'seq'}...\n" if defined($slots{'seq'}) and $slots{'seq'} != -1;
    $slots{'labeling'} = $self->get_slotnum_label();
    unless (defined($slots{'labeling'}) and $slots{'hybridization'} != -1) {
	print "WARNING!!! did not find labeling protocol.\n";
    }
    print "found labeling protocol at slot $slots{'labeling'}...\n" if defined($slots{'labeling'});
    $slots{'scanning'} = $self->get_slotnum_scan();
    print "found scanning protocol at slot $slots{'scanning'}...\n" if defined($slots{'scanning'});
    $slots{'normalization'} = $self->get_slotnum_normalize();
    print "found normalization protocol at slot $slots{'normalization'}...\n" if defined($slots{'normalization'});
    $slots{'raw'} = $self->get_slotnum_raw();
    print "found raw protocol at slot $slots{'raw'}...\n" if defined($slots{'raw'}) and $slots{'raw'} != -1;
    $slots{'immunoprecipitation'} = $self->get_slotnum_ip();
    print "found ip protocol at slot $slots{'immunoprecipitation'}...\n" if defined($slots{'immunoprecipitation'});
    $slots{'rip'} = $self->get_slotnum_rip();
    #$slots{'source name'} = $self->get_slotnum_source_name();
    #$slots{'sample name'} = $self->get_slotnum_sample_name();
    #$slots{'extract name'} = $self->get_slotnum_extract_name();    
    $ap_slots{ident $self} = \%slots;
}

sub set_first_extraction_slot {
    my $self = shift;
    $first_extraction_slot{ident $self} = $self->get_slotnum_extract('protocol');    
}

sub set_last_extraction_slot {
    my $self = shift;
    $last_extraction_slot{ident $self} = $self->get_slotnum_extract('group');
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

sub get_slotnum_extract {
    my ($self, $option) = @_;
    my $type = "extract";
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    if (scalar(@aps) > 1) {
	if ($option eq 'group') { #report this one to group rows in SDRF to GEO samples=extraction+array
	    return $self->check_complexity(\@aps);
	} elsif ($option eq 'protocol') { #report this one to write out all extraction protocols and in between
	    if (defined($extract_name_ap_slot{ident $self}) and $extract_name_ap_slot{ident $self} != -1) {
		return $aps[0] > $extract_name_ap_slot{ident $self} ? $extract_name_ap_slot{ident $self} : $aps[0] ;
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
		my @itypes = ('whole_organism', 'multi-cellular organism', 'organism_part', 'DNA', 'genomic_DNA');
		my @iaps;
		for my $type (@itypes) {
		    my @xaps = $self->get_slotnum_by_datum_property('input', 0, 'type', undef, $type);
		    @iaps = merge_two_lists(\@iaps, \@xaps);
		}
		my @otypes = ('DNA', 'genomic_DNA', 'chromatin', 'mRNA', '\s*RNA');
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
		    croak("Every experiment must have at least one extraction protocol. Maybe you omitted this protocol in SDRF?");
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
    my $xap_slots = $experiment{ident $self}->get_applied_protocol_slots();
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

sub get_slotnum_ip {
    my $self = shift;
    my $type = 'immunoprecipitation';
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    return $aps[-1] if scalar(@aps);
    return undef;
}

sub get_slotnum_rip {
    my $self = shift;
    my $type = 'immunoprecipitation';
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    my $otype = 'rna';
    for my $ap_slot (@aps) {
	my $ap = $normalized_slots{ident $self}->[$ap_slot]->[0];
	return $ap_slot if (ap_has_datatype($ap, 'output', $otype));
    }
    return undef;
}

sub get_slotnum_label {
    my $self = shift;
    my $type = "label";
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    return $aps[-1] if scalar(@aps);
    return undef;
}

sub get_slotnum_scan {
    my $self = shift;
    my $type = "scan";
    my @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    return $aps[-1] if scalar(@aps);
    return undef;
}

sub get_slotnum_raw {
    my $self = shift;
    return $self->get_slotnum_raw_array if $self->get_slotnum_hyb() != -1;
    return $self->get_slotnum_raw_seq() if $self->get_slotnum_seq() != -1;   
}

sub get_slotnum_raw_seq {
    my $self = shift;
    my @types = ('FASTQ');
    for my $type (@types) {
	my @aps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
	return $aps[0] if scalar(@aps);
    }
    croak("can not find the protocol that generates raw data");
}

sub get_slotnum_raw_array {
    my $self = shift;
    #first search by output data type, such as modencode-helper:nimblegen_microarray_data_file (pair) [pair]
    #or modencode-helper:CEL [Array Data File], or agilent_raw_microarray_data_file (TXT)
    my @types = ('nimblegen_microarray_data_file (pair)', 'CEL', 'agilent_raw_microarray_data_file');
    for my $type (@types) {
	print $type;
	my @aps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
	print @aps;
	#even there are more than 1 raw-data-generating protocols, choose the first one since it is the nearest to hyb protocol
	return $aps[0] if scalar(@aps);
    }
    croak("can not find the protocol that generates raw data");
}

sub get_slotnum_normalize {
    my $self = shift;
    return $self->get_slotnum_normalize_array() if $self->get_slotnum_hyb() != -1;
    return $self->get_slotnum_normalize_seq() if $self->get_slotnum_seq() != -1;    
}

sub get_slotnum_normalize_seq {
    my $self = shift;
    my @types = ('WIG', 'BED', 'Sequence_Alignment/Map (SAM)');
    my $slot;
    for my $type (@types) {
	my @aps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
	sort @aps;
	if (scalar(@aps)) {
	    if (defined($slot)) {
		$slot = $aps[-1] if ($aps[-1] > $slot);
	    } else {
		$slot = $aps[-1];
	    }
	}
    }
    return $slot if defined($slot);
    croak("can not find the normalization protocol");
}

sub get_slotnum_normalize_array {
    my $self = shift;
    #first search by output data type, such as modencode-helper:Signal_Graph_File [sig gr]
    my @types = ('Signal_Graph_File [sig gr]', 'normalized data', 'scaled data');
    for my $type (@types) {
	my @aps = $self->get_slotnum_by_datum_property('output', 0, 'type', undef, $type);
	#even there are more than 1 normalization protocols, choose the first one since it is the nearest to hyb protocol
	return $aps[0] if scalar(@aps);
    }

    my @aps;
    #then search by protocol type
    my $type = "normalization";
    @aps = $self->get_slotnum_by_protocol_property(1, 'heading', 'Protocol\s*Type', $type);
    #even there are more than 1 normalization protocols, return the first one, since it is the nearest to hyb protocol
    return $aps[0] if scalar(@aps);

    #finally search by protocol name
    my $name = "normalization";
    @aps = $self->get_slotnum_by_protocol_property(0, 'name', undef, $name);
    return $aps[0] if scalar(@aps);
    croak("can not find the normalization protocol");
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

sub ap_slot_without_real_data {
    my ($self, $ap_slot) = @_;
    my $anonymous = 1;
    for (my $i = 0; $i < scalar(@{$normalized_slots{ident $self}->[$ap_slot]}); $i++) {
	last if $anonymous == 0;
	for my $datum (@{$normalized_slots{ident $self}->[$ap_slot]->[$i]->get_output_data}) {
	    $anonymous = 0 and last unless $datum->is_anonymous;
	}
    }
    return $anonymous;
}

sub set_replicate_group_ap_slot {
    my $self = shift;
    my $text = 'replicate[\s_]*group';
    $replicate_group_ap_slot{ident $self} = $self->get_ap_slot_by_attr_info('input', 'name', $text);
}

sub set_sample_name_ap_slot {
    my $self = shift;
    my $text = 'Sample\s*Name';
    my $slot = $self->get_ap_slot_by_datum_info('output', 'heading', $text);
    if ( defined($slot) and $slot > 0 ) {
	$sample_name_ap_slot{ident $self} = $slot;
    } else { #fly groups tend to use sample name instead of source name for the beginning material since it is produced
	#by bloomington subgroup
	my $islot = $self->get_ap_slot_by_datum_info('input', 'heading', $text);
	if ( defined($islot) and $islot == 0 ) {
	    $sample_name_ap_slot{ident $self} = $islot;
	}
    }
}

sub get_ap_slot_by_datum_info {
    my ($self, $direction, $field, $fieldtext) = @_;
    for (my $i=0; $i<scalar @{$normalized_slots{ident $self}}; $i++) {
	my $ap = $normalized_slots{ident $self}->[$i]->[0];
	eval { _get_datum_by_info($ap, $direction, $field, $fieldtext) };
 	return $i unless $@;
	next if $@;
    }
    return undef;
}

sub get_ap_slot_by_attr_info {
    my ($self, $direction, $field, $fieldtext) = @_;
    for (my $i=0; $i<scalar @{$normalized_slots{ident $self}}; $i++) {
        my $ap = $normalized_slots{ident $self}->[$i]->[0];
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



sub group_by_this_ap_slot {
    my $self = shift;
    my $hyb_col = $ap_slots{ident $self}->{'hybridization'};
    my $seq_col = $ap_slots{ident $self}->{'seq'};
    my $replicate_group_col = $replicate_group_ap_slot{ident $self};
    my $extract_name_col = $extract_name_ap_slot{ident $self};
    my $sample_name_col = $sample_name_ap_slot{ident $self};
    my $source_name_col = $source_name_ap_slot{ident $self};
    print "replicate group slot $replicate_group_col\n";
    print "extract name slot $extract_name_col\n";
    print "sample name slot $sample_name_col\n";
    print "source name slot $source_name_col\n";
    if ( defined($replicate_group_col) && (defined($hyb_col) and $hyb_col>=0) ) {
	print "I will use ap slot $replicate_group_col (replicate group) to group\n";
	#return [$replicate_group_col, 'replicate[\s_]*group'] if defined($replicate_group_col);
    }
    if ( defined($replicate_group_col) && (defined($seq_col) and $seq_col>=0)) {
	return [$source_name_col, 'Source\s*Name'] if ($replicate_group_col == $source_name_col);
	return [$sample_name_col, 'Sample\s*Name'] if ($replicate_group_col == $sample_name_col);
    }

    print "I will use ap slot $extract_name_col (extract name) to group\n" and return [$extract_name_col, 'Extract\s*Name'] if ( defined($extract_name_col) and $last_extraction_slot{ident $self} <= $extract_name_col );

    print "I will use ap slot $last_extraction_slot{ident $self} (last extraction slot) to group\n" and return [$last_extraction_slot{ident $self}, 'protocol'] if ( defined($extract_name_col) and $last_extraction_slot{ident $self} > $extract_name_col );

    if ( !defined($extract_name_col) ) {
	print "I will use ap slot $source_name_col (source name) to group\n" and return [$source_name_col, 'Source\s*Name'] if defined($source_name_col);
	print "I will use ap slot $sample_name_col (sample name) to group\n" and return [$sample_name_col, 'Sample\s*Name'] if defined($sample_name_col);
	if ( $self->ap_slot_without_real_data($last_extraction_slot{ident $self}) ) { 
	    croak("suspicious submission, extraction protocol has only anonymous data, AND no protocol has Extract Name, Sample Name, Source(Hybrid) Name.");
	}
    } else {
	print "I will use ap slot $last_extraction_slot{ident $self} (last choice) to group\n" and return [$last_extraction_slot{ident $self}, 'protocol'];
    }
}

sub set_groups {
    my $self = shift;
    print $self->get_slotnum_seq(), "seq\n";
    print $self->get_slotnum_hyb(), "hyb\n";

    return $self->set_groups_seq() if (defined($self->get_slotnum_seq()) and $self->get_slotnum_seq() != -1);
    return $self->set_groups_array() if (defined($self->get_slotnum_hyb()) and $self->get_slotnum_hyb() != -1);
}

sub set_groups_seq {
    my $self = shift;
    my $denorm_slots = $denorm_slots{ident $self};
    my $ap_slots = $ap_slots{ident $self};
    my ($nr_grp, $all_grp, $all_grp_by_seq);
    my ($last_extraction_slot, $method) = @{$self->group_by_this_ap_slot()};
    print "group by this slot $last_extraction_slot using method $method\n";
    if ( $method eq 'protocol' ) {
	($nr_grp, $all_grp) = $self->group_applied_protocols($denorm_slots->[$last_extraction_slot], 1);
    } else {
	if ($method eq 'replicate[\s_]*group') {
	    $all_grp = $self->group_applied_protocols_by_attr($denorm_slots->[$last_extraction_slot], 'name', $method);
	}
	elsif ($method eq 'Source\s*Name') {
	    $all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'input', 'heading', $method);
	} elsif ($method eq 'Sample\s*Name'){
	    if ($last_extraction_slot == 0) {
		$all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'input', 'heading', $method);
	    } else {
		$all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'output', 'heading', $method);
	    }
	} else { #extract name are treated by validator as output
	    $all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'output', 'heading', $method);
	}	
    }
    print "all groups by extraction...\n";
    print Dumper($all_grp);

    eval {
	$all_grp_by_seq = $self->group_applied_protocols_by_data($denorm_slots->[$ap_slots->{'seq'}], 'input', 'name', 'sequencing platform');
    };
    #print "the eval err msg says: $@";
    if ($@) {
	print "seq machine ok1";
	eval {
	    $all_grp_by_seq = $self->group_applied_protocols_by_attr($denorm_slots->[$ap_slots->{'seq'}], 'name', 'sequencing platform');
	};
	if ($@) {
	    print "seq machine ok2";
	    my %all_grp_by_seq = map {$_ => 0} (0..$num_of_rows{ident $self}-1);
	    $all_grp_by_seq = \%all_grp_by_seq;
	}
    }
    print "all groups by seq machine...\n";
    print Dumper($all_grp_by_seq);

    my %combined_grp;
    my %duplicate;
    while (my ($row, $extract_grp) = each %$all_grp) {
	my $seq_grp = $all_grp_by_seq->{$row};
	if (exists $combined_grp{$extract_grp}{$seq_grp}) {
	    my $this_extract_ap = $denorm_slots->[$last_extraction_slot]->[$row];
	    my $this_seq_ap = $denorm_slots->[$ap_slots->{'seq'}]->[$row];
	    my $same = 0; 
            #repeats of rows in denormalized ap slots caused by experimental factor column at the end of SDRF
	    #or by sharing inputs
	    for my $that_row (@{$combined_grp{$extract_grp}{$seq_grp}}) {
                my $that_extract_ap = $denorm_slots->[$last_extraction_slot]->[$that_row];
                my $that_seq_ap = $denorm_slots->[$ap_slots->{'seq'}]->[$that_row];
		if ($this_extract_ap->equals($that_extract_ap) && $this_seq_ap->equals($that_seq_ap)) {
		    $same = 1; 
		    print "duplicated row $row!\n";
		    $duplicate{$that_row} = $row; 
		    last; 
		}
	    }
	    push @{$combined_grp{$extract_grp}{$seq_grp}}, $row unless $same;	    
	} else {
	    $combined_grp{$extract_grp}{$seq_grp} = [$row]; 
	}
    }
    print "final groups...\n";
    print Dumper(%combined_grp);
    $groups{ident $self} = \%combined_grp;
    print "duplicates...\n";
    print Dumper(%duplicate);
    $dup{ident $self} = \%duplicate;
}

sub set_groups_array {
    my $self = shift;
    my $denorm_slots = $denorm_slots{ident $self};
    my $ap_slots = $ap_slots{ident $self};
    my ($last_extraction_slot, $method) = @{$self->group_by_this_ap_slot()};
    my ($nr_grp, $all_grp, $all_grp_by_array);
    if ( $method eq 'protocol' ) {
	($nr_grp, $all_grp) = $self->group_applied_protocols($denorm_slots->[$last_extraction_slot], 1);
    } else {
	if ($method eq 'replicate[\s_]*group') {
	    $all_grp = $self->group_applied_protocols_by_attr($denorm_slots->[$last_extraction_slot], 'name', $method);
	}
	elsif ($method eq 'Source\s*Name') {
	    $all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'input', 'heading', $method);
	} elsif ($method eq 'Sample\s*Name'){
	    if ($last_extraction_slot == 0) {
		$all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'input', 'heading', $method);
	    } else {
		$all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'output', 'heading', $method);
	    }
	} else { #extract name are treated by validator as output
	    $all_grp = $self->group_applied_protocols_by_data($denorm_slots->[$last_extraction_slot], 'output', 'heading', $method);
	}
    }
    
    my $ok = eval {$all_grp_by_array = $self->group_applied_protocols_by_data($denorm_slots->[$ap_slots->{'hybridization'}],
								     'input', 'name', '\s*array\s*')};
    $all_grp_by_array = $self->group_applied_protocols_by_data($denorm_slots->[$ap_slots->{'hybridization'}],
							       'input', 'name', 'adf') unless $ok;

    my %combined_grp;
    while (my ($row, $extract_grp) = each %$all_grp) {
	my $array_grp = $all_grp_by_array->{$row};
	if (exists $combined_grp{$extract_grp}{$array_grp}) {
            my $this_extract_ap = $denorm_slots->[$last_extraction_slot]->[$row];
            my $this_hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$row];
	    my $ignore = 0; #possible validator bug might cause repeats of rows in denormalized ap slots
	    for my $that_row (@{$combined_grp{$extract_grp}{$array_grp}}) {
                my $that_extract_ap = $denorm_slots->[$last_extraction_slot]->[$that_row];
                my $that_hyb_ap = $denorm_slots->[$ap_slots->{'hybridization'}]->[$that_row];
                $ignore = 1 and print "ignored $row!\n" and last if ($this_extract_ap->equals($that_extract_ap) && $this_hyb_ap->equals($that_hyb_ap));
	    }
	    push @{$combined_grp{$extract_grp}{$array_grp}}, $row unless $ignore;
	} else {
	    $combined_grp{$extract_grp}{$array_grp} = [$row]; 
	}
    }
    #print Dumper($denorm_slots);
    #print Dumper($all_grp);
    print Dumper(%combined_grp);
    $groups{ident $self} = \%combined_grp;
}

sub group_applied_protocols {
    my ($self, $ap_slot, $rtn) = @_; #these applied protocols are simple obj from AppliedProtocol.pm
    return _group($ap_slot, $rtn);
}

sub group_applied_protocols_by_data {
    my ($self, $ap_slot, $direction, $field, $fieldtext, $rtn) = @_;
#    for my $ap (@$ap_slot) {
#	print $ap->get_protocol->get_name(), "\n";
#	for my $datum (@{$ap->get_input_data}) {
#	    print $datum->get_heading, ":", $datum->get_value, " ";
#	    if ($datum->get_heading eq 'Source Name') {
#		for my $att (@{$datum->get_attributes()}) {
#		    print $att->get_heading, ":", $att->get_value, "\n";
#		}
#	    }
#	}
#	print "\n";
#    }
#    print $direction, $field, $fieldtext, "\n";
    my $data = _get_data_by_info($ap_slot, $direction, $field, $fieldtext);
    return _group($data, $rtn);
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
    print Dumper(@attrs);
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

sub get_protocol_text {
    my ($self, $ap) = @_;
    my $protocol = $ap->get_protocol();
    if ( $self->get_long_protocol_text() ) {
	my $url = $protocol->get_termsource()->get_accession();
	my $title;
	if ( $url =~ /\?title=\w+\// ) {
    	    $url =~ /\?title=\w+\/(\w+):?/;
	    $title = $1;
	} else {
	    $url =~ /\?title=(\w+):?/;
	    $title = $1;
	} 
      	$title =~ s/_/ /g;
	return $title . " protocol; " . decode_entities($self->_get_full_protocol_text($url));
    }
    else {
	if (my $txt = $protocol->get_description()) {
	    return decode_entities($txt);
	}
    }
}

sub _get_full_protocol_text {
    my ($self, $url) = @_;
    require URI;
    require LWP::UserAgent;
    require HTTP::Request::Common;
    require HTTP::Response;
    require HTTP::Cookies;
    require HTML::TreeBuilder;
    require HTML::FormatText;
    
    #use wiki render action to get the context instead of left/top panels
    $url .= '&action=render';
    my $uri = URI->new($url);
    
    my $username = $self->get_config()->{wiki}{username};
    my $password = $self->get_config()->{wiki}{password};

    my $fetcher = new LWP::UserAgent;
    my @ns_headers = (
	'User-Agent' => 'reporter by zheng',
	'Accept' => 'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*',
	'Accept-Charset' => 'iso-8859-1,*,utf-8',
	'Accept-Language' => 'en-US',
	);
    $fetcher->cookie_jar({});

    my $login_query = "title=Special:Userlogin&action=submitlogin";
    my $login = $uri->scheme. "://" . $uri->host . $uri->path . "?" . $login_query;
    my $response = $fetcher->post($login, @ns_headers, Content=>[wpName=>$username, wpPassword=>$password,wpRemember=>"1",wpLoginAttempt=>"Log in"]);
    if ($response->code != 302) {
	print "modencode private wiki login failed!";
	exit 1;
    }
    
    my $request = $fetcher->request(HTTP::Request->new('GET' => $url));
    my $content = $request->content();

    my $tree = HTML::TreeBuilder->new_from_content($content);
    my $formatter = HTML::FormatText->new();
    my $txt = $formatter->format($tree);

    $txt =~ s/(.*)Validation\s*Form.*/{$txt = $1;}/gsex; #find the last match, just in case
    $txt =~ s/(.*)Notes\s*\n.*/{$txt = $1;}/gsex;
    $txt =~ s/Protocol\s*Text(\s*-*\s*)?//i;
    $txt =~ s/\[edit\]//i;
    $txt =~ s/ +/ /g;
    return $txt;    
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

sub get_value_by_info {
    my ($self, $row, $field, $fieldtext) = @_;
    for (my $i=0; $i<=$last_extraction_slot{ident $self}; $i++) {
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




sub _get_data_by_info {
    my ($aps, $direction, $field, $fieldtext) = @_;
    my @data = ();
    for my $ap (@$aps) {
	push @data, @{_get_datum_by_info($ap, $direction, $field, $fieldtext)};
    }
    croak("can not find data with field $field and fieldtext $fieldtext") unless scalar @data;
    return \@data;
}

#called by 
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

#called by get_slotnum_by_protocol_property
sub _get_protocol_info {
    my ($protocol, $field) = @_;
    my $func = "get_$field";
    return $protocol->$func();
}

sub _get_datum_info {
    my ($datum, $field) = @_;
    return $datum->get_name() if $field eq 'name';
    return $datum->get_heading() if $field eq 'heading';
    return $datum->get_type()->get_name() if $field eq 'type';
    return $datum->get_termsource()->get_db()->get_name() . ":" . $datum->get_termsource()->get_accession() if $field eq 'dbxref';
}

sub _get_datum_value {
    my ($datum, $field, $fieldtext) = @_;
    return $datum->get_value() if (($field eq 'name') && ($datum->get_name() =~ /$fieldtext/i));
    return $datum->get_value() if (($field eq 'heading') && ($datum->get_heading() =~ /$fieldtext/i)); 
    return undef;
}

sub _get_attr_info {
    my ($attr, $field) = @_;
    return $attr->get_name() if $field eq 'name';
    return $attr->get_heading() if $field eq 'heading';
    return $attr->get_type()->get_name() if $field eq 'type';
    return $attr->get_termsource()->get_db()->get_name() . "|" . $attr->get_termsource()->get_accession() if $field eq 'dbxref';
}

#called by get_slotnum_by_protocol_property
sub _get_attr_value {
    my ($attr, $field, $fieldtext) = @_;
    return $attr->get_value() if (($field eq 'name') && ($attr->get_name() =~ /$fieldtext/i));
    return $attr->get_value() if (($field eq 'heading') && ($attr->get_heading() =~ /$fieldtext/i));
    return undef;
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

sub ap_has_datatype {
    my ($ap, $direction, $type) = @_;
    my $func = 'get_' . $direction . '_data';
    my $sign = 0;
    for my $datum (@{$ap->$func()}) {
	$sign = 1 and last if $datum->get_type()->get_name() =~ /$type/i;
    }
    return 1 if $sign == 1;
    return 0 if $sign == 0;
}

1;
