#!/usr/bin/perl
#take a group of files in commandline or from configure file
#cp sim link, unzips and removes barcode as necessary and concats them
#modified from code of Brad Arshinoff

use strict;
use Getopt::Long qw[GetOptions];
use File::Basename qw[fileparse];
use Archive::Extract;
$Archive::Extract::WARN = 0;
#use Misc;

my $rm_barcode = 0;
my $dent = 0;
#default, fast select a num of short reads in fastq file to determine barcode
my $sampling = 'fast';
my $option = GetOptions ("rm_barcode:i" => \$rm_barcode,
			 "sampling:s" => \$sampling,
			 "dent:i" => \$dent);
#otherwise, use Knuth reservoir sampling algo, much much slower
$sampling = 'random' unless lc($sampling) eq 'fast';

my ($out, @in) = @ARGV;
my $out_dir = (fileparse($out))[1];
my $ori_dir = $out_dir; $ori_dir =~ s/uniform/origin/;
my @want;
my @tmp;
foreach my $inf (@in) {
    my $fn = (fileparse($inf))[0]; #original file
    my $t = $ori_dir . $fn; #copy file
    unless (-e $t) {
	if (-l $inf) { #symlink
	    mprint("$inf is a symbolic link. copying...", $dent);
	    system("cp -L $inf $t");
	    mprint("done", $dent);
	} else {
	    mprint("$inf is an ordinary file. copying...", $dent);
	    system("cp $inf $t");
	    mprint("done", $dent);
	}
    } else {
	mprint("$t already exists!", $dent);
    }
    
    my $ae;
    eval {$ae = Archive::Extract->new(archive => $t)};
    if ( !$@ && defined($ae)) {#a zipped file
	mprint("$t is a zipped file. unzipping...", $dent);
	$ae->extract(to => $ori_dir) || die "failed to extract $t.\n";
	die "multiple files found in $t.\n" if scalar @{$ae->files} != 1;
	push @tmp, $t;
	$t = $ori_dir . $ae->files->[0]; #the unzipped file
	die "can not found just extracted $t\n" unless -e $t;
	mprint("done. the new unzipped file is $t", $dent);
    }

    if ($rm_barcode) {
	mprint("checking $t for a barcode...", $dent);
	$t = remove_barcode($t, $sampling);
	mprint("done", $dent);
    }

    push @want, $t if defined($t);
}

#catenate files and cleanup tmp files  
if (scalar @want == 1) {
    system("mv $want[0] $out") == 0 || die "cannot move files \n";
    system(join(" ", ("rm", @tmp)));
} else {
    system(join(" ", ("cat", @want, "> $out"))) == 0 || die "cannot cat files \n";  
    system(join(" ", ("rm", (@want, @tmp))));
}


sub mprint {
    my ($msg, $dent) = @_;
    my $default_dent = "    ";
    print $default_dent x $dent;
    print $msg . "\n";
}

sub remove_barcode {
    my ($file, $method) = @_;
    my $barcode = determine_barcode($file, $method);
    if ($barcode eq "INVALID") {
	mprint("file being ignored...", $dent);
	return undef;
    }
    if ( length($barcode) == 0 ) {
	mprint("file does not appear to contain a barcode...", $dent);
	return $file;
    }
    if ($method eq 'fast' && length($barcode) <= 2 ) {
	mprint("WARNING!!! many short reads might start with the same nucleotide(s) $barcode...", $dent);
	return $file;
    }

    mprint("The following barcode was found and will be stripped from file: $barcode", $dent);
    my $outfile = $file . '.barcode-removed';
    open( my $IN, "<", $file ) || die "cannot open $file for input $!";
    open( my $OUT, ">", $outfile ) || die "cannot open $outfile for output $!";
    my $check_next      = 0;
    my $barcode_count   = 0;
    my $nobarcode_count = 0;
    my $barcode_endpos  = length($barcode);
    my $badquality_barcode =0;
    my $qual_next = 0;
    my $barcode_removed = 0;
    while ( my $line = <$IN> ) {
	chomp $line;
	if ( $check_next == 1 && $line =~ /^[ACGTN]*$/) {
	    $check_next=0;
	    if ( $line =~ /^$barcode/ ) {
		$line = substr( $line, $barcode_endpos );
		$barcode_count++;
		$barcode_removed = 1;
	    } 
	    else {
		my $non_matches=0;
		mprint("Barcode $barcode not found in $line", $dent);
		for (my $i=0; $i<=$barcode_endpos; $i++) {
		    $non_matches++ if substr( $line, $i, 1 ) ne substr($barcode, $i, 1);
		}
		if ($non_matches <=1) {
		    $badquality_barcode++;
		    $line = substr( $line, $barcode_endpos );
		    $barcode_removed = 1;
		} 
		else {
		    $nobarcode_count++;
		}
	    } #endo of $line !~ /^$barcode/
	} #end of check_next == 1
	elsif ($qual_next == 1) {
	    $qual_next = 0;
	    if ($barcode_removed == 1) {
		$barcode_removed = 0;
		$line = substr($line, $barcode_endpos);
	    }
	}
	else {
	    $check_next = ( $line =~ /^@/ ) ? 1 : 0; 
	    $qual_next = ( $line =~ /^\+/ ) ? 1 : 0;
	}
	print $OUT ($line . "\n");
    } #end of while
    close $OUT;
    close $IN;
    mprint("Barcode removal complete: #sequence with barcode= $barcode_count, #sequences without= $nobarcode_count, #of sequences with bad quality barcodes= $badquality_barcode...", $dent);
    if ( $nobarcode_count == 0 && $barcode_count > 0 ) {
	push @tmp, $file;
	return $outfile;
    }        
    elsif ( $nobarcode_count > 0 ) {
	if ( ( ( $barcode_count / ($barcode_count +$nobarcode_count) ) < 0.2 ) ) {
	    my $str = "WARNING: something weird has occured here, barcodes were found in  " . ( $barcode_count / ($barcode_count +$nobarcode_count) ). "% of sequences";
	    mprint($str, $dent);
	    return $file;
	}
    }
}

sub fast_select {
    my $filename = shift;
    open( my $IN, "<", $filename )
	|| die "cannot open $filename to check for barcode $!";

    my $check_next   = 0;
    my $lineschecked = 0;
    my @lines;
    while ( my $line = <$IN> ) {
        last if $lineschecked >= 20000;
	chomp $line;

        if ( $check_next == 1 && $line =~ /^[ACGTN]*$/) {
            $check_next = 0;
            push( @lines, $line );
        }
        else {
            $check_next = ( $line =~ /^@/ ) ? 1 : 0;
        }
        $lineschecked++;
    }

    close $IN;

    return \@lines;
}

sub random_select {
    my ($filename, $num) = @_;
    open( my $IN, "<", $filename )
        || die "cannot open $filename to check for barcode $!";

    my @selected;
    my $numselected = 0;
    my $check_next = 0;
    while ( my $line = <$IN> ) {
	chomp $line;
	
	if ( $check_next == 1 && $line =~ /^[ACGTN]*$/) {
            $check_next = 0;
	    $numselected++;
	    if ($numselected > $num) {
		my $r = int(rand($numselected));
		if ( $r < $numselected ) {
		    $selected[$r] = $line;
		}
	    }
	    else {
		push @selected, $line;
	    }
	}
	else {
	    $check_next = ( $line =~ /^@/ ) ? 1 : 0;
	}
    }
    
    close $IN;

    return \@selected;
}

sub determine_barcode {
    #random selection, Knuth algorithm R3.4.2 implemented in random_select method, much much slower.
    my ($filename, $method) = @_;
    $method = (defined($method) && $method ne '' && lc($method) ne 'fast') ? 'random' : 'fast';
    my $lines = [];
    open( my $IN, "<", $filename )
	|| die "cannot open $filename to check for barcode $!";
    
    $lines = fast_select($filename);

    if ( scalar(@$lines) < 10 ) {
	my $str = "file contains " . scalar(@$lines) . " sequences. It does not meet minimum size requirement of 10 sequences and will be skipped\n";
	mprint($str, $dent);
	return "INVALID";
    }

    if ($method eq 'random') {
        $lines = random_select($filename, scalar @$lines);
    }

    #if it exists but we can't find it with three tries then read quality is so bad it probably isn't worth analyzing anyway
    my $bc = __test_forbarcode( 0, $lines );
    if ( $bc eq "" ) {
	$bc = __test_forbarcode( 10, $lines );
    }
    if ( $bc eq "" ) {
	$bc = __test_forbarcode( 100, $lines );
    }
    
    return $bc;
}

sub __test_forbarcode {
    my ( $testindex, $array ) = @_;
    my $match   = 0;
    my $nomatch = 0;
    my $barcode = "";
    my $lastbarcode;
    my $charno = 0;
    do {
	$lastbarcode = $barcode;
	my $char = substr( $array->[$testindex], $charno, 1 );
	my $consistent = 1;
	foreach my $line (@$array) {
	    if ( substr( $line, $charno, 1 ) eq $char ) {
                                $match++;
				
	    }
	    else {
		$nomatch++;
	    }
	}
	if ( $match / ( $nomatch + $match ) > 0.95  && $char ne "N") {
	    $barcode .= $char;
	}
	$charno++;
    } while ( length($barcode) != length($lastbarcode) );
    return $barcode;
}

