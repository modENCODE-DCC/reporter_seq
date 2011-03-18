#!/usr/bin/perl
use URI;
use Net::FTP;
 
my $file = $ARGV[0]; #sra_mapping.csv
my $url = "ftp://ftp-trace.ncbi.nih.gov/sra/sra-instant/reads/ByExp/sra/SRX/";
my $uri = URI->new($url);
my ($scheme, $host, $path) = ($uri->scheme, $uri->host, $uri->path);
my $ftp = Net::FTP->new($host) or die "Cannot connect to, $@";
$ftp->login();
for my $dir (@{$ftp->ls($path)}) {#dir == SRXxxx
    for my $srx (@{$ftp->ls($dir)}) {#srx == SRXxxxxxx
	for my $srr (@{$ftp->ls($srx)}) {
	    my $full_srr_path = $scheme . "://" . $host . "/". $srr;
	    print join("\t", ($srx, $srr, $full_srr_path)), "\n";
	}
    }
}


