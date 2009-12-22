#!/usr/bin/perl

use strict;

my $root_dir;
BEGIN {
  $root_dir = $0;
  $root_dir =~ s/[^\/]*$//;
  $root_dir = "./" unless $root_dir =~ /\//;
  push @INC, $root_dir;
}

use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Cookies;
use File::Basename;
use File::Copy;
use File::Spec;
use Net::FTP;
use Mail::Mailer;
use Config::IniFiles;
use Getopt::Long;
use Digest::MD5;
use ModENCODE::Parser::LWChado;
use GEO::Reporter;

print "initializing...\n";

#parse command-line parameters
my ($unique_id, $output_dir, $config);
#default config
$config = $root_dir . 'chado2GEO.ini';
my $use_existent_metafile = 0; 
my $make_tarball = 0;
my $use_existent_tarball = 0;
my $send_to_geo = 0;
my $long_protocol_text = 0;
my $option = GetOptions ("unique_id=s"     => \$unique_id,
			 "out=s"           => \$output_dir,
			 "config=s"        => \$config,
			 "long_protocol_text=s" => \$long_protocol_text,
			 "use_existent_metafile=s" => \$use_existent_metafile,
			 "make_tarball=s"  => \$make_tarball,
			 "use_existent_tarball=s"  => \$use_existent_tarball,   
			 "send_to_geo=s"   => \$send_to_geo) or usage();
usage() if (!$unique_id or !$output_dir);
usage() unless -w $output_dir;
usage() unless -e $config;

#get config
my %ini;
tie %ini, 'Config::IniFiles', (-file => $config);

#report directory
my $report_dir = File::Spec->rel2abs($output_dir);
#make sure $report_dir ends with '/'
$report_dir .= '/' unless $report_dir =~ /\/$/;
#build the uniquename for this dataset
my $unique_name = 'modencode_' . $unique_id;

my ($seriesfile, $samplefile, $file_datafilenames, $metafile);
$seriesfile = $report_dir . $unique_name . '_series.txt';
$samplefile = $report_dir . $unique_name . '_sample.txt';
$file_datafilenames = $report_dir . $unique_name . '_datafilenames.txt';
$metafile = $unique_name . '.soft';

if (($use_existent_metafile == 0) && ($use_existent_tarball == 0)) {
    #what is the database for this dataset? 
#    my $dbname = $ini{database}{dbname};
#    my $dbhost = $ini{database}{host};
#    my $dbusername = $ini{database}{username};
#    my $dbpassword = $ini{database}{password};
#    #search path for this dataset, this is fixed by modencode chado db
#    my $schema = $ini{database}{pathprefix}. $unique_id . $ini{database}{pathsuffix} . ',' . $ini{database}{schema};
    my $dbname = 'modencode_2542';
    my $dbhost = 'localhost';
    my $dbusername = 'zheng';
    my $dbpassword = 'weigaocn';
    my $schema = 'public';

    #start read chado
    print "connecting to database ...";
    my $reader = new ModENCODE::Parser::Chado({
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
    print "done.\n";

    open my $seriesFH, ">", $seriesfile;
    open my $sampleFH, ">", $samplefile;
    open my $file_datafilenamesFH, ">", $file_datafilenames;    
    my $reporter = new GEO::Reporter({
        'config' => \%ini,
        'unique_id' => $unique_id,
        'sampleFH' => $sampleFH,
        'seriesFH' => $seriesFH,
        'report_dir' => $report_dir,
        'reader' => $reader,
        'experiment' => $experiment,
	'long_protocol_text' => $long_protocol_text,
    });
    $reporter->get_all();

    print "generating GEO series file ...";
    $reporter->chado2series();
    print "done.\n";
    print "generating GEO sample file ...";
    my ($raw_datafiles, $normalized_datafiles, $more_datafiles) = $reporter->chado2sample();
    my @nr_raw_datafiles = nr(@$raw_datafiles);
    my @nr_normalized_datafiles = nr(@$raw_datafiles);
    my @rd_datafiles = (@$raw_datafiles, @$normalized_datafiles, @$more_datafiles);
    my @datafiles = nr(@rd_datafiles);
    for my $datafile (@datafiles) {
	print $file_datafilenamesFH $datafile, "\n";
    }
    chdir $report_dir;
    my $file1 = basename($seriesfile);
    my $file2 = basename($samplefile);
    close $sampleFH;
    close $seriesFH;
    close $file_datafilenamesFH;
    system("cat $file1 $file2 > $metafile") == 0 || die "can not catenate series and sample files to make soft file: $?";    
    system("rm $file1 $file2") == 0 || die "can not remove the series and sample files: $?";
    print "done\n";
}

my $tarfile = $unique_name . '.tar';
my $tarballfile = $unique_name . '.tar.gz';
my $tarball_made = 0;
if (($make_tarball == 1) && ($use_existent_tarball == 0)) {
    print "making tarball for GEO submission ...\n";
    #make a tar ball at report_dir for all datafiles
    chdir $report_dir;
    system("tar cf $tarfile $metafile") == 0 || die "can not tar the GEO soft file: $?";
    system("rm $metafile") == 0 || die "can not remove GEO soft file: $?";

    print "   downloading tarball provided by pipeline ...";
    my $url = $ini{tarball}{url};
    $url .= '/' unless $url =~ /\/$/;
    $url .= $unique_id . $ini{tarball}{condition};
    my $allfile = 'extracted.tgz';
    my @allfilenames;
    #download flattened tarball of submission
    open my $allfh, ">" , $allfile;
    my $ua = new LWP::UserAgent;
    my $request = $ua->request(HTTP::Request->new('GET' => $url));
    $request->is_success or die "$url: " . $request->message;
    print $allfh $request->content();
    close $allfh;
    print "done.\n";
    #peek into tarball to list all filenames
    @allfilenames = split(/\n/, `tar tzf "$allfile"`);
    
    my @datafiles;
    open my $file_datafilenamesFH, "<", $file_datafilenames;
    while (<$file_datafilenamesFH>) {
	chomp;
	push @datafiles, $_;
    }
    close $file_datafilenames;
    system("rm $file_datafilenames") == 0 || die "can not remove file $file_datafilenames.";

    for my $datafile (@datafiles) {
	if ($datafile =~ /\.fastq/) {
	    my $request = $ua->request(HTTP::Request->new('GET' => $datafile));
	    $request->is_success or die "$url: " . $request->message;
	    my ($tmpfh, $tmpfile) = File::Temp::tempfile();
	    print $tmpfh $request->content();
	    system("tar -r --remove-files -f $tarfile $tmpfile") == 0 || die "can not append a datafile $datafile from download to my tarball $tarfile and then remove it (leave no garbage).";
	} 
	else {
	#remove subdirectory prefix, remove suffix of compression, such as .zip, .bz2, this is the filename goes into geo tarball
	my $myfile = unzipp(basename($datafile));

	#replace / with _ , use it to match the filenames in downloaded tarball
	$datafile =~ s/\//_/g;	
	my $chars = 0 - length($datafile);
	my $filename_in_tarball;
	for my $filename (@allfilenames) {
	    # the filenames in pipeline provided tarball are of pattern extracted_maindirectory_subdirectory_datafilename(_compression_suffix),
	    # the filenames in chado are of pattern subdirectory_datafilenames(_compression_suffix) 
	    $filename_in_tarball = $filename and last if substr($filename, $chars) eq $datafile;
	}
	system("tar xzf $allfile $filename_in_tarball") == 0 || die "can not extract a datafile $filename_in_tarball from download tarball $allfile";
	#if it is compressed ......right now only allows one level of compression
	#if it is multiple levels of compression, GEO will still get compressed files in tarball, they will complain and we will fix.
	my $zipsuffix = iszip($filename_in_tarball);
	if ($zipsuffix) {
	    #unzip and remove the original compressed file
	    my $filename_no_zip = do_unzip($filename_in_tarball, $zipsuffix);
	    system("mv $filename_no_zip $myfile") == 0 || die "can not change filename $filename_no_zip to $myfile";
	} else {
	    system("mv $filename_in_tarball $myfile") == 0 || die "can not change filename $filename_in_tarball to $myfile";
	}
	system("tar -r --remove-files -f $tarfile $myfile") == 0 || die "can not append a datafile $filename_in_tarball from download tarball $allfile to my tarball $tarfile and then remove it (leave no garbage).";
	}
    }
    system("rm $tarballfile 2>&1 > /dev/null") if -e $tarballfile; # Remove the gzip if it already exists; ignore output
    system("gzip $tarfile") == 0 || die "cannot gzip the tar file $tarfile";
    system("rm $allfile") == 0 || die "can not remove file $allfile";
    $tarball_made = 1;
    print "tarball made.\n";
}

if (($tarball_made || $use_existent_tarball) && $send_to_geo) {
    #use ftp to send file to geo ftp site
    chdir $report_dir;
    die "can not find tarball $tarballfile" unless -r $tarballfile;
    my $md5 = Digest::MD5->new;
    open my $tarballfh, "<", $tarballfile;
    binmode $tarballfh;
    $md5->addfile($tarballfh);
    my $digest = $md5->hexdigest;
    print "beginning to send tarball to GEO ...\n";
    my $ftp_host = $ini{ftp}{host};
    my $ftp_username = $ini{ftp}{username};
    my $ftp_password = $ini{ftp}{password};
    my $ftp = Net::FTP->new($ftp_host);
    my $success = $ftp->login($ftp_username, $ftp_password);
    die $ftp->message unless $success;
    my $success1 = $ftp->cwd($ini{ftp}{dir});
    die "FTP error changing to directory: " . $ftp->message unless $success1;
    $ftp->binary;
    my $success2 = $ftp->put($tarballfile);
    die "FTP error uploading tarball: " . $ftp->message unless $success2;
    my $now_string = localtime;
    #send geo a email
    my $mailer = Mail::Mailer->new;
    my $submitter = $ini{submitter}{submitter};
    $mailer->open({
	From => $ini{email}{from},
	To   => $ini{email}{to},
	CC   => $ini{email}{cc},
	Subject => 'ftp upload',
		  });
    print $mailer "userid: $submitter\n";
    print $mailer "file: $tarballfile\n";
    print $mailer "modencode DCC ID for this submission: $unique_id\n";
    print $mailer "md5sum for this tarball is $digest\n";
    print $mailer "sent successfully at $now_string\n";
    print $mailer "Best Regards, modencode DCC\n";
    $mailer->close or die "couldn't send email to GEO: $!";
    print "file upload and email sent to GEO!\n";
    # Don't remove tarball after uploading...
    my @rm = ("rm $tarballfile");
    system(@rm) == 0 || die "can not remove file $tarballfile";   
}

exit 0;

sub nr {
    my @files = @_;
    my @nr_files = ();
    for my $file (@files) {
	my $already_in = 0;
	for my $nr_file (@nr_files) {
	    $already_in = 1 and last if $file eq $nr_file;
	}
	push @nr_files, $file unless $already_in;
    }
    return @nr_files;
}

sub iszip {
    my $path = shift;
    return 'gz' if $path =~ /\.gz$/ ;
    return 'bz2' if $path =~ /\.bz2$/ ;
    return 'zip' if $path =~ /\.zip$/;
    return 'zip' if $path =~ /\.ZIP$/;
    return 'z' if $path =~ /\.Z$/;
    return 0;
}

sub do_unzip {
    my ($zipfile, $zipsuffix) = @_;
    my $char = length($zipfile);
    my $filename_no_zip;
    if ($zipsuffix eq 'bz2') {
	$filename_no_zip = substr($zipfile, 0, $char-4);
	system("bzip2 -d -f $zipfile") == 0 || die "can not bunzip file $zipfile";
    }
    return $filename_no_zip;
}


sub unzipp {
    my $path = shift; #this is already a basename
    $path =~ s/\.tgz$//;
    $path =~ s/\.tar\.gz$//;    
    $path =~ s/\.tar$//;
    $path =~ s/\.gz$//;    
    $path =~ s/\.bz2$//;
    $path =~ s/\.zip$//;
    $path =~ s/\.ZIP$//;
    $path =~ s/\.Z$//;
    return $path;
}

sub usage {
    my $usage = qq[$0 -unique_id <unique_submission_id> -out <output_dir> [-config <config_file>] [-use_existent_metafile <0|1>] [-make_tarball <0|1>] [-use_existent_tarball <0|1>] [-send_to_geo <0|1>] [-long_protocol_text <0|1>]];
    print "Usage: $usage\n";
    print "example 1, generate soft file but no tarball, $0 -unique_id id -out dir \n";
    print "example 2, generate tarball using existent soft file, $0 -unique_id id -out dir -use_existent_metafile 1 -make_tarball 1 \n";
    print "example 3, use existent tarball to send to geo, $0 -unique_id id -out dir -use_existent_tarball 1 -send_to_geo 1 \n";
    print "required parameters: unique_id, out\n";
    print "optional parameter: config, for customized config file, the default one is chado2GEO.ini in this directory.\n";
    print "optional parameter: use_existent_metafile, set to 1 if you already made GEO soft file and want to use it to make_tarball or send to geo. the file must exist in the output_dir and its name must be modencode_id.soft. another file named modencode_id_datafilenames.txt which contains all the data filenames must also exist in the output_dir. the script could then use these filenames to extract files in the tarball provided by pipeline.\n";
    print "optional yet helpful parameter: make_tarball, default is 0 for NOT archiving any raw/normalized data.\n";
    print "optional yet helpful parameter: use_existent_tarball, default is 0. set to 1 if you have already made a tarball and want to use it to send to geo. the tarball must exist in the output_dir and its name must be modencode_id.tar.gz\n";
    print "optional yet important parameter: send_to_geo, default is 0 for NOT sending crappy results to geo. must set both make_tarball and send_to_geo to 1 for sending submission to geo happen.\n";
    print "optional parameter: long_protocol_text, default 0 for using protocol wiki dbfield short description for protocol text, 1 for using protocol wiki text itself, this is an experimental feature since the code does a screen scrap/massage of wiki html, the wiki database is not open yet.\n";
    exit 2;
}
