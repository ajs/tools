#!/usr/bin/env perl6

# Perl weekly challenge

# TASK #1: Isomorphic Strings

# You are given two strings $A and $B. Write a script to check if the
# given strings are Isomorphic. Print 1 if they are otherwise 0.

use Test;


#= Return an iterator with a single number for each characer in the
#= input string. For each unique character in the input, the output
#= will have a corresponding unique number, starting at 0.
sub numify($s) {
    my %mapping;

    gather for $s.comb -> $c {
        %mapping{$c} = (state $n = 0)++ if $c !~~ %mapping;
        take %mapping{$c};
    }
}
        
#= Perform unit tests on numify
sub do_tests {
    say "Running Tests...";
    ok numify("word") ~~ [0,1,2,3], "'word' vs 0,1,2,3";
    ok numify("tilt") ~~ [0,1,2,0], "'tilt' vs 0,1,2,0";
    ok numify("word") ~~ numify("slip"), "'word' vs 'slip'";
    nok numify("word") ~~ numify("tilt"), "'word' vs 'tilt'";
    nok numify("word") ~~ numify("words"), "'word' vs 'words'";
    ok numify("") ~~ [], "Empty input";
    ok numify("aaaa") ~~ [0,0,0,0], "'aaaa' vs 0,0,0,0";
}

#= Compare two strings and determine isomorphism
multi sub MAIN(
    Str $s1, #= First string
    Str $s2, #= Second string
    Bool :$verbose = False, #= Extra output
) {
    if $s1.chars != $s2.chars {
        say 0;
        say "Differing lengths" if $verbose;
    } else {
        my $sn1 = numify($s1).List;
        my $sn2 = numify($s2).List;

        say ($sn1 ~~ $sn2 ?? 1 !! 0);
        if $verbose {
            my $eq = ($sn1 eq $sn2 ?? "==" !! "!=");
            say "$s1 -> $sn1 $eq $s2 -> $sn2";
        }
    }
}

multi sub MAIN(Str $s1) { put numify($s1) }

multi sub MAIN(Bool :$test where {$test}) { do_tests }
