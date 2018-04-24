#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use Data::Dump qw(dump);

my $stat;

my $file = shift @ARGV;

my $cf;
open(my $fh, '<', $file);
while(<$fh>) {
	chomp;
	if ( m{<cf>(.*)</cf>} ) {
		$cf = $1;
	} elsif ( m{<v>\d\.\d+e[+-](\d+)</v>} ) {
		my $e = $1;
		$stat->{expon}->{$cf}->{$e}++;
		if ( $e > 7 ) {
			s{<v>.*</v>}{<v>NaN</v>};
		}
	}
	print "$_\n";
}

#warn dump( $stat );
