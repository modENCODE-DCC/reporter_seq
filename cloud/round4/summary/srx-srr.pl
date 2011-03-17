#!/usr/bin/perl
use URI;
use Net::FTP;
 
my $url = "ftp://ftp-trace.ncbi.nih.gov/sra/sra-instant/reads/ByExp/sra/SRX/SRX012/SRX012965";
my $uri = URI->new($url);
my ($scheme, $host, $path) = ($uri->scheme, $uri->host, $uri->path);
my $ftp = Net::FTP->new($host) or die "Cannot connect to, $@";
$ftp->login();

for my $srr (@{$ftp->ls($path)}) {
    $ftp->cwd($srr);
    map {print $scheme, "://", $host, $srr, "/", $_, "\n"} @{$ftp->ls()};
}

