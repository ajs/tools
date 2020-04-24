#!/usr/bin/env perl6

use v6.d;

our @small-primes = eager (^1000).grep: *.is-prime;

sub factor($n, $min=2) {
    #= Check $n for primality and factor (factors will be >= $n)
    if $n.is-prime {
        return $n;
    } else {
        return factor-comp($n, $min);
    }
}

sub factor-comp($n, $min) {
    #= Factor known composite $n

    for potential-divisors($n, $min) -> $p {
        return $p, |factor($n div $p, $p) if $n %% $p;
    }

    die "$n was not composite"
}

sub potential-divisors($n, $min) {
    #= Potential divisors of $n, >= $min as a lazy list

    my $cutoff = $n.sqrt.Int;
    $cutoff-- if $cutoff %% 2;

    lazy gather do {
        take $_ for @small-primes.grep({$min <= $_ <= $cutoff});
        if $cutoff >= 1001 {
            take $_ for max($min,1001), *+2 ... $cutoff;
        }
    }
}

sub MAIN(Int $n, Bool :$quiet) {
    #= Factor N and produce the prime decomposition
    if $n.is-prime {
        put $quiet ?? $n !! "$n is prime";
    } elsif $n < 2 {
        put "$n is too small";
    } else {
        my @factors = factor($n);
        my $check = [*] @factors;
        die "Bad result $n != $check ({@factors.join('*')})" if $check != $n;
        if $quiet {
            put @factors.join(" ");
        } else {
            put "Factors of $n: {@factors.join(", ")}";
        }
    }
}
