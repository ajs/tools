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

proto multiA(Int $m, Int $n --> Int) {*}
multi multiA(     0, Int $n --> Int) {        $n + 1                      }
multi multiA(Int $m,      0 --> Int) { multiA($m - 1, 1)                  }
multi multiA(Int $m, Int $n --> Int) { multiA($m - 1, multiA($m, $n - 1)) }

sub whenA(Int $m, Int $n) {
	when $m == 0 {        $n + 1                    }
	when $n == 0 { whenA($m - 1, 1)                 }
	default      { whenA($m - 1, whenA($m, $n - 1)) }
}

sub recurseA(Int $m, Int $n) {
	if $m == 0 {
		$n + 1;
	} elsif $n == 0 {
		recurseA($m - 1, 1);
	} else {
		recurseA($m - 1, recurseA($m, $n - 1));
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

sub iterativeA(Int $m, Int $n --> Int) {
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

grammar Ackermann {
	rule TOP {^ <ackermann> $}
	rule ackermann { <number> | <function> }
	token number { "-"? \d+ }
	rule function {
		'A' '(' $<m> = <ackermann> ',' $<n> = <ackermann> ')'
	}
	rule resolvable {
		'A' '(' $<m> = <number> ',' $<n> = <number> ')'
	}
}

sub regexA(Int $m, Int $n, :$verbose=False --> Int) {
	my $ack = "A($m, $n)";
	say $ack if $verbose;
	while $ack !~~ /^ <Ackermann::number> $/ {
		$ack .= subst(
			/$<A> = <Ackermann::resolvable>/, 
			{
				when $<A><m> eq "0" { $<A><n> + 1 }
				when $<A><n> eq "0" { "A({$<A><m> - 1}, 1)" }
				default { "A({$<A><m> - 1}, A($<A><m>, {$<A><n> - 1}))" }
			},
			:global);
		say "\t = $ack" if $verbose;
	}
	+$ack;
}

sub arrayA(Int $m, Int $n --> Int) {
	my @ack of int = $m, $n;
	while @ack.elems > 1 {
		(my int $m, my int $n) = @ack.splice(@ack.elems-2);
		if $m == 0 { @ack.push($n + 1) }
		elsif $n == 0 { @ack.push($m - 1, 1) }
		else { @ack.push($m - 1, $m, $n -1) }
	}
	@ack.pop;
}

sub doA(UInt $m, UInt $n, :$count, :$A=&whenA, *%flags) {
	say $A($m, $n, |%flags) for ^$count;
}

proto MAIN(UInt $m, UInt $n, UInt :$count, *%options) {*}

multi MAIN(UInt $m, UInt $n, UInt :$count=1, Bool :$when=True) {
	#= Ackermann via recursion using when instead of if/else
	doA($m, $n, :$count);
}

multi MAIN(UInt $m, UInt $n, UInt :$count=1, Bool :$recurse!) {
	#= Ackermann via if/else recursion
	doA($m, $n, :$count, :A(&recurseA));
}

multi MAIN(UInt $m, UInt $n, UInt :$count=1, Bool :$multi!) {
	#= Ackermann via multi sub recursion
	doA($m, $n, :$count, :A(&multiA));
}

multi MAIN(UInt $m, UInt $n, UInt :$count=1, Bool :$iterative!) {
	#= Ackermann via iterative tree
	doA($m, $n, :$count, :A(&iterativeA));
}

multi MAIN(UInt $m, UInt $n, UInt :$count=1, Bool :$regex!, Bool :$verbose) {
	#= Ackermann via regex replacement
	doA($m, $n, :$count, :A(&regexA), :$verbose);
}

multi MAIN(UInt $m, UInt $n, UInt :$count=1, Bool :$array!) {
	#= Ackermann via array management
	doA($m, $n, :$count, :A(&arrayA));
}
