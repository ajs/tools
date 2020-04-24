#!/usr/bin/env perl6

# A solution to the Two-Sum interview question in Perl 6

sub report($a, $b, $goal) {
    say "{sort($a, $b).join(' + ')} == $goal";
}

proto MAIN($goal, *@input, *%options) {*}

multi MAIN($goal, *@input, Bool :$brute-force!, Bool :$all) {
    #= The brute-force approach
    for @input.combinations(2) -> ($a, $b) {
        if $a+$b == $goal {
            report($a, $b, $goal);
            last unless $all;
        }
    }
}

multi MAIN($goal, *@input, Bool :$all) {
    #= The hash-based approach (--all will skip some duplicates)
    for @input -> $value {
        state SetHash $seeking .= new;
        my $delta = $goal - $value;
        if $seeking{$delta} {
            report($value, $delta, $goal);
            last unless $all;
        }
        $seeking (|)= +$value;
    }
}
