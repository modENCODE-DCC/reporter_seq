#!/usr/bin/perl
use strict;

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
my $name;
#create cfg for each TF run to override the default
my $option = GetOptions ("cfg:s" => \$cfg,
			 "name=s" => \$name);
usage() unless -e $cfg;
usage() unless defined($name);
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
 
#uniform name/format of the input short read files
my $r1_chip_reads = $out_dir . $name . '_r1_chip.fastq';
my $r2_chip_reads = $out_dir . $name . '_r2_chip.fastq';
#my $chip_reads = $out_dir . $name . '_chip.fastq';
my $r1_input_reads = $out_dir . $name . '_r1_input.fastq';
my $r2_input_reads = $out_dir . $name . '_r2_input.fastq';
#my $input_reads = $out_dir . $name . '_input.fastq';
#uniform name/format of the alignment files;
my $r1_chip_alignment = $out_dir . $name . '_r1_chip.sam';
my $r2_chip_alignment = $out_dir . $name . '_r2_chip.sam';
my $chip_alignment = $out_dir . $name . '_chip.sam';
my $r1_input_alignment = $out_dir . $name . '_r1_input.sam';
my $r2_input_alignment = $out_dir . $name . '_r2_input.sam';
my $input_alignment = $out_dir . $name . '_input.sam';
#uniform name for peak files;
my $r1_peak = $out_dir . $name . '_r1_peak';
my $r2_peak = $out_dir . $name . '_r2_peak';
my $peak = $out_dir . $name . '_peak';

my $done_preprocess = 0;
if (defined($preprocess) && $preprocess == 1) {
    $now = localtime;
    mprint("preprocessing... $now", 0);
    unless (-e $r1_chip_reads && -e $r2_chip_reads && -e $r1_input_reads && -e $r2_input_reads) {
	my $remove_barcode = $ini{PREPROCESS}{run_remove_barcode};
	if (defined($remove_barcode) && $remove_barcode == 1) {
	    mprint("pipeline will do preprocess: remove barcode.", 1);
	    run_uniform_input({rm_barcode =>1, 
			       dent => 1});
	    $done_preprocess = 1;
	    $now = localtime;
	    mprint("done $now", 1);
	} else {
	    mprint("pipeline will do misc preprocess, such as unzip, etc.", 1);
	    run_uniform_input({dent => 1});
	    $done_preprocess = 1;
	    $now = localtime;
	    mprint("done $now", 1);
	}
    } else {
	$done_preprocess = 1;
	mprint("uniformed files already exists: $r1_chip_reads, $r1_input_reads, $r2_chip_reads, $r2_input_reads", 1);
    }
    mprint("preprocess done $now\n", 0);
}

my $done_align = 0;
if (defined($align) && $align == 1) {
    if (defined($preprocess) && $preprocess == 1) {
	die "preprocess not done yet\n" unless $done_preprocess == 1;
    }
    $now = localtime;
    mprint("aligning $now...", 0);
    my $run_bowtie = $ini{ALIGNMENT}{run_bowtie};
    if (defined($run_bowtie) && $run_bowtie == 1) {
	mprint("pipeline will do alignment: bowtie.", 1); #this shall put into bowtie module
	my $cfg = $cfg_dir . 'bowtie.ini';
	run_bowtie($cfg);
	$done_align = 1;
	$now = localtime;
	mprint("done $now", 0);
    }
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
}

if (defined($postprocess) && $postprocess == 1) {
    if (defined($peakcall) && $peakcall == 1) {
	die "peak calling not done yet\n" unless $done_peakcall == 1 ;
    }
    $now = localtime;
    mprint("postprocessing $now...", 0);
    my $run_idr = $ini{POSTPROCESS}{run_idr};
    if (defined($run_idr) && $run_idr == 1) {
	die "need rep2 files to do IDR.\n" unless scalar @r2_chip && scalar @r2_input; 
	mprint("pipeline will do postprocess: idr.", 1);
	my $cfg = $cfg_dir . 'idr.ini';
	#run_idr($cfg);
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
    my $usage = qq[$0 -name <name> [-cfg <cfg_file>]];
    print "Usage: $usage\n";
    exit 1;
}

sub run_uniform_input {
    my ($opt) = @_;
    #do copy if input are symlink
    #do unzip if input are zipped
    #cat multiple-lanes file into one lane file
    #remove barcode if necessary
    my $script = $root_dir . 'uniform_input.pl';
    die "$script does not exist.\n" unless -e $script;
    my $rm_barcode = "";
    $rm_barcode = '-rm_barcode 1' if defined($opt) && $opt->{rm_barcode} == 1;
    my $cmd = join(" ", ($script, $rm_barcode, $r1_chip_reads, @r1_chip));
    mprint(join(" ", ("will run ", $cmd)), 1);
    system($cmd) == 0 || die "error occured when run $cmd\n";
    $cmd = join(" ", ($script, $rm_barcode, $r1_input_reads, @r1_input));
    mprint(join(" ", ("will run ", $cmd)), 1);
    system($cmd) == 0 || die "error occured when run $cmd\n";
    if (scalar @r2_chip) {
	$cmd = join(" ", ($script, $rm_barcode, $r2_chip_reads, @r2_chip));
	mprint(join(" ", ("will run ", $cmd)), 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    }
    if (scalar @r2_input) {
        $cmd = join(" ", ($script, $rm_barcode, $r2_input_reads, @r2_input));
	mprint(join(" ", ("will run ", $cmd)), 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    }
}

sub run_bowtie {
    my ($cfg) = @_;
    tie my %ini, 'Config::IniFiles', (-file => $cfg);
    my $bowtie_bin = $ini{BOWTIE}{bowtie_bin};
    $bowtie_bin .= '/' unless $bowtie_bin =~ /\/$/;
    $bowtie_bin .= 'bowtie';
    die "bowtie binary $bowtie_bin not executable.\n" unless -x $bowtie_bin;
    my $bowtie_indexes = $ini{BOWTIE}{bowtie_indexes};
    my $parameter = $ini{BOWTIE}{parameter};
    my $cmd;
    unless (-e $r1_chip_alignment) {
	$cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, $r1_chip_reads, $r1_chip_alignment));
	mprint(join(" ", ("will run ", $cmd)), 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    } else {
	print "rep1 ChIP aligned already! $r1_chip_alignment\n";
    }
    if (scalar @r2_chip) {
	unless ( -e $r2_chip_alignment) { 
	    $cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, $r2_chip_reads, $r2_chip_alignment));
	    mprint(join(" ", ("will run ", $cmd)), 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
	    print "rep2 ChIP aligned already! $r2_chip_alignment\n";
	}
	unless (-e $chip_alignment) {
	    $cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, join(",", ($r1_chip_reads, $r2_chip_reads)), $chip_alignment));
	    mprint(join(" ", ("will run ", $cmd)), 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
	    print "Pooled ChIP aligned already! $chip_alignment\n";
	}
    }
    unless (-e $r1_input_alignment) {
	$cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, $r1_input_reads, $r1_input_alignment));
	mprint(join(" ", ("will run ", $cmd)), 1);
	system($cmd) == 0 || die "error occured when run $cmd\n";
    } else {
	print "rep1 input aligned already! $r1_input_alignment\n";
    }
    if (scalar @r2_input) {
	unless (-e $r2_input_alignment) {
	    $cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, $r2_input_reads, $r2_input_alignment));
	    mprint(join(" ", ("will run ", $cmd)), 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
	    print "rep2 input aligned already! $r2_input_alignment\n";
	}
	unless (-e $input_alignment) {
	    $cmd = join(" ", ($bowtie_bin, $parameter, $bowtie_indexes, join(",", ($r1_input_reads, $r2_input_reads)), $input_alignment));
	    mprint(join(" ", ("will run ", $cmd)), 1);
	    system($cmd) == 0 || die "error occured when run $cmd\n";
	} else {
	    print "Pooled input aligned already! $input_alignment\n";
	}
    }
}

sub run_peakranger {#accept a hashref argument
    my $arg = shift;
    die "need cfg to run peakranger.\n" unless exists $arg->{cfg};
    tie my %ini, 'Config::IniFiles', (-file => $arg->{cfg});
    my $script = $ini{PEAKRANGER}{script};
    die "peakranger binary $script does not exist.\n" unless -e $script;
    my $parameter = $ini{PEAKRANGER}{parameter};
    if (scalar keys %$arg == 1) {#only cfg
	print "$script -d $r1_chip_alignment -c $r1_input_alignment -o $r1_peak $parameter\n";
	#system("$script -d $r1_chip_alignment -c $r1_input_alignment -o $r1_peak $parameter");
	if (scalar @r2_chip && scalar @r2_input) {
	    print "$script -d $r2_chip_alignment -c $r2_input_alignment -o $r2_peak $parameter\n";
	    #system("$script -d $r2_chip_alignment -c $r2_input_alignment -o $r2_peak $parameter");
	    print "$script -d $chip_alignment -c $input_alignment -o $peak $parameter\n";
	    #system("$script -d $chip_alignment -c $input_alignment -o $peak $parameter");
	}
    }
    else {#other arguments,
	die "need to specify options d/c/o to run peakranger.\n" unless exists $arg->{d} && exists $arg->{c} && exists $arg->{o};
	my $par = __change_parameter('peakranger', $parameter, $arg);
	system("$script $par");
    }
}

sub run_idr {
    my ($cfg) = @_;
    tie my %ini, 'Config::IniFiles', (-file => $cfg);
    my $analysis = $ini{IDR}{'batch-consistency-analysis'};
    my $plot = $ini{IDR}{'batch-consistency-plot'};
    my $idr_cut_ori = $ini{IDR}{'idr-ori'};
    my $idr_cut_self = $ini{IDR}{'idr-self'};
    my $idr_cut_pseudo = $ini{IDR}{'idr-pseudo'};

    my @samples; my @o_prefiz;
    #s1_c0
    my $o_prefix = $out_dir . $name . '_s1_c0';
    push @samples, $r1_chip_alignment;
    push @o_prefiz, $o_prefix;
    
    #s2_c0
    $o_prefix = $out_dir . $name . '_s2_c0';
    push @samples, $r2_chip_alignment;
    push @o_prefiz, $o_prefix;

    #s0_c0
    $o_prefix = $out_dir . $name . '_s0_c0';	
    push @samples, $chip_alignment;
    push @o_prefiz, $o_prefix;
    
    #s1p1_c0 and s1p2_c0	
    my ($r1p1_chip_alignment, $r1p2_chip_alignment) = 
	shuffle_split($r1_chip_alignment);
    push @samples, $r1p1_chip_alignment;
    push @samples, $r1p2_chip_alignment;
    $o_prefix = $out_dir . $name . '_s1p1_c0';
    push @o_prefiz, $o_prefix;
    $o_prefix = $out_dir . $name . '_s1p2_c0';
    push @o_prefiz, $o_prefix;

    #s2p1_c0 and s2p2_c0	
    my ($r2p1_chip_alignment, $r2p2_chip_alignment) = 
	shuffle_split($r2_chip_alignment);
    push @samples, $r2p1_chip_alignment;
    push @samples, $r2p2_chip_alignment;
    $o_prefix = $out_dir . $name . '_s2p1_c0';
    push @o_prefiz, $o_prefix;
    $o_prefix = $out_dir . $name . '_s2p2_c0';
    push @o_prefiz, $o_prefix;

    #s0p1_c0 and s0p2_c0	
    my ($p1_chip_alignment, $p2_chip_alignment) = 
	shuffle_split($chip_alignment);
    push @samples, $p1_chip_alignment;
    push @samples, $p2_chip_alignment;
    $o_prefix = $out_dir . $name . '_p1_c0';
    push @o_prefiz, $o_prefix;
    $o_prefix = $out_dir . $name . '_p2_c0';
    push @o_prefiz, $o_prefix;

    my $peakcall = $ini{PEAK}{script};
    my $rank_measure = $ini{PEAK}{rank_measure};
    my $cfg;
    my @peaks;
    if ( $peakcall eq 'peakranger' ) {
	$cfg = $cfg_dir . 'peakranger.ini';
	my $p = $ini{PEAK}{pvalue};

	#run all peakcalls needed for idr
	for my $i (0..8) {
	    run_peakranger({cfg => $cfg,
			    d => $samples[$i],
			    c => $input_alignment,
			    o => $o_prefiz[$i],
			    p => $p});
	    push @peaks, $o_prefiz[$i] . "_peak_with_region.bed";
	}
	#transform *_peaks_with_region.bed (6 bed format) to 6+4 bed format
	#transform p/q values into -log10
    }
    
    #run idr on pairs
    #s1_c0/s2_c0
    my $idr_ori = $out_dir . $name . "_s1_c0_vs_s2_c0";
    system("$analysis $peaks[0] $peaks[1] -1 $idr_ori 0 F $rank_measure");
    system("$plot 1 $idr_ori $idr_ori");
    #s1p1_c0/s1p2_c0
    my $idr_self_r1 = $out_dir . $name . "s1p1_c0_vs_s1p2_c0";
    system("$analysis $peaks[3] $peaks[4] -1 $idr_self_r1 0 F $rank_measure");
    system("$plot 1 $idr_self_r1 $idr_self_r1");
    #s2p1_c0/s2p2_c0
    my $idr_self_r2 = $out_dir . $name . "s2p1_c0_vs_s2p2_c0";
    system("$analysis $peaks[5] $peaks[6] -1 $idr_self_r2 0 F $rank_measure");
    system("$plot 1 $idr_self_r2 $idr_self_r2");
    #s0p1_c0/s0p2_c0
    my $idr_pseudo = $out_dir . $name . "s0p1_c0_vs_s0p2_c0";
    system("$analysis $peaks[7] $peaks[8] -1 $idr_pseudo 0 F $rank_measure");
    system("$plot 1 $idr_pseudo $idr_pseudo");    

    #final peaks
    my $overlap_peaks_ori = $idr_ori . 'overlapped-peaks.txt';
    my $finalpeaks_ori = $idr_ori . 'final-peaks.txt';
    system("awk '$11 <= $idr_cut_ori {print $0}' $overlap_peaks_ori > $finalpeaks_ori");
    my $overlap_peaks_self_r1 = $idr_self_r1 . 'overlapped-peaks.txt';
    my $finalpeaks_r1 = $idr_self_r1 . 'final-peaks.txt';
    system("awk '$11 <= $idr_cut_self {print $0}' $overlap_peaks_self_r1 > $finalpeaks_r1");
    my $overlap_peaks_self_r2 = $idr_self_r2 . 'overlapped-peaks.txt';
    my $finalpeaks_r2 = $idr_self_r2 . 'final-peaks.txt';
    system("awk '$11 <= $idr_cut_self {print $0}' $overlap_peaks_self_r2 > $finalpeaks_r2");
    my $overlap_peaks_pseudo = $idr_pseudo . 'overlapped-peaks.txt';
    my $finalpeaks_pseudo = $idr_pseudo . 'final-peaks.txt';
    system("awk '$11 <= $idr_cut_pseudo {print $0}' $overlap_peaks_pseudo > $finalpeaks_pseudo"); 
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
		   '--mode='   => $mode
	    );
	my %arg2opt = ('format' => '--format=',
		       "t" => '-t ',
		       "p" => '-p ',
		       "l" => '-l ',
		       "r" => '-r ',
		       "b" => '-b ',
		       "mode" => '--mode='
	    );
	map {$opt{$arg2opt{$_}} = $arg->{$_}} keys %$arg;
	map { $new_par .= $_; $new_par .= $opt{$_}; } keys %opt;
	return $new_par;
    }
}

