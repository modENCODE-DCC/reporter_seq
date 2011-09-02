#!/usr/bin/perl
#this program will try to find the real path of datafiles, update spreadsheet and migrate to WS220
use strict;
use File::Basename qw[fileparse];
use File::Find;

open my $ws190, "<", "/modencode/modencode-dcc/staging/update-worm-to-ws220/ws190/ws190-spreadsheet.csv" || die $!;
open my $ws220, ">", "/modencode/modencode-dcc/staging/update-worm-to-ws220/ws220/ws220-spreadsheet.csv" || die $!;
#open my $err, "<", "/modencode/modencode-dcc/staging/update-worm-to-ws220/id-err2.txt" || die "cannot open id-err2.txt: $!";
#my @err_ids;
#while(<$err>) {
#    chomp;
#    next if $_ =~ /^\s*$/;
#    $_ =~ s/^\s*//g; $_ =~ s/\s*$//g;
#    print $_, "\n";
#    push @err_ids, $_;
#}
#these are the file formats that a genome build migration need to take care.                          
#alignment_sam                                                                                        
#computed-peaks_gff3                                                                                  
#coverage-graph_wiggle                                                                                
#gene-model_gff3                                                                                      
#normalized-arrayfile_wiggle                                                                          
my %des = ('alignment_sam'               => '/modencode/modencode-dcc/staging/update-worm-to-ws220/ws220/sam/', 
	   'computed-peaks_gff3'         => '/modencode/modencode-dcc/staging/update-worm-to-ws220/ws220/gff3/',
	   'coverage-graph_wiggle'       => '/modencode/modencode-dcc/staging/update-worm-to-ws220/ws220/wiggle/',
	   'gene-model_gff3'             => '/modencode/modencode-dcc/staging/update-worm-to-ws220/ws220/gff3/',
	   'normalized-arrayfile_wiggle' => '/modencode/modencode-dcc/staging/update-worm-to-ws220/ws220/wiggle/'
    );
my @formats = keys %des;
map {mkdir $_ unless -e $_} (values %des); 

#these are other formats of files that could be found in pipeline
my @array_formats= qw[raw-arrayfile-agilent_txt
                      raw-arrayfile_CEL
                      raw-arrayfile_pair];

#these are formats ignored right now
my @ignored_formats = qw[GEO_record];

#these are raw-seq formats need special treatment
my @seq_formats = qw[raw-seqfile_fastq]; 

#deal with header line
my $header = <$ws190>;
print $ws220 $header;
chomp $header;
my $i = 0;
my @flds = split /\t/, $header;
for my $x (@flds) {
#    print join(" ", ($i, $x, "\n"));
    $i++;
}

my $id_now = 1000000;
my @lifted_now;
while(my $line = <$ws190>) {
    chomp $line;
    my @flds = split /\t/, $line;
    my @extra = ();
    #simple replace Cele_WS190 with Cele_WS220    
    #at column organism, build, uniform filename, extensional uniform filename  
    $flds[4] =~ s/Cele_WS190/Cele_WS220/;
    $flds[14] =~ s/Cele_WS190/Cele_WS220/;
    $flds[16] =~ s/Cele_WS190/Cele_WS220/;
    $flds[17] =~ s/Cele_WS190/Cele_WS220/;
    
    #chado_path is the relative (to submission package) path of datafile taken from chado db
    my ($id, $fmt, $chado_path, $org) = ($flds[0], $flds[7], $flds[3], $flds[4]);

#    if (scalar grep { $_ eq $fmt } @ignored_formats) {
#	next;
#    }

    if ($org =~ /^Cele/) {
	#next unless scalar grep {$_==$id} @err_ids;
	if (scalar grep { $_ eq $fmt } @formats) {
	    #for each id, only do the following once
	    if ($id != $id_now) {
		@lifted_now = get_lifted_files($id);
		$id_now = $id;
	    }

	    if (scalar @lifted_now > 0) {
		my $path = find_in_pipeline($id_now, $chado_path, \@lifted_now);
		if ($path ne 'not found') {
		    my $from = "/modencode/raw/data/$id/extracted/" . $path;
		    my $to = des_name($id, $fmt, $from);
		    #print "from $from \n";
		    #print "to $to \n";
		    if ( -e $from ) {
			mcopy($from, $to);
			@extra = ($from, $to);
			print "success! submission $id data $chado_path\n";
		    } else {
			print "weird happened, cannot find in pipeline $from\n"; 
		    }
		} else { # file not in the lift record
		    print "submission $id has lift record but data $chado_path is not in it, might not been lifted, trust Ellen, direct copy\n";
		    $chado_path =~ s/([Ww][Ss])\d{3}/${1}220/;
		    my $found = 0;
		    find(sub {
			if ($_ eq $chado_path) {
			    my $from = $File::Find::name;
			    my $to = des_name($id, $fmt, $from);
			    mcopy($from, $to);
			    @extra = ($from, $to);
			    $found = 1;
			}
			 }, "/modencode/raw/data/$id/extracted/");
		    if ($found == 0) {
			print "could not find submission $id data $chado_path\n";
		    }
		}
	    } else { # no lift record
		print "submission $id does not have lift record, trust Ellen, direct copy\n";
		$chado_path =~ s/([Ww][Ss])\d{3}/${1}220/;
		my $found =0;
		find(sub {
		    if ($_ eq $chado_path) {
			my $from = $File::Find::name;
			my $to = des_name($id, $fmt, $from);
			mcopy($from, $to);
			@extra = ($from, $to);
			$found = 1;
		    }
		     }, "/modencode/raw/data/$id/extracted/");
		if ($found == 0) {
		    print "could not find submission $id data $chado_path\n";
		}
	    }
	}
	elsif (scalar grep { $_ eq $fmt } @seq_formats) {
	}
    }
    if (scalar @extra ) {
	print $ws220 join("\t", (@flds, @extra)), "\n";
    } else {
	print $ws220 join("\t", @flds), "\n";
    }
}
close $ws190;
close $ws220;

sub des_name {
    my ($id, $fmt, $from) = @_;
    my ($name, $dir, $suffix) = fileparse($from);
    my $to = $des{$fmt} . $id . "_" . $name . $suffix;
    return $to;
}

sub mcopy {
    my ($from, $to) = @_;
    $from =~ s/\(/\\(/g; $to =~ s/\(/\\(/g;
    $from =~ s/\)/\\)/g; $to =~ s/\)/\\)/g;
    system("cp $from $to") == 0 || print "err when copy $from to $to\n";
}

sub get_lifted_files {
    my $id = shift;
    my @lifted = ();
    my $dir = "/modencode/raw/data/$id/";
    opendir(my $dh, $dir) || die "can not open dir $dir: $!";
    my @rec =  grep { /lifted_ws220/ } readdir($dh);
    closedir($dh);
    if (scalar @rec >= 1) {
	my $f = $dir . $rec[0];
	@lifted = `tar tzf $f`;
	@lifted = map {chomp; $_} @lifted;
    }
    return @lifted;
}

sub find_in_pipeline {
    my ($id, $chado_path, $lifted) = @_;
    #print "$id $chado_path\n";
    $chado_path =~ s/([Ww][Ss])\d{3}/${1}220/;
    $chado_path = lc($chado_path);
    print "modified chado path is $chado_path\n";
    for my $x (@$lifted) {
	my $t = lc($x);
	return $x if substr($t, -length($chado_path)) eq $chado_path;
    }
    return 'not found';
}
