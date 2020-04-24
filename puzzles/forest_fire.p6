#!/usr/bin/env perl6

use v6;

$*OUT.out-buffer = False;

sub forest-fire(:$negative, :$base=1) {
    my @a;
    gather loop {
        my $min = $negative ?? (@a ?? min(@a)-1 !! 0) !! $base;
        GUESS: for $min..* -> $i {
            for (1..(+@a div 2)).map({@a[*-$_], @a[*-($_*2)]}) -> ($a1, $a2) {
                next GUESS if $i - $a1 == $a1 - $a2;
            }
            @a.push: take $i;
            last GUESS;
        }
    }
}

sub MAIN(Bool :$verbose, Bool :$negative, Bool :$prime, Int :$base=1) {
    my @p = (2..*).grep({.is-prime});
    for forest-fire(:$negative, :$base) -> $an {
        (state $n = 0)++;
        if $verbose {
            put "A229037($n) = $an";
        } else {
            if $prime {
                put "$an\t{@p.shift}";
            } else {
                put $an;
            }
            CATCH { when /'Broken pipe'/ {exit} }
        }
    }
}
