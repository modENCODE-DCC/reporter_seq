#!/usr/bin/perl
use strict;
use constant PARENT_DIR => '/glusterfs/zheng/fastq-replica-v2/';
use constant CFG_DIR => '/glusterfs/zheng/cfg/';

my $cfg_dir; my @tf_dirs; my %taxa;
if (scalar @ARGV == 0) {
    $cfg_dir = CFG_DIR;
    for my $pi ('snyder', 'white', 'macalpine') {
	my $dir = PARENT_DIR . $pi . '/';
	opendir my $dh, $dir || die "cannot open dir $dir \n";
	my @dirs = map {$dir . $_ . '/'} grep {!/^\./} readdir($dh);
	my $org = $pi eq 'snyder' ? 'worm' : 'fly';
	for my $t (@dirs) {
	    $taxa{$t} = $org;
	}
   	push @tf_dirs, @dirs;
    }
}
elsif (scalar @ARGV >= 3) {
    %taxa = reverse $ARGV[0, -1];
    @tf_dirs = keys %taxa;
    $cfg_dir = $ARGV[-1];
}
else {
    usage();
}
mkdir($cfg_dir) unless -d $cfg_dir;
#map {print $_, "\n"} @tf_dirs; #right

foreach my $tf (@tf_dirs) {
    opendir my $dh, $tf || die"cannot open dir $tf \n";
    my @stages = map {$tf . $_ . '/'} grep {!/^\./} readdir($dh);
    for my $stage (@stages) {
	#print "###$stage\n"; #right
	opendir my $dh, $stage || die "cannot open dir $stage \n";
	my (@chips, @inputs, @pol2s);
	my ($chips_dir_ready, $inputs_dir_ready, $pol2s_dir_ready) = (1,1,1);

      
	my @t = split "/", $tf; my $x = $t[-1];
	my @t = split "/", $stage; my $y = $t[-1];
	my $z = $taxa{$tf};
	my $name = join('_', ($z, $x, $y));
	my $pol2_name = $name . '_pol2';

	foreach (readdir($dh)) {
	    /^anti/ && push @chips, $stage . $_ . '/';
	    /^input/ && push @inputs, $stage . $_ . '/';
	    /pol2/ && !/^anti/ && push @pol2s, $stage . $_ . '/';
	}
	
	print "exactly 1 ChIP dir expected for $stage\n" and $chips_dir_ready = 0 if scalar @chips != 1;
	print "exactly 1 input dir expected for $stage\n" and $inputs_dir_ready = 0 if scalar @inputs != 1;
	print "exactly 1 pol2 dir expected for $stage\n" and $pol2s_dir_ready = 0 if scalar @pol2s > 0 && scalar @pol2s != 1;

      
	###check whether input dir exists as of 13 Sep 2011#################################
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/cbp/E0-4/                #
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/cbp/E16-20/              #
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/cbp/E20-24/              #
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/E4-8/            #
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/E0-4/           #
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/E12-16/         #
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/E20-24/         # 
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/L2/             #
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/pol2/E12-16/             #
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/pol2/E20-24/             #
        #no input dir for /glusterfs/zheng/fastq-replica-v2/white/pol2/E8-12/              #
        ####output##########################################################################

	if ($chips_dir_ready && $inputs_dir_ready && $pol2s_dir_ready) {
	    my (@chip_reps_dir, @input_reps_dir, @pol2_reps_dir);
	    opendir my $dh, $chips[0] || die "cannot open dir $chips[0] \n";
	    @chip_reps_dir = map {$chips[0] . $_ . '/'} grep {!/^\./} readdir($dh);
	    opendir my $dh, $inputs[0] || die "cannot open dir $inputs[0] \n";
	    @input_reps_dir = map {$inputs[0] . $_ . '/'} grep {!/^\./} readdir($dh);
	    if (scalar @pol2s == 1) {
		opendir my $dh, $pol2s[0] || die "cannot open dir $pol2s[0] \n";
		@pol2_reps_dir = map {$pol2s[0] . $_ . '/'} grep {!/^\./} readdir($dh);
	    }

	    #map {print $_, "\n"} @chip_reps_dir;
	    #map {print $_, "\n"} @input_reps_dir;
	    #map {print $_, "\n"} @pol2_reps_dir if scalar @pol2_reps_dir;
		
	    #if ( scalar @chip_reps_dir == 1 ) {
		#print "#only 1 rep for $chips[0] #\n";
	    #}

	    #check for #replicates = 1, could do self-idr??########################################## 
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/caudal/AdultFemale/anti-caudal/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/caudal/E4-8/anti-caudal/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/cbp/AdultFemale/anti-cbp/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/cbp/AdultMale/anti-cbp/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/cbp/E12-16/anti-cbp/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/cbp/E4-8/anti-cbp/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/cbp/E8-12/anti-cbp/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/cbp/L1/anti-cbp/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/cbp/L3/anti-cbp/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/cbp/Pupae/anti-cbp/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/AdultFemale/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/AdultMale/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/E0-4/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/E12-16/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/E16-20/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/E20-24/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/E8-12/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/L1/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/L2/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/L3/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27ac/Pupae/anti-h3k27ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/AdultMale/anti-h3k27me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/E16-20/anti-h3k27me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/E4-8/anti-h3k27me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/E8-12/anti-h3k27me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/L1/anti-h3k27me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/L3/anti-h3k27me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k27me3/Pupae/anti-h3k27me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/AdultFemale/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/AdultMale/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/E0-4/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/E12-16/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/E16-20/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/E20-24/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/E4-8/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/E8-12/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/L1/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/L2/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/L3/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me1/Pupae/anti-h3k4me1/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/AdultFemale/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/AdultMale/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/E0-4/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/E12-16/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/E16-20/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/E20-24/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/E4-8/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/E8-12/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/L1/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/L2/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/L3/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k4me3/Pupae/anti-h3k4me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/AdultFemale/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/AdultMale/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/E0-4/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/E12-16/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/E16-20/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/E20-24/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/E4-8/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/E8-12/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/L1/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/L2/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/L3/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9ac/Pupae/anti-h3k9ac/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9me3/E0-4/anti-h3k9me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9me3/E12-16/anti-h3k9me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9me3/E16-20/anti-h3k9me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9me3/E20-24/anti-h3k9me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9me3/E4-8/anti-h3k9me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9me3/E8-12/anti-h3k9me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9me3/L1/anti-h3k9me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9me3/L2/anti-h3k9me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/h3k9me3/Pupae/anti-h3k9me3/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/pol2/E4-8/anti-PolII/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/pol2/L1/anti-PolII/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/pol2/L3/anti-PolII/ #
            #only 1 rep for /glusterfs/zheng/fastq-replica-v2/white/pol2/Pupae/anti-PolII/ #
	    #######################################################################################

	    if (scalar @input_reps_dir > 1) {
		die "#ChIP and #input donot match\n" unless scalar @chip_reps_dir == scalar @input_reps_dir;
		if (scalar @pol2_reps_dir) {
		    die "#pol2 and #input donot match\n" unless scalar @pol2_reps_dir == scalar @input_reps_dir;
		}
	    }

	    gen_cfgfile(\@chip_reps_dir, \@input_reps_dir, $name);
	    gen_cfgfile(\@pol2_reps_dir, \@input_reps_dir, $pol2_name) if scalar @pol2_reps_dir;
	}
    }
}     

sub usage {
    my $usage = qq[$0 [<worm|fly> <DIR_to_TF1> <worm|fly> <DIR_to_TF2> ... <DIR_to_CFG>]];
    print "Usage: $usage\n";
    print "please follow directory structure of DIR_to_TF--->SUBDIR_to_DevStage--->SUBDIR_to_ChIP/input/pol2--->SUBDIR_to_rep1/2--->files\n";
    exit 1;
}

sub gen_cfgfile {
    my ($sdirs, $cdirs, $name) = @_;
    my $cfg = CFG_DIR . $name . '_pipeline.ini';
    if (-e $cfg) {
	my $bak = $cfg . '.bak';
	`mv $cfg $bak`;
	print "Warning! a same name configure file exists $cfg, moved the original one to $bak\n";
    }
    open my $cfgh, ">", $cfg || die "cannot open $cfg: $!";
    print $cfgh <<"CFG";
[PIPELINE]
run_preprocess = 1
run_alignment = 1
run_peak_calling = 1
run_postprocess = 1
	
[PREPROCESS]
run_remove_barcode = 1
	
[ALIGNMENT]
run_bowtie = 1

[PEAK_CALLING]
run_peakranger = 1

[POSTPROCESS]
run_idr = 1
    
[OUTPUT]
dir = /glusterfs/zheng/tmp/
log = /glusterfs/zheng/tmp/log/

[INPUT]
CFG

    my $num_reps = scalar @$sdirs;
    for my $i (1..$num_reps) {
	for my $j (0..$num_reps-1) {
	    my $sdir = $sdirs->[$j];
	    if ($sdir =~ /$i\/$/) {
		print $cfgh "r${i}_ChIP = ", get_raw($sdir), "\n";
	    }
	}
    }
    if (scalar @$cdirs == 1) {
	print $cfgh "share_input = ", get_raw($cdirs->[0]), "\n";
    } else { 
	for my $i (1..$num_reps) {
	    for my $j (0..$num_reps-1) {
		my $cdir = $cdirs->[$j];
		if ($cdir =~ /$i\/$/) {
		    print $cfgh "r${i}_input = ", get_raw($cdir), "\n";
		}
	    }
	}
    }
}

sub get_raw {
    my $dir = shift;
    opendir my $dh, $dir || die "cannot open dir $dir: $!";
    my @raw = map {$dir . $_} grep {!/^\./} readdir($dh);
    my $str = join(" ", @raw);
    return $str;
}
