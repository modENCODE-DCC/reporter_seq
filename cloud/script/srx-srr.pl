#!/usr/bin/perl
use URI;
use Net::FTP;
 
my $url = $ARGV[0];
my $uri = URI->new($url);
my ($scheme, $host, $path) = ($uri->scheme, $uri->host, $uri->path);
my $ftp = Net::FTP->new($host) or die "Cannot connect to, $@";
$ftp->login();
for my $srr (@{$ftp->ls($path)}) {
	my $full_srr_path = $scheme . "://" . $host . "/". $srr;
	print join("\t", ($path, $srr, $full_srr_path)), "\n";
}	


