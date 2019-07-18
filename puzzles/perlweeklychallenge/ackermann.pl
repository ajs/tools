#!/usr/bin/env perl

use v5.20;
use feature 'signatures';
use feature "switch";
use warnings;
no warnings 'experimental';
no warnings 'recursion';
use strict;

use Getopt::Long;
use Pod::Usage;

# From the announcement:

# PERL WEEKLY CHALLENGE - 017

# Task #1

# Create a script to demonstrate Ackermann function. The Ackermann function
# is defined as below, m and n are positive number:

#  A(m, n) = n + 1                  if m = 0
#  A(m, n) = A(m - 1, 1)            if m > 0 and n = 0
#  A(m, n) = A(m - 1, A(m, n - 1))  if m > 0 and n > 0

#Example expansions as shown in wiki page.

# A(1, 2) = A(0, A(1, 1))
#         = A(0, A(0, A(1, 0)))
#         = A(0, A(0, A(0, 1)))
#         = A(0, A(0, 2))
#         = A(0, 3)
#         = 4

sub givenA($m, $n) {
	given ($m) {
		when (0      ) {        $n + 1                      }
		when ($n == 0) { givenA($m - 1, 1)                  }
		default        { givenA($m - 1, givenA($m, $n - 1)) }
	}
}

sub regex_resolve {
	if ($1 eq "0") {
		$2 + 1;
	} elsif ($2 eq "0") {
		my $m = $1 - 1;
		"A($m, 1)";
	} else {
		my $m1 = $1 - 1;
		my $m2 = $1;
		my $n = $2 - 1;
		"A($m1, A($m2, $n))";
	}
}

sub regexA($m, $n, %args) {
	my $verbose = $args{verbose};
	my $ack = "A($m, $n)";
	say $ack if $verbose;
	while ($ack =~ s/A\(\s*(\d+)\s*,\s*(\d+)\s*\)/regex_resolve()/eg) {
		say "\t = $ack" if $verbose;
	}
	$ack+0;
}

sub arrayA($m, $n) {
	my @ack = ($m, $n);
	while (@ack > 1) {
		my($m, $n) = splice(@ack, @ack-2);
		if ($m == 0) { push(@ack, $n + 1) }
		elsif ($n == 0) { push(@ack, $m - 1, 1) }
		else { push(@ack, $m - 1, $m, $n -1) }
	}
	pop(@ack) + 0;
}

sub doA($m, $n, $count, $A=\&givenA, %flags) {
	say $A->($m, $n, %flags) for 1..$count;
}

sub main {
	my $mode = 'array';
	my $count = 1;
	my $verbose = 0;
	GetOptions(
		'mode=s' => \$mode,
		'count=i' => \$count,
		'verbose' => \$verbose) or pod2usage(2);
	if (@ARGV != 2) {
		pod2usage(2);
	}
	my($m, $n) = @ARGV;
	my %opts;
	$opts{verbose} = 1 if $verbose;
	my %funcmap = (
		array => \&arrayA,
		given => \&givenA,
		regex => \&regexA
	);
	doA($m, $n, $count, $funcmap{$mode}, %opts);
}

main();

__END__

=head1 NAME

ackerman.pl - Various ways of resolving Ackermann numbers

=head1 SYNOPSIS

    ackermann.pl [options] <m> <n>

		--mode=<NAME> - One of array, regex or given
		--count=<N> - Number of trials (for timing)
		--verbose - If the mode supports it, be verbose

=cut
