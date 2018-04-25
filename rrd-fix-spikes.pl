#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use English;

die "you need to run this script as root\n" unless $UID == 0;

my ( $patt, $max ) = @ARGV;
#die "usage: $0 rrd-file-pattern max-value" unless $patt && $max;

#$patt = 'snmp;sw-lib.*:if_bytes.(send|recv)';
$patt = 'snmp;' . $patt .':if_bytes.(send|recv)';
$max = 2_000_000_000; # 10Gbit/s

warn "# $patt max:$max\n";

open(my $munin, '<', '/var/lib/munin/datafile');
while(<$munin>) {
	chomp;
	next unless m/type/;
	#warn "# $_\n";
	next unless m/$patt/;
	if (/^(\S+);(\S+):(\S+)\.(\S+)\./) {
		foreach (glob "/var/lib/munin/$1/$2-$3-$4-?.rrd") {
			qx{sudo /etc/init.d/rrdcached stop};

			print qq{File: $_\tMax: $max\n};

			qx{rrdtool tune $_ -a 42:$max};
			qx{rrdtool dump $_ > /tmp/rrdtool-xml};
			qx{./rrdxml-flatten-spike.pl /tmp/rrdtool-xml > /tmp/rrdtool-xml.fixed};
			qx{rrdtool restore -r /tmp/rrdtool-xml.fixed $_.new};
			qx{chown munin:munin $_.new};
			qx{mv $_ $_.bak};
			qx{mv $_.new $_};

			qx{sudo /etc/init.d/rrdcached start};
		}
	}
}
