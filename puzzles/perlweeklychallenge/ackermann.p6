#!/usr/bin/env perl6

use v6;

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

subset PInt of UInt where *;

proto multiA(UInt $m, UInt $n --> UInt) {*}
multi multiA(0, PInt $n --> UInt)       {        $n + 1                      }
multi multiA(PInt $m, 0 --> UInt)       { multiA($m - 1, 1)                  }
multi multiA(PInt $m, PInt $n --> UInt) { multiA($m - 1, multiA($m, $n - 1)) }

sub givenA(UInt $m, UInt $n --> UInt) {
	given $m {
		when 0       {        $n + 1                      }
		when $n == 0 { givenA($m - 1, 1)                  }
		default      { givenA($m - 1, givenA($m, $n - 1)) }
	}
}

# Because Perl won't let me modify a pair's value...
class MIPair does Associative {
	has Int $.key;
	has $.value is rw;
	# Allow non-named construction:
	multi method new(Int $key, Int $value) {
		self.bless(:$key, :$value, |%_);
	}
	multi method new(Int $key, MIPair $value) {
		self.bless(:$key, :$value, |%_);
	}
}

sub iterativeA(UInt $m, UInt $n --> UInt) {
	my $p = MIPair.new($m, $n);
	# Pair($m, $n) is A($m, $n) while a non-pair is a resolved value
	my $pp := $p;
	while $p ~~ MIPair {
		if $pp.value ~~ MIPair {
			$pp := $pp.value;
		} elsif $pp.key == 0 {
			$pp = $pp.value + 1;
			$pp := $p;
		} elsif $pp.value == 0 {
			$pp = MIPair.new(($pp.key - 1), 1);
		} else {
			$pp = MIPair.new(
				($pp.key - 1),
				MIPair.new($pp.key, $pp.value - 1));
		}
	}
	return $p;
}

sub doA(UInt $m, UInt $n, :$count, :$A=&givenA) {
	say $A($m, $n) for ^$count;
}

proto MAIN(UInt $m, UInt $n, UInt :$count, *%options) {*}

multi MAIN(UInt $m, UInt $n, UInt :$count=1, Bool :$given=True) {
	#= Ackermann via given/when recursion
	doA($m, $n, :$count);
}

multi MAIN(UInt $m, UInt $n, UInt :$count=1, Bool :$multi!) {
	#= Ackermann via multi sub recursion
	doA($m, $n, :$count, :A(&multiA));
}

multi MAIN(UInt $m, UInt $n, UInt :$count=1, Bool :$iterative!) {
	#= Ackermann via iterative tree
	doA($m, $n, :$count, :A(&iterativeA));
}
