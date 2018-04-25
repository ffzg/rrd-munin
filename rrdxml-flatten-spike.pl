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
		# FIXME this should be calculated, but then this script can't be pipe
		if ( $e > 7 ) {
			warn "# FLATTEN [$_]\n";
			s{<v>.*</v>}{<v>NaN</v>};
		} elsif ( $e == 7 && m/<v>[2-9]\./ ) {
			warn "# SPIKE   [$_]\n";
		}
	}
	print "$_\n";
}

warn "# stat = ",dump( $stat );
