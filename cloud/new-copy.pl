#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw/fileparse/;

#accept my spreadsheet as argument.
my $file = $ARGV[0];
#output a spreadsheet of id, chado path, real path
my $new_file = $file . ".correct_path";
#copy file to destination
my $des = "/modencode/modencode-dcc/data-0922/";

open my $fh, "<", $file || die;
open my $nfh, ">", $new_file || die;
<$fh>;
while(my $line = <$fh>) {
	chomp $line;
	my @fields = split /\t/, $line;
	my ($id, $chado_path) = ($fields[0], $fields[2]);
	#find the file first
	my $real_path = findit($id, $chado_path);
	if ( defined($real_path) ) {
	    print $nfh join("\t", ($id, $chado_path, $real_path)), "\n";
	    #now found, copy it
	    mycopy($id, $real_path);
	} else {
	    print $nfh join("\t", ($id, $chado_path, "not found")), "\n";
	}
}

sub mycopy {
    my ($id, $from) = @_;
    $from =~ s/\(/\\\(/g;
    $from =~ s/\)/\\\)/g;
    $from =~ s/ /\\ /g;
    my ($to, $path, $suffix) = fileparse($from);
    $to = $des . $id . "_" . $to;
    print "cp $from $to\n";
    system("cp $from $to") == 0 || print "copy error: cp $from $to\n";
}

sub findit {
    my ($id, $chado_path) = @_;
    my $dir = "/modencode/raw/data/" . $id . "/extracted/";
    my $real_path = _findit($dir, $chado_path);
#    print $real_path, "\n";
    return $real_path;
}

sub _findit {
    my ($dir, $file) = @_;
    my $path = $dir . $file;
    if ($dir !~ /ws180/i && $dir !~ /ws210/i) {
	if (-e $path) {
#	    print $path, "\n";
	    return $path;
	}
	else {
	    #is the filename changed due to worm lifting?
	    my $xpath = $file;
	    $xpath =~ s/[Ww][Ss]\d{3}/${1}220/;
	    if (-e $xpath) {
		return $xpath;
	    }
	    else {
	    #find it in subdir
		opendir(my $dh, $dir) || die "cannot open dir $dir: $!";
		my @subdirs = readdir $dh ;
		for my $subdir (@subdirs) {
		    next if $subdir =~ /^\./;
		    $subdir = $dir . $subdir;
		    if ( -d $subdir ) {
			$subdir .= '/' unless $subdir =~ /\/$/;
			return _findit($subdir, $file);
		    }
		}
		closedir($dh);
	    }
	}
    }
    return undef;
}
