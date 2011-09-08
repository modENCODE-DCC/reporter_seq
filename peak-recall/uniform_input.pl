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
my $option = GetOptions ("rm_barcode:i" => \$rm_barcode,
			 "dent:i" => \$dent);
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
	    print "$inf is a symbolic link. copying...";
	    system("cp -L $inf $t");
	    print "done\n";
	} else {
	    print "$inf is an ordinary file. copying...";
	    system("cp $inf $t");
	    print "done\n";
	}
    } else {
	print "$t already exists!\n";
    }
    
    my $ae;
    eval {$ae = Archive::Extract->new(archive => $t)};
    if ( !$@ && defined($ae)) {#a zipped file
	print "$t is a zipped file. unzipping...";
	$ae->extract(to => $ori_dir) || die "failed to extract $t.\n";
	die "multiple files found in $t.\n" if scalar @{$ae->files} != 1;
	push @tmp, $t;
	$t = $ori_dir . $ae->files->[0]; #the unzipped file
	die "can not found just extracted $t\n" unless -e $t;
	print "done. the new unzipped file is $t\n";
    }
    
    if ($rm_barcode) {
	print "checking $t for a barcode...\n";
	$t = remove_barcode($t);
    }

    push @want, $t;
}

#catenate files
system(join(" ", ("cat", @want, "> $out")));  

#cleanup files
#system(join(" ", ("rm", (@want, @tmp))));

sub remove_barcode {
    my ($file) = @_;
    my $barcode = determine_barcode($file);
    if ($barcode eq "INVALID") {
	print "file being ignored...\n";
    }
    if ( length($barcode) == 0 ) {
	print "file does not appear to contain a barcode...\n";
	return $file;
    }
    else {
	print "The following barcode was found and will be stripped from file: $barcode\n";
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
		    print "Barcode $barcode not found in $line\n";
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
	print "Barcode removal complete: #sequence with barcode= $barcode_count, #sequences without= $nobarcode_count, #of sequences with bad quality barcodes= $badquality_barcode...\n";
        if ( $nobarcode_count == 0 && $barcode_count > 0 ) {
	    push @tmp, $file;
	    return $outfile;
        }        
	elsif ( $nobarcode_count > 0 ) {
	    if ( ( ( $barcode_count / ($barcode_count +$nobarcode_count) ) < 0.2 ) ) {
		print "WARNING: something weird has occured here, barcodes were found in  " . ( $barcode_count / ($barcode_count +$nobarcode_count) ). "% of sequences\n";
		return $file;
	    }
	}
    } #end of length($barcode) != 0
}

sub determine_barcode {
    my $filename = shift;
    my @lines;
    open( my $IN, "<", $filename )
	|| die "cannot open $filename to check for barcode $!";
    my $check_next   = 0;
    my $lineschecked = 0;
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
    if ( scalar(@lines) < 10 ) {
	print "file contains " . scalar(@lines) . " sequences. It does not meet minimum size requirement of 10 sequences and will be skipped\n";
	return "INVALID";
    }

    #if it exists but we can't find it with three tries then read quality is so bad it probably isn't worth analyzing anyway
    my $bc = __test_forbarcode( 0, \@lines );
    if ( $bc eq "" ) {
	$bc = __test_forbarcode( 10, \@lines );
    }
    if ( $bc eq "" ) {
	$bc = __test_forbarcode( 100, \@lines );
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

