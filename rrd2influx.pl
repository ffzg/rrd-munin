#!/usr/bin/perl
use warnings;
use strict;
use autodie;

use Data::Dump qw(dump);
my $debug = $ENV{DEBUG};

my $url = "http://10.60.0.92:8086/write?db=munin_archive";

my @files;
while(<DATA>) {
	chomp;
	my @add = glob $_;
	push @files, @add;
	warn "# $_ -> ", $#add + 1, " rrd files\n" if $debug;
}
@files = @ARGV if @ARGV;

my $influx_path = '/dev/shm/rrd2influx';

foreach my $file ( @files ) {

	my $id = $file;
	$id =~ s{/var/lib/munin/}{} || die "can't strip path from: $id";
	my ($group,$host,$plugin,$name,undef) = split(/[\/-]/,$id);
	my @a = split(/[\/-]/,$id);
	warn "# file = $file ", dump(\@a) if $debug;

	my $cf = '_UNKNOWN';
	my $t_off = 0; # spread average/min/max

	open(my $fh, '-|', "rrdtool dump $file");
	open(my $influx, '>', $influx_path);
	while(<$fh>) {
		if ( m{<cf>(\w+)</cf>} ) {
			$cf = $1;
			$t_off++; # multiple values for same time offset (kind of)
		} elsif ( m{/ (\d+) --> <row><v>(.+)</v></row>} ) {
			if ( $2 + 0 != $2 ) {
				warn "SKIP: $_" if $debug;
				next;
			}
			my ( $t, $v ) = ( $1, $2 + 0 );
			print $influx "$plugin,group=$group,host=$host,plugin=$plugin,cf=$cf,name=$name $cf=$v ", $t * 1000000000 + $t_off, "\n";
		} else {
			warn "## $_" if $debug;
		}
	}
	close ($influx);
	system "curl -q -XPOST $url --data-binary \@$influx_path";

}

__DATA__
/var/lib/munin/*/*-fail2ban-*.rrd
/var/lib/munin/net.ffzg/deenes-amavis-*.rrd
/var/lib/munin/net.ffzg/deenes-clamav-*.rrd
/var/lib/munin/*/*-postfix_*.rrd
