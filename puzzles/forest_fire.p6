#!/usr/bin/env perl6

$*OUT.out-buffer = False;
my @a;
loop {
    GUESS: for 1..* -> $i {
        for 1..(+@a div 2) -> $spacing {
            my @parts = $i, |@a[*-$spacing, *-$spacing*2];
            next GUESS if [==] gather for @parts -> $n {
                if state $p.defined { take $n-$p }
                $p = $n;
            }
        }
        @a.push: $i;
        last GUESS;
    }
    say "A229037({@a.elems}): {@a[*-1]}";
}
