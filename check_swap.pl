#! /usr/bin/perl -w

$| = 1;
use strict;
# Tell Perl what we need to use
use strict;
use Getopt::Std;


use vars qw($opt_c $opt_f $opt_u $opt_w $opt_C $opt_v %exit_codes);
%exit_codes   = ('UNKNOWN' ,-1,
		'OK'      , 0,
		'WARNING' , 1,
		'CRITICAL', 2,
		);

# Get our variables, do our checking:
init();

my ($total_swp, $free_swp, $used_swp ) = get_swp_info();
print "Free: $free_swp Used: $used_swp Total: $total_swp " if ($opt_v);
tell_nagios($used_swp,$free_swp,$used_swp);

sub tell_nagios {
	my ($used,$free,$caches) = @_;

# Calculate Total Memory
	my $total = $free + $used;
	print "$total Total\n" if ($opt_v);
	my $cval = $total * $opt_c / 100; 
	my $wval = $total * $opt_w / 100;
	my $perfdata = "|TOTAL=${total}KB;$opt_w;$opt_c;; USED=${used}KB;;;; FREE=${free}KB;;;; ";
	my $percent;
	if($total == 0)
	{
	$percent = 0;
	}
	else
	{
	$percent    = sprintf "%.1f", ($used / $total * 100);
	}
		if ($percent >= $opt_c) {
			finish("CRITICAL - $percent% ($used kB) used!|$perfdata",$exit_codes{'CRITICAL'});
		}
		elsif ($percent >= $opt_w) {
			finish("WARNING - $percent% ($used kB) used!|$perfdata",$exit_codes{'WARNING'});
		}
		else {
			finish("OK - $percent% ($used kB) used.|$perfdata",$exit_codes{'OK'});
		}
}

sub get_swp_info {

	my ($free,$used,$full) = 0; 
	$full = `free | grep Swap | sed -r 's/\\ +/\\ /g' | cut -d \\  -f 2`;
	$free = `free | grep Swap | sed -r 's/\\ +/\\ /g' | cut -d \\  -f 4`;
	chomp($full);
	chomp($free);
	$used = $full - $free;
	return ($full,$free,$used);
}
sub usage() {
	print "\ncheck_swap.pl v1.0 - Nagios Plugin\n\n";
	print "usage:\n";
	print " check_swap.pl -w <warnlevel> -c <critlevel>\n\n";
	print "options:\n";
	print " -w PERCENT   Percent free/used when to warn\n";
	print " -c PERCENT   Percent free/used when critical\n";
	exit $exit_codes{'UNKNOWN'}; 
}
sub init {
# Get the options
	if ($#ARGV le 0) {
		&usage;
	}
	else {
		getopts('c:vw:');
	}

# Shortcircuit the switches
	if (!$opt_w or $opt_w == 0 or !$opt_c or $opt_c == 0) {
		print "*** You must define WARN and CRITICAL levels!\n";
		&usage;
	}

# Check if levels are sane
	if ($opt_w <= $opt_c and $opt_f) {
		print "*** WARN level must not be less than CRITICAL when checking FREE memory!\n";
		&usage;
	}
	elsif ($opt_w >= $opt_c and $opt_u) {
		print "*** WARN level must not be greater than CRITICAL when checking USED memory!\n";
		&usage;
	}
}

sub finish {
	my ($msg,$state) = @_;
	print "$msg\n";
	exit $state;
}

