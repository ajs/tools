use v6;

# Perl Weekly Challenge 020.2
# Task #2
# Write a script to print the smallest pair of Amicable Numbers. For more
# information, please checkout wikipedia page.
# https://en.wikipedia.org/wiki/Amicable_numbers

sub number($n) { "a" x $n }

sub divisors($n) {
    my @divisors;
    $n ~~ m :!ratchet /^ (.+) [$0]+ $ {@divisors.push: ~$0} '-' /;
    @divisors;
}

sub sum(+@n) { [+] @n>>.chars }

#= The most obvious way to find Amicable Numbers
sub MAIN(
        Int $start=0, #= Where to start the search (0)
        Int $end=Int, #= Where to terminate the search (∞)
        Bool :$include-same, #= Include pairs that are the same number
        Bool :$verbose #= Verbose output
) {
    for $start .. ($end//Inf) -> $i {
        my $amicable = sum(divisors(number($i)));
        my $second = sum(divisors(number($amicable)));
        say "  $i -> $amicable -> $second" if $verbose;
        next if $include-same ?? $i > $amicable !! $i >= $amicable;
        say "$i, $amicable" if $i == $second;
    }
}
