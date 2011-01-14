#!/usr/bin/perl 
my $file = $ARGV[0];
open my $fh, "<", $file || die;
my %id_geo;
while( my $line = <$fh> ) {
    chomp $line;
    my @fields = split /\t/, $line;
    my $id = $fields[0];
    my @geo_ids = split /,\s*/, $fields[2];
    @geo_ids = nr(@geo_ids);
    for my $t (@geo_ids) {
	if ( exists $id_geo{$t} ) {
	    push @{$id_geo{$t}}, $id;
	} else {
	    $id_geo{$t} = [$id];
	}
    }
}

while (my ($gs_id, $sub_ids) = each %id_geo) {
#    print $gs_id, " ", join(" ", @$sub_ids), "\n" ;
    print $gs_id, " is shared btwn ", join(" ", @$sub_ids), "\n" if scalar @$sub_ids > 1;
}

sub nr {
    my @ids = @_;
    my @nr;
    for my $id (@ids) {
	push @nr, $id unless scalar grep {$id eq $_} @nr;
    }
    return @nr;
}
