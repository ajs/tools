---
layout: post
title:  "Perl Weekly Challenge 014.1"
published: true
---

This week's challenge starts off with something Perl 6 can do exceedingly well: filter values
based on fixed criteria. The problem statement:

_Write a script to generate first 10 strong and weak prime numbers._

_For example, the nth prime number is represented by p(n)._

```
  p(1) = 2
  p(2) = 3
  p(3) = 5
  p(4) = 7
  p(5) = 11
```
_Strong Prime number `p(n) when p(n) > [ p(n-1) + p(n+1) ] / 2`_

_Weak Prime number `p(n) when p(n) < [ p(n-1) + p(n+1) ] / 2`_

Interestingly, we have our solution partially written for us, above. All we need to do
is put that pseudocode into Perl 6 like so:

```
my @primes = (2,3,*+2 ... *).grep: {.is-prime};

my @strong-primes = lazy @primes.pairs.grep(-> (:$key, :$value) {
	$key != 0 and $value > (@primes[$key-1] + @primes[$key+1])/2.0}
).map: {.value};
my @weak-primes = lazy @primes.pairs.grep(-> (:$key, :$value) {
	$key != 0 and $value < (@primes[$key-1] + @primes[$key+1])/2.0}
).map: {.value};
```

and as a bonus, the balanced primes:

```
my @balanced-primes = lazy @primes.pairs.grep(-> (:$key, :$value) {
	$key != 0 and $value == (@primes[$key-1] + @primes[$key+1])/2.0}
).map: {.value};
```

But that's a lot of duplicated code... what can we do about that? Well...

Perl 6 lets us pass a block to a subroutine with placeholder variables,
so we can define the generator for each of these sequences as a
function taking one `Code` parameter:

```
sub powerful-primes(&cmp) {
	lazy @primes.pairs.grep(-> (:$key, :$value) {
		$key != 0 and cmp($value, (@primes[$key-1] + @primes[$key+1])/2.0)}
	).map: {.value};
}
```

And then we can call this like so:

```
my @strong-primes = powerful-primes({$^a > $^b});
my @weak-primes = powerful-primes({$^a < $^b});
my @balanced-primes = powerful-primes({$^a == $^b});
```

Here's the whole program with tests.

```
use Test;

my @primes = (2,3,*+2 ... *).grep: {.is-prime};

sub powerful-primes(&cmp) {
	lazy @primes.pairs.grep(-> (:$key, :$value) {
		$key != 0 and cmp($value, (@primes[$key-1] + @primes[$key+1])/2.0)}
	).map: {.value};
}

my @strong-primes = powerful-primes({$^a > $^b});
my @weak-primes = powerful-primes({$^a < $^b});
my @balanced-primes = powerful-primes({$^a == $^b});

for (
	 ("strong", @strong-primes, [11, 17, 29, 37, 41, 59, 67, 71, 79, 97]),
	 ("weak", @weak-primes, [3, 7, 13, 19, 23, 31, 43, 47, 61, 73]),
	 ("ballanced", @balanced-primes, [5, 53, 157, 173, 211, 257, 263, 373, 563, 593])) -> ($name, $seq, $oeis) {
	say "Calculating $name primes...";
	say "First 10 $name primes: {$seq[^10]}";
	cmp-ok $seq[^10], '~~', $oeis, "OEIS canned values compared";
}
```
