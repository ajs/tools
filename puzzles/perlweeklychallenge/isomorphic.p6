#!/usr/bin/env perl6

# Perl weekly challenge

# TASK #1: Isomorphic Strings

# You are given two strings $A and $B. Write a script to check if the
# given strings are Isomorphic. Print 1 if they are otherwise 0.


sub numify($s) {
    my %mapping;

    join "", gather for $s.comb -> $c {
        %mapping{$c} = (state $n = 0)++ if $c !~~ %mapping;
        take %mapping{$c};
    }
}
        
#= Compare two strings and determine isomorphism
sub MAIN(
    Str $s1, #= First string
    Str $s2, #= Second string
    Bool :$verbose = False, #= Extra output
) {
    if $s1.chars != $s2.chars {
        say 0;
        say "Differing lengths" if $verbose;
    } else {
        my $sn1 = numify $s1;
        my $sn2 = numify $s2;

        say ($sn1 eq $sn2 ?? 1 !! 0);
        if $verbose {
            my $eq = ($sn1 eq $sn2 ?? "==" !! "!=");
            say "$s1 -> $sn1 $eq $s2 -> $sn2";
        }
    }
}
