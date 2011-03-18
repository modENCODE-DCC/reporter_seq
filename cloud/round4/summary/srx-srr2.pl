#!/usr/bin/perl
use URI;
use Net::FTP;
 
my $file = $ARGV[0]; #sra_mapping.csv
my $host = 'ftp-trace.ncbi.nih.gov';
#my $ftp = Net::FTP->new($host) or die "Cannot connect to, $@";
#$ftp->login();
open my $fh, "<", $file || die;
while(my $line = <$fh>) {
    chomp $line;
    my ($id, $sra) = split /\t/, $line;
    my $url;
    if ($sra =~ /^SRX/) {
	$f = substr($sra, 0, 6);
	$url = "ftp://ftp-trace.ncbi.nih.gov/sra/sra-instant/reads/ByExp/sra/SRX/" . $f  . '/' . $sra;
    } elsif ($sra =~ /^SRR/) {

    }
    print $url, "\n";
#    my $uri = URI->new($url);
#    my ($scheme, $newhost, $path) = ($uri->scheme, $uri->host, $uri->path);
#    if ($newhost ne $host) {
#	$host = $newhost;
#	$ftp = Net::FTP->new($newhost) or die "Cannot connect to, $@";
#	$ftp->login();
#    }
#    for my $srr (@{$ftp->ls($path)}) {
#	$ftp->cwd($srr);
#	map {print $fld[0], " ", $fld[1], " ", $scheme, "://", $host, $srr, "/", $_, "\n"} @{$ftp->ls()};
#    }
}

