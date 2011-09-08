#!/usr/bin/perl
use strict;
use Data::Dumper;
use File::Basename qw/fileparse/;
my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir;
}

use Config::IniFiles;
use Getopt::Long qw[GetOptions GetOptionsFromString];
mprint("###pipeline started###", 0);
my $now = localtime;
mprint("initiate... $now", 0);
#default config files
my $cfg_dir = $root_dir . 'config/';
my $cfg = $cfg_dir . 'pipeline.ini';
#uniform name for all intermediate files;
#do we need timestamp to make it unique?
my ($org, $name);
#create cfg for each TF run to override the default
my $option = GetOptions ("cfg:s" => \$cfg,
			 "org=s" => \$org,
			 "name=s" => \$name);
$org = lc($org);
usage() unless -e $cfg;
usage() unless defined($name);
my @allow_org = qw[worm fly];
usage() unless defined($org) && scalar grep {$org eq $_} @allow_org;
mprint("the pipeline will be constructed according to configure file $cfg", 1);
mprint("all output files will have prefix $name", 1);

tie my %ini, 'Config::IniFiles', (-file => $cfg);
#parse [PIPELINE] session to understand what need to run
my $preprocess = $ini{PIPELINE}{run_preprocess};
my $align = $ini{PIPELINE}{run_alignment};
my $peakcall = $ini{PIPELINE}{run_peak_calling};
my $postprocess = $ini{PIPELINE}{run_postprocess};
#make sure dirs exist and end with '/'
my $out_dir = $ini{OUTPUT}{dir};
my $log_dir = $ini{OUTPUT}{log};
mkdir($out_dir) unless -e $out_dir;
mkdir($log_dir) unless -e $log_dir;
$out_dir .= '/' unless $out_dir =~ /\/$/;
$log_dir .= '/' unless $log_dir =~ /\/$/;
$out_dir .= $name ; mkdir($out_dir) unless -e $out_dir; $out_dir .= '/' unless $out_dir =~ /\/$/;
$log_dir .= $name ; mkdir($log_dir) unless -e $log_dir; $log_dir .= '/' unless $log_dir =~ /\/$/;

mprint("output dir is $out_dir", 1);
mprint("log dir is $log_dir", 1);
#input files
my @r1_chip = split /\s+/, $ini{INPUT}{r1_ChIP};
my @r2_chip = split /\s+/, $ini{INPUT}{r2_ChIP} if exists $ini{INPUT}{r2_ChIP};
my @r1_input = split /\s+/, $ini{INPUT}{r1_input};
my @r2_input = split /\s+/, $ini{INPUT}{r2_input} if exists $ini{INPUT}{r2_input};
#check files exist, to do!
die "no rep1 ChIP files specified.\n" unless scalar @r1_chip;
die "no rep1 input files specified.\n" unless scalar @r1_input;
die "no rep2 ChIP files specified although there are rep2 input files.\n" if scalar @r2_input && !scalar @r2_chip;
die "no rep2 input files specified although there are rep2 ChIP files.\n" if scalar @r2_chip && !scalar @r2_input;
map {die "rep1 ChIP file $_ does not exist!\n" unless -e $_} @r1_chip;
map {die "rep1 input file $_ does not exist!\n" unless -e $_} @r1_input;
map {die "rep2 ChIP file $_ does not exist!\n" unless -e $_} @r2_chip if scalar @r2_chip;
map {die "rep2 input file $_ does not exist!\n" unless -e $_} @r2_input if scalar @r2_input;
mprint("rep1 ChIP files are:", 1);
map {mprint($_, 2)} @r1_chip;
mprint("rep1 input files are:", 1);
map {mprint($_, 2)} @r1_input;
if (scalar @r2_chip) {
    mprint("rep2 ChIP files are:", 1);
    map {mprint($_, 2)} @r2_chip;
}
if (scalar @r2_input) {
    mprint("rep2 input files are:", 1);
    map {mprint($_, 2)} @r2_input;
}
$now = localtime;
mprint("initiation done $now\n", 0);

my $ori_raw_dir = $out_dir . 'origin/' ; mkdir($ori_raw_dir) unless -e $ori_raw_dir;
my $uniform_raw_dir = $out_dir . 'uniform/' ; mkdir($uniform_raw_dir) unless -e $uniform_raw_dir;
#uniform name/format of the input short read files
my $r1_chip_reads = $uniform_raw_dir . $name . '_r1_chip.fastq';
my $r2_chip_reads = $uniform_raw_dir . $name . '_r2_chip.fastq';
#my $chip_reads = $uniform_raw_dir . $name . '_chip.fastq';
my $r1_input_reads = $uniform_raw_dir . $name . '_r1_input.fastq';
my $r2_input_reads = $uniform_raw_dir . $name . '_r2_input.fastq';
#my $input_reads = $uniform_raw_dir . $name . '_input.fastq';

my $alignment_dir = $out_dir . 'alignment/'; mkdir($alignment_dir) unless -e $alignment_dir;
#uniform name/format of the alignment files;
my $r1_chip_alignment = $alignment_dir . $name . '_r1_chip.sam';
my $r2_chip_alignment = $alignment_dir . $name . '_r2_chip.sam';
my $chip_alignment = $alignment_dir . $name . '_chip.sam';
my $r1_input_alignment = $alignment_dir . $name . '_r1_input.sam';
my $r2_input_alignment = $alignment_dir . $name . '_r2_input.sam';
my $input_alignment = $alignment_dir . $name . '_input.sam';

my $peak_dir = $out_dir . 'peak/' ; mkdir($peak_dir) unless -e $peak_dir;
#uniform name for peak files;
my $r1_peak = $peak_dir . $name . '_r1_peak.bed';
my $r2_peak = $peak_dir . $name . '_r2_peak.bed';
my $peak = $peak_dir . $name . '_peak.bed';

my $done_preprocess = 0;
if (defined($preprocess) && $preprocess == 1) {
    $now = localtime;
    mprint("preprocessing... $now", 0);
    my $simple_preprocess = $ini{PREPROCESS}{run_simple_preprocess};
    my $remove_barcode = $ini{PREPROCESS}{run_remove_barcode};
    if (defined($remove_barcode) && $remove_barcode == 1) {
	mprint("pipeline will do preprocess: remove barcode.", 1);
	run_uniform_input({rm_barcode =>1,
			   cfg => $cfg_dir . 'remove_barcode.ini', 
			   dent => 1});
	$done_preprocess = 1;
	$now = localtime;
	mprint("done $now", 1);
    } 
    elsif (defined($simple_preprocess) && $simple_preprocess == 1) {
	mprint("pipeline will do misc preprocess, such as unzip, etc.", 1);
	run_uniform_input({dent => 1});
	$done_preprocess = 1;
	$now = localtime;
	mprint("done $now", 1);
    }
    else {
	if (-e $r1_chip_reads && -e $r1_input_reads) {
	    if (scalar @r2_chip && scalar @r2_input) {
		if (-e $r2_chip_reads && -e $r2_input_reads) {
		    $done_preprocess = 1;
		    mprint("uniformed input files already exists: $r1_chip_reads, $r1_input_reads, $r2_chip_reads, $r2_input_reads", 1);
		}
	    } else {
		$done_preprocess = 1;
		mprint("uniformed input files already exists: $r1_chip_reads, $r1_input_reads", 1);
	    }
	}
    }
    mprint("preprocess done $now\n", 0);
}

my $done_align = 0;
if (defined($align) && $align == 1) {
    if (defined($preprocess) && $preprocess == 1) {
	die "preprocess not done yet\n" unless $done_preprocess == 1;
    }
    $now = localtime;
    mprint("aligning... $now", 0);
    my $run_bowtie = $ini{ALIGNMENT}{run_bowtie};
    if (defined($run_bowtie) && $run_bowtie == 1) {
	mprint("pipeline will do alignment: bowtie.", 1); #this shall put into bowtie module
	my $cfg = $cfg_dir . 'bowtie.ini';
	run_bowtie($cfg);
	$done_align = 1;
	$now = localtime;
	mprint("done $now", 0);
    } 
    else {
	if (-e $r1_chip_alignment && -e $r1_input_alignment) {
	    if (scalar @r2_chip && scalar @r2_input) {
		if (-e $r2_chip_alignment && -e $r2_input_alignment) {
		    $done_align = 1;
		    mprint("alignment files already exists: $r1_chip_alignment $r2_chip_alignment $r1_input_alignment $r2_input_alignment", 1);
		}
	    } else {
		$done_align = 1;
		mprint("alignment files already exists: $r1_chip_alignment $r1_input_alignment", 1);
	    }
	}
    }
    $now = localtime;
    mprint("alignment done $now\n", 0);
}

my $done_peakcall = 0;
if (defined($peakcall) && $peakcall == 1) {
    if (defined($align) && $align == 1) {
	die "alignment not done yet\n" unless $done_align == 1 ; 
    }
    $now = localtime;
    mprint("peak calling $now...", 0);
    my $run_peakranger = $ini{PEAK_CALLING}{run_peakranger};
    if (defined($run_peakranger) && $run_peakranger == 1) {
	mprint("pipeline will do peak call: peakranger.", 1);
	my $cfg = $cfg_dir . 'peakranger.ini';
	run_peakranger({cfg => $cfg});
	$done_peakcall = 1;
	$now = localtime;
	mprint("done $now", 0);
    }
    else {
	if (-e $r1_peak) {
	    if (scalar @r2_chip && scalar @r2_input) {
		if (-e $r2_peak && -e $peak) {
		    $done_peakcall = 1;
		    mprint("peak called already! $r1_peak $r2_peak $peak", 1);
		}
	    } else {
		$done_peakcall = 1;
		mprint("peak called already! $r1_peak", 1);
	    }
	}
    }
}

if (defined($postprocess) && $postprocess == 1) {
    if (defined($peakcall) && $peakcall == 1) {
	die "peak calling not done yet\n" unless $done_peakcall == 1 ;
    }
    mprint("postprocessing $now...", 0);
    my $run_idr = $ini{POSTPROCESS}{run_idr};
    if (defined($run_idr) && $run_idr == 1) {
	die "need rep2 files to do IDR.\n" unless scalar @r2_chip && scalar @r2_input; 
	mprint("pipeline will do postprocess: idr.", 1);
	my $cfg = $cfg_dir . 'idr.ini';
	run_idr($cfg);
	$now = localtime;
	mprint("done $now", 1);
    }
}

mprint("###pipeline finished###", 0);

sub mprint {
    my ($msg, $dent) = @_;
    my $default_dent = "    ";
    print $default_dent x $dent;
    print $msg . "\n";
}

sub usage {
    my $usage = qq[$0 -name <name> -org <worm|fly> [-cfg <cfg_file>]];
    print "Usage: $usage\n";
    exit 1;
}

sub run_uniform_input {
    my ($opt) = @_;
    #do copy if input are symlink
    #do unzip if input are zipped
    #cat multiple-lanes file into one lane file
    #remove barcode if necessary
    tie my %ini, "Config::IniFiles", (-file => $opt->{cfg}) if exists $opt->{cfg};
    my $script = $ini{SCRIPT}{remove_barcode};
    my $force_redo = $ini{SCRIPT}{force_redo};
    die "$script does not exist.\n" unless -e $script;
    my $rm_barcode = "";
    $rm_barcode = '-rm_barcode 1' if defined($opt) && $opt->{rm_barcode} == 1;
    my $cmd;
    if ( ! -e $r1_chip_reads || $force_redo) {
	$cmd = join(" ", ($script, $rm_barcode, $r1_chip_reads, @r1_chip));
	mprint("will run $cmd", 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    } else {
	mprint("uniformed input for rep1 ChIP already exists: $r1_chip_reads", 1); 
    }
    if ( ! -e $r1_input_reads || $force_redo) {
	$cmd = join(" ", ($script, $rm_barcode, $r1_input_reads, @r1_input));
	mprint("will run $cmd", 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    } else {
	mprint("uniformed input for rep1 control already exists: $r1_input_reads", 1);
    }
    if (scalar @r2_chip) {
	if ( ! -e $r2_chip_reads && $force_redo) {
	    $cmd = join(" ", ($script, $rm_barcode, $r2_chip_reads, @r2_chip));
	    mprint("will run $cmd", 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
	    mprint("uniformed input for rep2 ChIP already exists: $r2_chip_reads", 1);
	}
    }
    if (scalar @r2_input) {
	if ( ! -e $r2_input_reads && $force_redo) {
	    $cmd = join(" ", ($script, $rm_barcode, $r2_input_reads, @r2_input));
	    mprint("will run $cmd", 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
            mprint("uniformed input for rep2 control already exists: $r2_input_reads", 1);
        }
    }
}

sub run_bowtie {
    my ($cfg) = @_;
    tie my %ini, 'Config::IniFiles', (-file => $cfg);
    my $bowtie_bin = $ini{BOWTIE}{bowtie_bin};
    $bowtie_bin .= '/' unless $bowtie_bin =~ /\/$/;
    $bowtie_bin .= 'bowtie';
    die "bowtie binary $bowtie_bin not executable.\n" unless -x $bowtie_bin;
    my $bowtie_indexes = $ini{BOWTIE}{"bowtie_indexes_$org"};
    my $force_redo = $ini{BOWTIE}{force_redo};
    my $parameter = $ini{BOWTIE}{parameter};
    my $cmd;
    if ( ! -e $r1_chip_alignment || $force_redo ) {
	$cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, $r1_chip_reads, $r1_chip_alignment));
	mprint("will run $cmd", 1);
	#system($cmd) == 0 || die "error occured when run $cmd\n";
    } else {
	mprint("rep1 ChIP aligned already! $r1_chip_alignment", 1);
    }
    if (scalar @r2_chip) {
	if ( ! -e $r2_chip_alignment || $force_redo ) { 
	    $cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, $r2_chip_reads, $r2_chip_alignment));
	    mprint("will run $cmd", 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
	    mprint("rep2 ChIP aligned already! $r2_chip_alignment", 1);
	}
	if ( ! -e $chip_alignment || $force_redo ) {
	    $cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, join(",", ($r1_chip_reads, $r2_chip_reads)), $chip_alignment));
	    mprint("will run $cmd", 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
	    mprint("Pooled ChIP aligned already! $chip_alignment", 1);
	}
    }
    if ( ! -e $r1_input_alignment || $force_redo ) {
	$cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, $r1_input_reads, $r1_input_alignment));
	mprint("will run $cmd", 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    } else {
	mprint("rep1 input aligned already! $r1_input_alignment", 1);
    }
    if (scalar @r2_input) {
	if (! -e $r2_input_alignment || $force_redo ) {
	    $cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, $r2_input_reads, $r2_input_alignment));
	    mprint("will run $cmd", 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
	    mprint("rep2 input aligned already! $r2_input_alignment", 1);
	}
	if ( ! -e $input_alignment || $force_redo ) {
	    $cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, join(",", ($r1_input_reads, $r2_input_reads)), $input_alignment));
	    mprint("will run $cmd", 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
	    mprint("Pooled input aligned already! $input_alignment", 1);
	}
    }
}

sub run_peakranger {#accept a hashref argument
    my $arg = shift;
    die "need cfg to run peakranger.\n" unless exists $arg->{cfg};
    tie my %ini, 'Config::IniFiles', (-file => $arg->{cfg});
    my $script = $ini{PEAKRANGER}{script};
    die "peakranger binary $script does not exist.\n" unless -e $script;
    my $force_redo = $ini{PEAKRANGER}{force_redo};
    my $parameter = $ini{PEAKRANGER}{parameter};

    if (scalar keys %$arg == 1) {#only cfg
	my $prefix = $out_dir . 'peakranger/' ; mkdir($prefix) unless -e $prefix;
	my $r1_prefix = $prefix . $name . '_r1';
	my $r2_prefix = $prefix . $name . '_r2';
	my $pool_prefix = $prefix . $name . '_pool';
	my $cmd;
	if ( ! -e $r1_peak || $force_redo ) {
	    $cmd = "$script -d $r1_chip_alignment -c $r1_input_alignment -o $r1_prefix $parameter"; #r1_peak is prefix
	    mprint("will run $cmd", 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	    mprint("transform rep1 peak to narrowPeak format", 1);
	    peakranger2narrowPeak($r1_prefix, $r1_peak); 
	} else {
	    mprint("peak already called for rep1: $r1_peak", 1);
	}
	if (scalar @r2_chip && scalar @r2_input) {
	    if ( ! (-e $r2_peak && -e $peak) || $force_redo ) {
		$cmd = "$script -d $r2_chip_alignment -c $r2_input_alignment -o $r2_prefix $parameter";
		mprint("will run $cmd", 1);
		system($cmd) == 0 || die "error occured when run $cmd\n";
		mprint("transform rep2 peak to narrowPeak format", 1);
		peakranger2narrowPeak($r2_prefix, $r2_peak);
		$cmd = "$script -d $chip_alignment -c $input_alignment -o $pool_prefix $parameter";
		mprint("will run $cmd", 1);
		system($cmd) == 0 || die "error occured when run $cmd\n";
		mprint("transform pool peak to narrowPeak format", 1);
		peakranger2narrowPeak($pool_prefix, $peak);
	    } else {
		mprint("peak already called for rep2 and pooled: $r2_peak $peak", 1);
	    }	    
	}
	$done_peakcall = 1;
    }
    else {#other arguments, custom run
	$now = localtime;
	delete $arg->{cfg};
	my $dent = $arg->{dent} and delete $arg->{dent} if exists $arg->{dent};
	my $custom_peak = $arg->{peak} and delete $arg->{peak} if exists $arg->{peak};
	my $force_redo = $arg->{force_redo} and delete $arg->{force_redo} if exists $arg->{force_redo};
	mprint("peak already called: $custom_peak", $dent) and return $custom_peak if -e $custom_peak && ! $force_redo;
	die "need to specify options d/c/o to run peakranger.\n" unless exists $arg->{d} && exists $arg->{c} && exists $arg->{o};
	my $par = join(" ", ('-d', $arg->{d}, '-c', $arg->{c}, '-o', $arg->{o}, __change_parameter('peakranger', $parameter, $arg)));
	my $cmd = "$script $par --nowig";
	mprint("fdr cutoff set as $arg->{p} !!!", $dent || 1);
	mprint("will run $cmd", $dent || 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
	mprint("transform into narrowPeak format with log p/q values", $dent || 1);
	peakranger2narrowPeak($arg->{o}, $custom_peak, 1) and return $custom_peak if defined($custom_peak);
    }
}

sub run_idr {
    my ($cfg) = @_;
    tie my %ini, 'Config::IniFiles', (-file => $cfg);
    my $rscript = $ini{IDR}{'Rscript'};
    my $code_dir = $ini{IDR}{'code-dir'};
    my $analysis = $ini{IDR}{'batch-consistency-analysis'};
    my $plot = $ini{IDR}{'batch-consistency-plot'};
    my $force_redo = $ini{IDR}{force_redo};
    my $idr_cut_ori = $ini{IDR}{'idr-ori'};
    my $idr_cut_self = $ini{IDR}{'idr-self'};
    my $idr_cut_pseudo = $ini{IDR}{'idr-pseudo'};
    my $genome_table = $ini{IDR}{"genome-table-$org"};

    mprint("idr uses the following cutoff: ", 1);
    mprint("original replicate threshold: $idr_cut_ori", 2);
    mprint("self-consistency threshold: $idr_cut_self", 2);
    mprint("pooled-pseudoreplicate threshold: $idr_cut_pseudo", 2);
    die "genome table $genome_table not exists\n" unless -e $genome_table;

    my @samples; my @o_prefiz; my @peak_name_prefiz; my @set;
    my $idr_dir = $out_dir . "idr/" ; mkdir($idr_dir) unless -e $idr_dir;

    #s1_c0
    push @set, 'rep1 vs merged control';
    my $o_prefix = $idr_dir . $name . '_s1_c0';
    my $peak_name_prefix = $name . '_s1_c0';
    push @samples, $r1_chip_alignment;
    push @o_prefiz, $o_prefix;
    push @peak_name_prefiz, $peak_name_prefix;
    
    #s2_c0
    push @set, 'rep2 vs merged control';
    $o_prefix = $idr_dir . $name . '_s2_c0';
    $peak_name_prefix = $name . '_s2_c0';
    push @samples, $r2_chip_alignment;
    push @o_prefiz, $o_prefix;
    push @peak_name_prefiz, $peak_name_prefix;

    #s0_c0
    push @set,'merged rep vs merged control';
    $o_prefix = $idr_dir . $name . '_s0_c0';
    $peak_name_prefix = $name . '_s0_c0';
    push @samples, $chip_alignment;
    push @o_prefiz, $o_prefix;
    push @peak_name_prefiz, $peak_name_prefix;
    
    #s1p1_c0 and s1p2_c0
    push @set, 'pseudo rep1 part1 vs merged control';
    push @set, 'pseudo rep1 part2 vs merged control';
    my $r1p1_chip_alignment = $alignment_dir . $name . '_r1p1_chip.sam';
    my $r1p2_chip_alignment = $alignment_dir . $name . '_r1p2_chip.sam';
    shuffle_split($r1_chip_alignment, $r1p1_chip_alignment, $r1p2_chip_alignment) if ( ! (-e $r1p1_chip_alignment && -e $r1p2_chip_alignment) || $force_redo );
    push @samples, $r1p1_chip_alignment;
    push @samples, $r1p2_chip_alignment;
    $o_prefix = $idr_dir . $name . '_s1p1_c0';
    $peak_name_prefix = $name . '_s1p1_c0';
    push @o_prefiz, $o_prefix;
    push @peak_name_prefiz, $peak_name_prefix;
    $o_prefix = $idr_dir . $name . '_s1p2_c0';
    $peak_name_prefix = $name . '_s1p2_c0';
    push @o_prefiz, $o_prefix;
    push @peak_name_prefiz, $peak_name_prefix;
    

    #s2p1_c0 and s2p2_c0
    push @set, 'pseudo rep2 part1 vs merged control';
    push @set, 'pseudo rep2 part2 vs merged control';
    my $r2p1_chip_alignment = $alignment_dir . $name . '_r2p1_chip.sam';
    my $r2p2_chip_alignment = $alignment_dir . $name . '_r2p2_chip.sam';
    shuffle_split($r2_chip_alignment, $r2p1_chip_alignment, $r2p2_chip_alignment) if ( ! (-e $r2p1_chip_alignment && -e $r2p2_chip_alignment) || $force_redo );
    push @samples, $r2p1_chip_alignment;
    push @samples, $r2p2_chip_alignment;
    $o_prefix = $idr_dir . $name . '_s2p1_c0';
    $peak_name_prefix = $name . '_s2p1_c0';
    push @o_prefiz, $o_prefix;
    push @peak_name_prefiz, $peak_name_prefix;
    $o_prefix = $idr_dir . $name . '_s2p2_c0';
    $peak_name_prefix = $name . '_s2p2_c0';
    push @o_prefiz, $o_prefix;
    push @peak_name_prefiz, $peak_name_prefix;

    #s0p1_c0 and s0p2_c0
    push @set, 'pseudo merged-rep part1 vs merged control';
    push @set, 'pseudo merged-rep part2 vs merged control';
    my $p1_chip_alignment = $alignment_dir . $name . '_p1_chip.sam';
    my $p2_chip_alignment = $alignment_dir . $name . '_p2_chip.sam';
    shuffle_split($chip_alignment, $p1_chip_alignment, $p2_chip_alignment) if ( ! (-e $p1_chip_alignment && -e $p2_chip_alignment) || $force_redo );
    push @samples, $p1_chip_alignment;
    push @samples, $p2_chip_alignment;
    $o_prefix = $idr_dir . $name . '_p1_c0';
    $peak_name_prefix = $name . '_p1_c0';
    push @o_prefiz, $o_prefix;
    push @peak_name_prefiz, $peak_name_prefix;
    $o_prefix = $idr_dir . $name . '_p2_c0';
    $peak_name_prefix = $name . '_p2_c0';
    push @o_prefiz, $o_prefix;
    push @peak_name_prefiz, $peak_name_prefix;

    #map {print "$_\n"} @samples;
    #map {print "$_\n"} @o_prefiz;

    map { mkdir($_) unless -e $_ } @o_prefiz;

    my $peakcall = $ini{PEAK}{script};
    my $rank_measure = $ini{PEAK}{rank_measure};
    my $cfg;
    my @peaks;

    if ( $peakcall eq 'peakranger' ) {
	$cfg = $cfg_dir . 'peakranger.ini';
	my $p = $ini{PEAK}{fdr};
     
	#run all peakcalls needed for idr
	for my $i (0..8) {
	    $now = localtime;
	    mprint("peak call on $set[$i]...$now", 1);
	    my $o_dir = $o_prefiz[$i] . '/peakranger/'; mkdir($o_dir) unless -e $o_dir; 
	    my $idr_peak = $o_prefiz[$i] . "/" . $peak_name_prefiz[$i] . '.bed'; 
	    my $o = $o_dir . $peak_name_prefiz[$i];
	    $idr_peak = run_peakranger({cfg => $cfg,
					dent => 2,
					force_redo => $force_redo,
					peak => $idr_peak,
					d => $samples[$i],
					c => $input_alignment,
					o => $o,
					p => $p,
				       });
	    push @peaks, $idr_peak;
	    $now = localtime;
	    mprint("done $now", 1);
	}
    }
    
    #run idr on pairs
    # change working dir to idrcode locates, 
    chdir($code_dir);
    die "$analysis not excutable\n" unless -x $analysis;
    die "$plot not excutable\n" unless -x $plot;
    my $cmd;
    #s1_c0/s2_c0
    my $idr_ori = $idr_dir . $name . "_s1_c0_vs_s2_c0/"; mkdir($idr_ori) unless -e $idr_ori;
    my $idr_ori_prefix = $idr_ori . $name . "_s1_c0_vs_s2_c0";
    mprint("check pairwise consistency by idr on pair s1_c0 vs s2_c0", 1);
    if ( ! -e $idr_ori_prefix . '-Rout.txt' || $force_redo ) {
	$cmd = "$rscript $analysis $peaks[0] $peaks[1] -1 $idr_ori_prefix 0 F $rank_measure $genome_table";
	mprint("will run $cmd", 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    }
    if ( ! -e $idr_ori_prefix . '-plot.ps' || $force_redo ) {
	$cmd = "$rscript $plot 1 $idr_ori_prefix $idr_ori_prefix";
	mprint("will run $cmd", 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    }
    #s1p1_c0/s1p2_c0
    my $idr_self_r1 = $idr_dir . $name . "_s1p1_c0_vs_s1p2_c0/"; mkdir($idr_self_r1) unless -e $idr_self_r1;
    my $idr_self_r1_prefix = $idr_self_r1 . $name . "_s1p1_c0_vs_s1p2_c0";
    mprint("check self consistency of rep1 by idr on pair s1p1_c0 vs s1p2_c0", 1);
    if ( ! -e $idr_self_r1_prefix . '-Rout.txt' || $force_redo ) {
	$cmd = "$rscript $analysis $peaks[3] $peaks[4] -1 $idr_self_r1_prefix 0 F $rank_measure $genome_table";
	mprint("will run $cmd", 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    }
    if ( ! -e $idr_self_r1_prefix . '-plot.ps' || $force_redo ) {
	$cmd = "$rscript $plot 1 $idr_self_r1_prefix $idr_self_r1_prefix";
	mprint("will run $cmd", 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    }
    #s2p1_c0/s2p2_c0
    my $idr_self_r2 = $idr_dir . $name . "_s2p1_c0_vs_s2p2_c0/"; mkdir($idr_self_r2) unless -e $idr_self_r2;
    my $idr_self_r2_prefix = $idr_self_r2 . $name . "_s2p1_c0_vs_s2p2_c0";
    mprint("check self consistency of rep2 by idr on pair s2p1_c0 vs s2p2_c0", 1);
    if ( ! -e $idr_self_r2_prefix . '-Rout.txt' || $force_redo ) {
        $cmd = "$rscript $analysis $peaks[5] $peaks[6] -1 $idr_self_r2_prefix 0 F $rank_measure $genome_table";
	mprint($cmd, 1);
        system($cmd) == 0 || die "error occured when run $cmd\n";
    }
    if ( ! -e $idr_self_r2_prefix . '-plot.ps' || $force_redo ) {
        $cmd = "$rscript $plot 1 $idr_self_r2_prefix $idr_self_r2_prefix";
        mprint($cmd, 1);
        system($cmd) == 0 || die "error occured when run $cmd\n";
    }
    #s0p1_c0/s0p2_c0
    my $idr_pseudo = $idr_dir . $name . "_s0p1_c0_vs_s0p2_c0/"; mkdir($idr_pseudo) unless -e $idr_pseudo;
    my $idr_pseudo_prefix = $idr_pseudo . $name . "_s0p1_c0_vs_s0p2_c0";
    mprint("check pseudo consistency of merged by idr on s0p1_c0 vs s0p2_c0", 1);
    if ( ! -e $idr_pseudo_prefix . '-Rout.txt' || $force_redo ) {
	$cmd = "$rscript $analysis $peaks[7] $peaks[8] -1 $idr_pseudo_prefix 0 F $rank_measure $genome_table";
	mprint($cmd, 1);
        system($cmd) == 0 || die "error occured when run $cmd\n";
    }
    if ( ! -e $idr_pseudo_prefix . '-plot.ps' || $force_redo ) {
        $cmd = "$rscript $plot 1 $idr_pseudo_prefix $idr_pseudo_prefix";
        mprint($cmd, 1);
        system($cmd) == 0 || die "error occured when run $cmd\n";
    }
    #change working dir back to my root (code) dir.
    chdir($root_dir);

    #final peaks, alway force_redo 
    my $overlap_peaks_ori = $idr_ori_prefix . '-overlapped-peaks.txt';
    my $np_r1_r2 = `awk '\$11 <= $idr_cut_ori {print \$0}' $overlap_peaks_ori |wc -l`; chomp $np_r1_r2;
    mprint("number of peaks passed pairwise idr threshold is $np_r1_r2", 1); 
    my $overlap_peaks_self_r1 = $idr_self_r1_prefix . '-overlapped-peaks.txt';
    my $np_r1_pr = `awk '\$11 <= $idr_cut_self {print \$0}' $overlap_peaks_self_r1 |wc -l`; chomp $np_r1_pr;
    mprint("number of peaks passed rep1 self idr threshold is $np_r1_pr", 1);
    my $overlap_peaks_self_r2 = $idr_self_r2_prefix . '-overlapped-peaks.txt';
    my $np_r2_pr = `awk '\$11 <= $idr_cut_self {print \$0}' $overlap_peaks_self_r2 |wc -l`; chomp $np_r2_pr;
    mprint("number of peaks passed rep2 self idr threshold is $np_r2_pr", 1);
    my $overlap_peaks_pseudo = $idr_pseudo_prefix . '-overlapped-peaks.txt';
    my $np_r0 = `awk '\$11 <= $idr_cut_pseudo {print \$0}' $overlap_peaks_pseudo |wc -l`; chomp $np_r0;
    mprint("number of peaks passed rep2 merge pseudo threshold is $np_r0", 1);
    my $conservative_peaks = $idr_dir . $name . '_conservative-peaks.bed';
    my $optimal_peaks = $idr_dir . $name . '_optimal-peaks.bed';
    mprint("final $np_r1_r2 conservative peaks called by idr are in file $conservative_peaks", 1);
    my $opt_cut = $np_r1_r2 > $np_r0 ? $np_r1_r2 : $np_r0 ;
    mprint("final $opt_cut optimal peaks called by idr are in file $optimal_peaks", 1);
    if ($rank_measure eq 'q.value') {
	`sort -k9nr,9nr $overlap_peaks_pseudo | head -n $np_r1_r2 > $conservative_peaks`;
	`sort -k9nr,9nr $overlap_peaks_pseudo | head -n $opt_cut > $optimal_peaks`;
    }
}

sub __change_parameter {
    my ($algo, $par, $arg) = @_;
    my $new_par = '';
    if ($algo eq 'peakranger') {
	my ($format, $t, $p, $l, $r, $b, $mode);
	GetOptionsFromString($par, 
			     'format:s' => \$format,
			     't:i' => \$t,
			     'p:s' => \$p,
			     'l:i' => \$l,
			     'r:s' => \$r, #delibrate str instead of float
			     'b:i' => \$b,
			     'mode:s' => \$mode
	    );
	my %opt = ('--format=' => $format,
		   '-t '       => $t,
		   '-p '       => $p,
		   '-l '       => $l,
		   '-r '       => $r,
		   '-b '       => $b,
		   '--mode='   => $mode,
	    );
	my %arg2opt = ('format' => '--format=',
		       "t" => '-t ',
		       "p" => '-p ',
		       "l" => '-l ',
		       "r" => '-r ',
		       "b" => '-b ',
		       "mode" => '--mode=',
	    );
	map { $opt{$arg2opt{$_}} = $arg->{$_} if exists $arg2opt{$_} } keys %$arg;
	map { $new_par .= " $_"; $new_par .= $opt{$_}; } keys %opt;
	return $new_par;
    }
}

sub peakranger2narrowPeak {
    my ($prefix, $out, $lg) = @_;
    my $in1 = $prefix . '_peaks_with_region.bed';
    my $in2 = $prefix . '_regions';
    $out .= '.bed' unless $out =~ /\.bed$/;
    open my $in1h, "<", $in1 || die "cannot open $in1\n";
    open my $in2h, "<", $in2 || die "cannot open $in2\n";
    open my $outh, ">", $out || die "cannot open $out\n";
    my $enrich = {[]};
    <$in2h>;
    while (<$in2h>) {
	chomp;
	my @fld = split /\t/;
	my $rgn = join('-', ($fld[0], $fld[1], $fld[2]));
	$enrich->{$rgn} = [$fld[3], $fld[4], $fld[5]];
    }
    while (<$in1h>) {
	chomp;
	my @fld = split /\t/;
	my $rgn = join('-', ($fld[0], $fld[1], $fld[2]));
	my $sample_tags = $enrich->{$rgn}->[0];
	my $control_tags = $enrich->{$rgn}->[1];    
	my $name = join('-', ('peakranger', $fld[0], $fld[1], $fld[2], $sample_tags, $control_tags));
	if (defined($lg) && $lg == 1) {
	    if ($fld[4] != 0 && $fld[5] != 0) {
		$fld[4] = -log($fld[4])/log(10);
		$fld[5] = -log($fld[5])/log(10);
	    } else { #min subnormal positive double is about 10^-324 
		$fld[4] = 323;
		$fld[5] = 323;
	    }
	}
	print $outh join("\t", ($fld[0], $fld[1], $fld[2], $name, 0, '.', $enrich->{$rgn}->[2], $fld[4], $fld[5], $fld[3])), "\n";
    }
    close $in1h;
    close $in2h;
    close $outh;
}

sub shuffle_split {
    my ($sam, $p1, $p2) = @_;
    mprint("shuffle and split $sam into $p1 and $p2", 1);
    my ($name, $dir, $suffix) = fileparse($sam, ".sam");
    my $prefix = $dir . $name;

    my @sam_head = `head -n 40 $sam`;
    my $num_head = scalar grep {/^@/} @sam_head;
    my $nlines = `wc -l $sam`; $nlines = int(($nlines-$num_head+1)/2);

    if ($num_head) {
	`grep -v @ $sam | shuf | split -d -l $nlines - $prefix`;
    } else {
	`shuf $sam| split -d -l $nlines - $prefix` ;
    }
    my $tp1 = $prefix . '00'; my $tp2 = $prefix . '01'; 
    `mv $tp1 $p1`; `mv $tp2 $p2`;
}
