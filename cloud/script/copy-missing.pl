#!/usr/bin/perl
my $file = $ARGV[0];
open my $fh, "<", $file;
while(my $line = <$fh>) {
  chomp $line;
  my ($from, $to) = split " ", $line;
  $from =~ s/\(/\\\(/g; $from =~ s/\)/\\\)/g;
  $to =~ s/\(/\\\(/g; $to =~ s/\)/\\\)/g;
  system("cp $from $to") == 0 || print $line, "\n" and next;
}
