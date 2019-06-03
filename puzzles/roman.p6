#!/usr/bin/env perl6
#
# From a Perl 6 puzzle. See:
#
# https://perlweeklychallenge.org/blog/perl-weekly-challenge-010/
#
# By Aaron Sherman 2019

use v6.c;

# Some globas relevant to both encoding and decoding
our $rom = 'MDCLXVI';
our @rom = $rom.comb;
our @val = <1000 500 100 50 10 5 1>;

# Declare that MAIN has multiple signatures. In Perl 6,
# MAIN is not only the default execution function, but
# is introspected in order to generate command-line
# parameter parsing. The comments that start with pound-
# equals are also pulled into the docs.
proto MAIN(|) {*}

# The test runner. Use --test to run this.
multi MAIN(
        Bool :$test #= Run tests
) {
    use Test;
    my @tests = <9999 1000 999 555 444 1149 9 8 7 6 5 4 3 2 1>;
    my @bad-tests = <LVX DM IIII XXXX CCCC roman !>;
    plan +@tests + +@bad-tests;
    for @tests -> $value {
        ok $value == from_roman(as_roman($value)), $value;
    }
    for @bad-tests -> $roman {
        dies-ok { from_roman($roman) }, "Bad roman value '$roman'";
    }
}
    
multi MAIN(
        Int $number #= base 10 number
) {
    say as_roman($number);
}

multi MAIN(
        Str $number #= Roman encoded number
) {
    say from_roman($number);
}

sub as_roman($n is copy) {
    return [~] gather for ^@val Z @val Z @rom -> ($i, $v, $r) {
        take $r x ($n div $v) if $n >= $v;
        $n %= $v;
        my $offset = $v == any(1000, 100, 10) ?? 2 !! 1;
        my ($voff, $roff) = @val[$i+$offset], @rom[$i+$offset];
        if $v > 1 and $n >= $v-$voff and $n > $voff {
            take $roff ~ $r if $v > 1 and $n >= $v-$voff;
            $n -= $v-$voff;
        }
    };
}

sub from_roman(Str $n) {
    sub value($c) { @val[$rom.index($c)] }
    if $n !~~ m{
        ^ 'M'* 'CM'? 'CD'? 'D'? 'C' ** 0..3 'XC'? 'L'? 'XL'? 'X' ** 0..3 'IX'?
        'V'? 'IV'? 'I' ** 0..3 $} {
        die "'$n' is not valid";
    }
    return [+] gather for $n ~~ m:g/CM|M|CD|D|XC|C|XL|L|IX|X|IV|V|I/ -> $r {
        if $r.chars == 1 {
            take value($r);
        } else {
            take value($r.substr(1,1)) - value($r.substr(0,1));
        }
    }
}
