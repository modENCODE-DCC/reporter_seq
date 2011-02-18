#!/usr/bin/perl

$tag_file = $ARGV[0];
open my $tfh, "<", $tag_file || die;
while(my $line = <$tfh>) {
    if ($line =~ /^DCC/) {
	if ($header_printed == 0) {
	    print $line;
	    $header_printed = 1;
	} 
    } else {
	print $line;
    }
}
