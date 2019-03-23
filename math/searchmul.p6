#!/usr/bin/env perl6
#

use v6;

# This program randomly generates numbers of a given'
# length and determines how many steps it takes to reach
# a one-digit nunber by multiplying the digits that make
# up the number at each stage. For example, here is a number
# that gives 5 steps:
#
#  18843
#  768
#  336
#  54
#  20
#  0
sub MAIN(
        Int  :$length is copy = 400, #= Length of results
        Str  :$digits is copy = "2346789", #= Available digits
        Int  :$base=10,              #= Base to work in (ignores --digits)
        Bool :$increment=False,      #= Increment length after each find
        Bool :$build=False,          #= Build on previous finds
        Int  :$stop=0,               #= Where to stop (0=none)
        Bool :$shuffle=False,        #= When --build-ing, shuffle prefix numbers
        Int  :$build-len=100,        #= When --build-ing, size of prefix cache
        Bool :$verbose is copy =False, #= Verbose output
        Bool :$debug=False,          #= Debugging output
        Bool :$frequency=False,      #= Weight digit choices by frequency in results
    ) {

    use Test;
    my $max = 0;
    my @prefixes;
    my @next-prefixes;
    my $ratchet = 0;

    if $build {
        if $increment {
            die "--build and --increment are not compatible";
        }
        warn "--build is experimental at this time.";
    }
    $verbose = True if $debug;

    given $base {
        when 10 { }
        when $_ < 3 { die "--base must be >=3" }
        when $_ > 36 { die "--base must be <= 36" }
        default {
            $digits = [~] (2..^$base).map({.base: $base}).eager;
        }
    }

    my Bag $freqs .= new: $digits.comb;

    OUTER:
    loop {
        my $number;
        print "-" if $debug and (state $debug-step)++ %% 100;
        if $build and @prefixes {
            my $all = [~] @prefixes;
            $number = @prefixes.pick; # Pick a prefix
            $number = [~] $number.comb.pick(*) if $shuffle; # Shuffle if required
            $number ~= $all.comb.pick; # Add a digit used in any prefix
        } else {
            my $choices := ($frequency ?? $freqs !! $digits.comb.eager);
            $number = [~] (^$length).map: { $choices.roll };
        }
        my @steps;
        my $orig = $number;
        put "Trying $number" if $debug and $debug-step %% 1000;
        loop {
            if $number.chars == 1 {
                if @steps >= $max {
                    if $increment {
                        $length++;
                        put "(New length $length at $orig)" if $verbose;
                    } elsif $build {
                        if $debug {
                            put "Add $orig to prefixes";
                        } elsif $verbose and (state $verbose-step)++ %% 100 {
                            print ".";
                        }
                        @next-prefixes.push: $orig;
                        if @next-prefixes == $build-len {
                            put "Swapping in new prefixes: {@next-prefixes}" if $debug;
                            @prefixes = @next-prefixes;
                            @next-prefixes = ();
                        }
                    }
                }
                if @steps > $max {
                    $max = +@steps;
                    put "Length: {$orig.chars}" if $increment or $build;
                    put "{+@steps} steps:\n$orig";
                    put $_ for @steps;
                    put ""
                }
                last;
            }
            $number = ([*] $number.comb.map({.parse-base($base)})).base($base);
            put "  $number" if $debug and $debug-step %% 1000;
            push @steps, $number;
        }
        if @steps > $ratchet {
            $ratchet = +@steps;
            put "$orig\({+@steps})" if $debug;
        }
        if @steps == $max {
            $ratchet = 0;
            if $frequency {
                $freqs (+)= $orig.comb;
                put $freqs if $debug;
            }
        }
        last if $stop and @steps >= $stop;
    }
}
