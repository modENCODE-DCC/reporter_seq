#!/usr/bin/perl
#take a group of files in commandline or from configure file
#cp sim link, unzips and removes barcode as necessary and concats them
#modified from code by Brad Arshinoff
use strict;
use Getopt::Long;
use Config::IniFiles;  
use use File::Basename qw/fileparse/;
use Archive::Extract;
my ($cfg, $outdir, $tmp); #$tmp, 1 for write out tmp final file, 0 for permanent file  
my $option = GetOptions ("cfg:s" => \$cfg,
                         "o=s" => \$outdir,
                         "t" => \$tmp);
print STDERR "output dir $outdir not writable.\n" and usage() unless -w $outdir;

my $ini; my @ini_chip; my @ini_input; my @in= @ARGV;
if ($cfg) {
    unless (-e $cfg) {
        print STDERR "configure file $cfg does not exist.\n" and usage();
    } else {
        $ini = Config::IniFiles->new(-file => $cfg, -allowcontinue => 1);
        @ini_chip = $ini->val('INPUT_FILES', 'ChIP');  
        @ini_input = $ini->val('INPUT_FILES', 'Input');
        print STDERR "it is not wise to input files from both command-line arguments and configure file.\n" and usage() if scalar @in && (scalar @ini_chip || scalar @ini_input);
    }
}

my $out;
if (scalar @in) {
    $out = create_filename($outdir, $tmp, 'cmdln');
    prepare_files(\@in, $outdir, $out);
}
if (scalar @ini_chip) {
    $out = create_filename($outdir, $tmp, 'chip', $cfg);
    prepare_files(\@ini_chip, $outdir, $out);
}
if (scalar @ini_input) {
    $out = create_filename($outdir, $tmp, 'input', $cfg);
    prepare_files(\@ini_input, $outdir, $out);
}

sub prepare_files {
    my ($rawfiles, $outdir, $finalfile) = @_;
    my @catfiles; my @tmpfiles;
    foreach my $rawfile (@$rawfiles) {
        my ($filename, $dir) = fileparse($rawfile);
        if ( -l $rawfile ) {#symlink
            my $tmpfile = "$outdir/$filename";
            unless (-e $tmpfile) {
                system("cp -L $rawfile $tmpfile");
            }
            push @tmpfiles, $tmpfile;
            $rawfile = $tmpfile;
        }
    }
}
