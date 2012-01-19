#!/usr/bin/perl
# A solution to the ITA puzzle as it appears in the ads, NOT as it appears
# on the Web site. On the Web site, the order of the numbers is based
# on an alphabetical sort of their names, not numberic order, which
# makes it a very different problem. This is the statement of the problem
# on the ad:
#  If the integers from 1 to 999,999,999 are written as words, and
#  concatenated, what is the 51 billionth letter?
# - http://www.itasoftware.com/careers/puzzles/puzzlethumb3.gif
#
# Written in 2007 by Aaron Sherman <ajs@itasoftware.com>

# $ time perl ./fiftyonebillion.pl
# The 25th character of 732796366
#	(sevenhundredthirtytwomillionsevenhundredninetysixthousand-
#	 threehundredsixtysix) is l
# 
# real    0m0.072s
# user    0m0.020s


use List::Util qw(sum);
use strict;

# All of the words that can be used:
our @ones = ('', qw(one two three four five six seven eight nine));
our @teens = qw(ten eleven twelve thirteen fourteen fifteen sixteen seventeen
		eighteen nineteen);
our @tens = qw(twenty thirty forty fifty sixty seventy eighty ninety);
our $hundred = 'hundred';
our $thousand = 'thousand';
our $million = 'million';

# Our givens:
my $number;
my $target = 51_000_000_000;
my $high = 999_999_999;
my $low = 1;

our %cache; # Used to cache the length of 1 to _key_

# Solve it using a simple binary search, calculating the lenght of 1
# to n for each n along the search.
for(;;) {
	my $old = $number;
	$number = int(($high + $low)/2);
	$number++ if $number == $old && $number < $high;
	my $len = one_to($number);
	if ($len > $target) {
		if ($number-$low == 1) {
			found_target($number,$len,$target);
		}
		$high = $number;
	} elsif ($len < $target) {
		$low = $number;
	} else {
		print "Exact hit at $number\n";
		found_target($number,$len,$target);
		last;
	}
	if ($high == $low) {
		found_target($number,$len,$target);
	}
}

exit 0;

###########################################

# Print the result and exit
sub found_target {
	my ($n,$len,$target) = @_;
	my $word = size_of($n,1);
	my $pos = length($word)-($len-$target);
	my $char = substr($word,$pos-1,1);
	print "The ",nth($pos), " character of $n ($word) is $char\n";
	exit 0;
}

# Format a number such as "3rd"
sub nth {
	my $n = shift;
	my @endings = qw(th st nd rd th th th th th th);
	return $n.'th' if $n > 9 && $n <= 20;
	return $n.$endings[$n%10];
}

# What is the length of all the number words from 1 to n.
# Caches all return values for later use.
sub one_to {
	my($n) = @_;
	return $cache{$n} if defined $cache{$n};
	my $len = 0;
	my $i;
	if ($n < 10) {
		$len = sum(map {length($_)} @ones[0..$n]);
	} elsif ($n < 100) {
		$len = one_to(9);
		for($i=10;$i<20 && $i<=$n;$i++) {
			# print "Adding length of ",$teens[$i-10], " to $len\n";
			$len += length($teens[$i-10]);
		}
		if ($n >= 20) {
			my $digit = $n%10;
			my $whole = $n-$digit;
			for($i=20;$i<$whole;$i+=10) {
				$len += length($tens[$i/10-2])*10 +
					one_to(9);
			}
			$len += one_to($digit) +
				length($tens[$whole/10-2])*($digit+1);
		}
	} elsif ($n < 1000) {
		$len = one_to_generic($n,100,$hundred);
	} elsif ($n < 1_000_000) {
		$len = one_to_generic($n,1000,$thousand);
	} elsif ($n < 1_000_000_000) {
		$len = one_to_generic($n,1_000_000,$million);
	} else {
		die "Cannot handle 1 billion+\n";
	}
	# print Dumper(\%cache);
	return $cache{$n} = $len;
}

# Length of the string 1-N, assuming that N is of MAGNITUDE which is
# named NAME.
sub one_to_generic {
	my($n,$magnitude,$name) = @_;
	my $rest = $n%$magnitude;
	my $len = whole_chunk($n,$magnitude,$name) +
		size_of($n-$rest)*($rest+1) +
		one_to($rest);
}

# What is the length of a particular single number
# Alternately, if called with a second parameter that is true,
# returns the string itself.
sub size_of {
	my $n = shift;
	my $text = shift;
	if ($n < 10) {
		my $words = $ones[$n];
		return $words if $text;
		return length($words);
	} elsif ($n < 20) {
		my $words = $teens[$n-10];
		return $words if $text;
		return length($words);
	} elsif ($n < 100) {
		my $part = $n%10;
		my $whole = $n-$part;
		my $words = $tens[$whole/10-2];
		return $words.size_of($part,$text) if $text;
		return length($words) + size_of($part);
	} elsif ($n < 1000) {
		return size_of_generic($n,100,$hundred,$text);
	} elsif ($n < 1_000_000) {
		return size_of_generic($n,1000,$thousand,$text);
	} elsif ($n < 1_000_000_000) {
		return size_of_generic($n,1_000_000,$million,$text);
	} else {
		die "Cannot handle 1 billion+\n";
	}
}

sub size_of_generic {
	my($n,$magnitude,$name,$text) = @_;
	my $part = $n%$magnitude;
	my $whole = $n-$part;
	my $words = size_of($whole/$magnitude,1).$name.size_of($part,1);
	return($text ? $words : length($words));
}

# The length of 1-n where n is the value of the first
# parameter rounded down to the nearest second parameter.
# The third parameter is the string name of the magnitude
# of the second parameter.
sub whole_chunk {
	my ($n,$chunk,$name) = @_;
	my $boundary = $n-$n%$chunk;
	my $rest = $n%$chunk;
	my $chunks = int($n/$chunk)-1;
	my $right = one_to($chunks)*$chunk;
	my $mid = length($name) * $chunks*$chunk;
	my $left = one_to($chunk-1)*($chunks+1);
	return $right+$mid+$left;
}
