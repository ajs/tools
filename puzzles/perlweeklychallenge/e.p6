#!/usr/bin/env perl6
#
# A fun exercise in turning Perl 6 into math: generating the constant e
#
# In the end, this expression will be used to define e:
#
#   1 + Σ(1, Inf, 1∕*!)
#
# To most mathematicians, this should be fairly readable, though you
# would typically use a variable like "n" instead of an asterisk.
#
# This does a few things we have to define:
#
# * It uses a factorial operator that doesn't exist in the core language
# * It uses a funky division operator to do arbitrary precision rational
#   division.
# * It uses a function called Σ (sigma) to do the summation
# * It adds 1 to an expression that isn't a simple scalar value

# Specify version requirement
use v6.c;

# Define factorial by first giving the prototype: it takes an Int parameter
# and has the same operator precedence as postfix ++
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
    # We don't use this here, but the step can be controlled by
    # passing this parameter to the Sigma instantiation.
    has &.step = * + 1;

    # The "Sigma:D:" on a method means this can only be called
    # on instantiated ("Defined") Sigma objects.
    method summation(Sigma:D:) {
        # [\+] is Perl 6 magic for "sum with partial results"
        # So [\+] 1, 2, 3 gives 1, 3, 6 which is just what we
        # need for sigma. It turns out that + isn't special, here,
        # and we could use any infix operator such as [\*] for partial
        # products.
        lazy [\+] gather do {
            take self.offset;
            for self.start, self.step ... self.end -> $i {
                take self.formula.($i);
            }
        }
    }

    # This Sigma iterable and will be called internally by loops
    method iterator(Sigma:D:) {
        self.summation.iterator
    }
}

# An integer plus a Sigma is a new Sigma with the integer added to
# its offset
multi infix:<+>(Numeric $a, Sigma $b) {
    Sigma.new(
        :start(   $b.start       ),
        :end(     $b.end         ),
        :formula( $b.formula     ),
        :offset(  $a + $b.offset ),
        :step(    $b.step        ));
}

# Now we can define Σ as a function that instantiates a new Sigma
sub Σ($start, $end, &formula) { Sigma.new(:$start, :$end, :&formula) }

# We need an op for arbitrary resolution rationals (which Perl 6 calls
# FatRat), so grab: ∕ (U+2215) DIVISION SLASH
sub infix:<∕>(Int $a, Int $b) { FatRat.new($a, $b) }

# Now e is easily defined in very simple terms
my @e = 1 + Σ(1, Inf, 1∕*!);

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
# ...