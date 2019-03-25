#!/usr/bin/env perl6
#

use v6;

# Right now this doesn't get included in the --man output,
# but it seems a rational expectation for the future...

=begin pod

=head1 DESCRIPTION

This program randomly generates numbers of a given
length and determines how many steps it takes to reach
a one-digit nunber by multiplying the digits that make
up the number at each stage. For example, here is a number
that gives 5 steps:

 18843
 768
 336
 54
 20
 0

=head1 CREDIT

Inspired by the video:

L<https://www.youtube.com/watch?v=Wim9WJeDTHQ>

See also the smallest numbers for each score at:

L<https://oeis.org/A003001>

=head1 EXAMPLES

Here are some example command-lines:

Start at length=3 and proceed to find longer
and longer chains in increasinlgy longer numbers.

    ./searchmul.p6 --length=3 --increment

Search for the longest possib chain in a 15-digit number:

    ./searchmul.p6 --length=15

Search for a chain 11-steps long in a 15-digit number:

    ./searchmul.p6 --length=15 --stop=11

Same as the first example, but in base 16:

    ./searchmul.p6 --length=3 --increment --base=16

Try to apply some filtering to the search based on
how often digits occur in results:

    ./searchmul.p6 --length=3 --increment --frequency

=head1 SAMPLE OUTPUT

    ./searchmul.p6 --length=15 --stop=11
    2 steps:
    429472673763664
    9217732608
    0

    4 steps:
    922932833286829
    1934917632
    244944
    4608
    0

    7 steps:
    269772376888389
    147483721728
    4214784
    7168
    336
    54
    20
    0

    10 steps:
    993247378243222
    438939648
    4478976
    338688
    27648
    2688
    768
    336
    54
    20
    0

    11 steps:
    848787974797878
    4996238671872
    438939648
    4478976
    338688
    27648
    2688
    768
    336
    54
    20
    0

=end pod

# Kept as global so we can detect user-provided changes
our $default-digits = '2346789';

class MultiplicativePersistence {
    has $.length is rw = 3; # Current number length
    has $.base = 10; # Calculate numbers in this base
    has $.digits = '2346789'; # Use these digits to find results
    has $.frequency = False; # Build on frequency of results' digits

    has Bag $!freqs; # Frequencies of digits in results

    # Experimental build mode tries building new numbers via
    # concatenation.
    has $.build = False;
    has $.shuffle = False;
    has $.build-len = 100;
    has @!prefixes;
    has @!next-prefixes;

    submethod TWEAK() {
        # Seed frequncies with initial digits
        $!freqs (+)= $!digits.comb if $!frequency;
    }

    #| Return a string containing the next number to check
    method next-number() {
        if $!build and @!prefixes {
            my $all = [~] @!prefixes;
            my $number = @!prefixes.pick; # Pick a prefix
            # Shuffle if required
            $number = [~] $number.comb.pick(*) if $!shuffle;
            return $number ~ $all.comb.pick; # Add a digit used in any prefix
        } else {
            my $choices := ($!frequency ?? $!freqs !! $!digits.comb.eager);
            return [~] $choices.roll($!length);
        }
    }

    #| Return the number of multiplicative steps to a 1-digit number
    method score($number) { return self.steps($number).elems - 1 }

    #| Return the actual steps, including the starting number
    method steps($number is copy) {
        my @steps;
        loop {
            @steps.push: $number;
            last if $number.chars == 1;
            # These are the same, but base-10 is simplified for performance
            if $!base == 10 {
                $number = [*] $number.comb;
            } else {
                $number = (
                    [*] $number.comb.map({.parse-base($!base)})
                ).base($!base);
            }
        }
        return @steps;
    }

    method add-prefix($number) {
        @!next-prefixes.push: $number;
        if @!next-prefixes == $!build-len {
            @!prefixes = @!next-prefixes;
            @!next-prefixes = ();
        }
    }

    method update-frequency($number) {
        $!freqs (+)= $number.comb;
    }
}

# The "is copy" arguments are modifed inside MAIN

#| Search for multiplicative persistence
sub MAIN(
        Int  :$length is copy = 400, #= Length of results
        Str  :$digits is copy = $default-digits, #= Available digits
        Int  :$base=10,              #= Base to work in (ignores --digits)
        Int  :$count-from? is copy,  #= Instead of generating random numbers
        Bool :$increment=False,      #= Increment length after each find
        Bool :$increment-slow=False, #= --increment, but only when score increases
        Bool :$build=False,          #= Build on previous finds
        Int  :$stop=0,               #= Where to stop (0=none)
        Bool :$shuffle=False,        #= When --build-ing, shuffle prefix numbers
        Int  :$build-len=100,        #= When --build-ing, size of prefix cache
        Bool :$verbose is copy =False, #= Verbose output
        Bool :$debug=False,          #= Debugging output
        Bool :$quiet is copy =False, #= Terse output
        Bool :$very-quiet=False,     #= Like --quiet, but only show the final entry
        Bool :$frequency=False,      #= Weight digit choices by frequency in results
        Bool :$prime=False,          #= Seed --digits with prime factors
        Bool :$print-max=False,      #= Show any find at least as long as current max
        Bool :$sort,                 #= Sort the digits of results.
    ) {

    my $max = 0;
    my @prefixes;
    my @next-prefixes;
    my $debug-step = 0;
    my $verbose-step = 0;

    if $build {
        if $increment {
            die "--build and --increment are not compatible";
        }
        warn "--build is experimental at this time.";
    }
    $verbose = True if $debug;

    if $very-quiet {
        die "--quiet requires --stop" unless $stop;
        $quiet = True;
    }

    given $base {
        when 10 { }
        when $_ < 3 { die "--base must be >= 3" }
        when $_ > 36 { die "--base must be <= 36" }
        default {
            if $digits eq $default-digits {
                $digits = [~] (2..^$base).map({.base: $base});
            }
        }
    }

    if $prime {
        print "Stripping composites from digits: $digits -> " if $verbose;
        $digits = [~] $digits.comb.grep: {.parse-base($base).is-prime};
        put $digits if $verbose;
    }

    my MultiplicativePersistence $engine .= new(
        :$length,
        :$base,
        :$digits,
        :$frequency,
        # All build mode params:
        :$build, :$build-len);

    my sub report($n, $score, :$force=False) {
        my $outnum = $sort ?? [~] $n.comb.sort !! $n;
        if $quiet {
            put "$outnum: $score" if $force or !$very-quiet or $score >= $stop;
        } else {
            put "Length: {$outnum.chars}" if $increment or $build;
            put "$score steps:";
            put $_ for $engine.steps($outnum);
            put "";
        }
    }

    our $winner; # The highest scoring result so far, used only for
                 # premature exit via signal.
    signal(SIGUSR1).tap: {
        report($winner, $engine.score($winner), :force) if $winner;
        exit 0;
    }

    # Here begins the main search loop:
    loop {
        # our current "number" (actually a string of digits)
        my $number = $count-from ?? $count-from++ !! $engine.next-number;
        my $score = $engine.score($number);

        if $debug {
            put "Trying $number" if $debug-step %% 1_000;
        } elsif $verbose {
            print "." if $verbose-step++ %% 1_000;
        }

        if $score >= $max {
            if $increment or ($increment-slow and $score > $max) {
                $engine.length++;
                put "(New length {$engine.length} at $number)" if $verbose;
            } elsif $build {
                if $debug {
                    put "Add $number to prefixes";
                }
                $engine.add-prefix($number)
            }

            if $frequency and $score > 2 {
                $engine.update-frequency($number);
                print "*" if $verbose;
            }

            if $score > $max or $print-max {
                report($number, $score);
            }

            # The winner thus far...
            $winner = $number if not $winner or $score > $max;
            $max = $score if $score > $max;
        }

        put $engine.steps($number) if $debug and $debug-step++ %% 1_000;

        last if $stop and $score >= $stop;
    }
}
