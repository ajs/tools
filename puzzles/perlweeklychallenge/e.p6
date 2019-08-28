#!/usr/bin/env perl6
#
# A fun exercise in turning Perl 6 into math: generating the constant e

# Specify verison requirement
use v6.c;

# Define factorial
proto postfix:<!>(Int) is equiv(&postfix:<++>) {*}
# Factorial 1 is 1
multi postfix:<!>(1) { 1 }
# Factorial anything else is n*(n-1)!
multi postfix:<!>(Int $n) { $n * ($n-1)! }

# Sigma is a class that holds a summation expression
class Sigma does Iterable {
    has $.start;
    has $.end;
    has $.offset = 0;
    has &.formula;

    # The "Sigma:D:" on a method means this can only be called
    # on instantiated ("Defined") Sigma objects.
    method summation(Sigma:D:) {
        # [\+] is Perl 6 magic for sum with partial results
        lazy [\+] gather do {
            take self.offset;
            loop (my $i = self.start; $i < self.end; $i++) {
                take (self.formula)($i);
            }
        }
    }

    # This Sigma iterable and will be called internally by loops
    method iterator(Sigma:D:) {
        self.summation.iterator
    }
}

# An integer plus a Sigma is a Sigma with an offset
multi infix:<+>(Numeric $a, Sigma $b) {
    Sigma.new(
        :start($b.start),
        :end($b.end),
        :formula($b.formula),
        :offset($a + $b.offset));
}

# Now we can define Σ as a function that instantiates a new Sigma
sub Σ($start, $end, &formula) { Sigma.new(:$start, :$end, :&formula) }

# We need an op for arbitrary size numerator rationals (which Perl 6 calls
# FatRat), so grab: ∕ (U+2215) DIVISION SLASH
sub infix:<∕>(Int $a, Int $b) { FatRat.new($a, $b) }

# Now e is easily defined in very simple terms
my @e = 1 + Σ(1, Inf, -> \n { 1∕n! });
# The only odd part is the "-> \n" which we can break down as follows:
#
# "-> parameters { ... }" defines a callable block or closure that takes
# the given parameters. \foo as a parameter is the variable "foo" without
# any special sigil like "$" or "@" before it. This is why we can reference
# the variable "n" in the body of that block as "1∕n!"

# Notice also that we stored this whole infinite sequence in an array.
# Arrays can be lazy in Perl 6, so there's no problem with that.

# print out the results
.put for @e;

# Output:
# 1
# 2
# 2.5
# 2.666667
# 2.708333
# 2.716667
# 2.718056
# 2.718254
# 2.718279
# 2.718282
# 2.718281801
# 2.718281826
# 2.7182818283
# 2.718281828447
# 2.7182818284582
# 2.71828182845899
# 2.7182818284590423
# 2.718281828459045
# 2.718281828459045227
# 2.7182818284590452
