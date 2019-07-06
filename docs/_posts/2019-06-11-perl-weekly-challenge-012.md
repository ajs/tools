---
layout: single
title:  "The Perl Weekly Challenge 012 Entries"
published: true
---

## The Entries

In this week's
[Perl Weekly Challenge](https://perlweeklychallenge.org/blog/perl-weekly-challenge-012/)
I submitted solutions for:

* [The Euclid Numbers non-prime challenge](https://github.com/ajs/tools/blob/master/puzzles/perlweeklychallenge/euclid-challenge.p6)
* [The common directory paths challenge](https://github.com/ajs/tools/blob/master/puzzles/perlweeklychallenge/common-directory-paths.p6)

You can see all of the entries here: [Perl Weekly Challenge Club](https://github.com/manwar/perlweeklychallenge-club/tree/master/challenge-012).

## Euclid

The Euclid challenge is interessting to me mostly because of my work on the [Math::Sequences](https://github.com/ajs/perl6-Math-Sequences) module for Perl 6. This module takes the core 
[On-Line Encyclopedia of Integer Sequences® (OEIS®)](https://oeis.org/) enttries and makes them available as Perl6 arrays, so that you can do things like:

```Perl6
    use Math::Sequences::Integer;
    
    for @A010051 -> $prime {
      say "$prime is a prime number!"
    }
```

The full list of core sequences are listed here: [Core Sequences of the OEIS](http://oeis.org/wiki/Index_to_OEIS:_Section_Cor#core).

So, to demonstrate how one might add to this list a new entry, I defined both the primes (already in the module) and the Euclid numbers (oddly, not an OEIS core entry) in this way. Here's just that part:

    #= OEIS sequence A010051: the primes
    sub primes() { (2,3,*+2...*).grep: *.is-prime }
    # Math::Sequences entry for the primes:
    our @A010051 = lazy primes;
    
    #= OEIS sequence A057588: the Euclid numbers
    sub euclids() {
        gather for primes() -> $p {
            take ((state $t=1) *= $p) + 1;
        }
    }
    # Math::Sequences entry for the Euclids:
    our @A057588 = lazy euclids;
    
### overview

Things to note, here:

* In both cases, the function returns an iterator that will go on forever. The use of the `lazy` keyword prevents the array assignment from stalling and only populates the array as needed.
* I take advantage of the fact that Perl6 has built-in handling for prime testing by filtering the odd numbers (and `2`) by the method `.is-prime`.
* The use of `state` is perhaps a bit unclear to someone not familar with Perl6, but once you get this it will be so important that I'm going to dedicate a section below to it.
* There is an extremely common paradigm, here: `gather for some-source -> $var { take $var.something }` This is what an iterator looks like in Perl6. The under-the-hood secret, here, is that the block of the for loop is really just an anonymous subroutine. You can even write the `-> $param { ... }` part without a for loop.

### state

The `state` keyword is like `my` or `our` in that it introduces a new variable, but the variable it declares is only initialized the first time it is encountered. Thereafter, it behaves similar to a global declared with `our`, but cannot be seen outside of the current scope.

In other words, this is a lexically scoped variable whose _state_ doesn't change when it goes out of scope.

In the challenge, it's used to keep track of the running product of all primes. So let's unpeel that...

    state $t=1

This is no different from any other variable declaration except that the assignment is only performed once.

    ((state $t=1) *= $p)

Each time this is executed, the state variable `$t` will be multiplied by the next prime number `$p`. Thus, this keeps a running product of all previously seen primes in `$t`.

    take ((state $t=1) *= $p) + 1;

Having created our running product, we add the current product plus one to the iterator. The addition of one doesn't affect the state variable which is only modified by the `*=` operation here, so we keep a pure product of the primes and only add one to each value as it gets sent to the consumer of this iterator.

### output

For all of that work, all we do is output the result:

    say euclids.grep(not *.is-prime).first;

In other words, print the first value from `euclids` that is not prime.

## The Common Paths Challenge

The next challenge was more interesting algorithmically, but the problem is that Perl6 trivializes it by providing some really advanced tools. Fortunately, this gives us a chance to show off those tools!

### defining an operator

    sub infix:<common-prefix>(@a, @b) {
        gather for @a Z @b -> ($a, $b) {
            ($a ~~ $b and take $a but True) or last;
        }
    }

This is a simple iterator over the zipped values of the two arrays, but there are two things of note:

* `take $a but True` gives a reuslt that is True in a Bool context. This is important because if the input is `/foo/bar` then we're going to split it into `'', 'foo', 'bar'` and that first empty string will cause our loop to end! With `but True` we only end the loop when the two input path elements do not match (thus failing the first half of the expression).
* The subroutine itself is a user-defined operator called `common-prefix`. This operator is an `infix` which means it operates on two values on either side, much like the `+` or `*` operators.

### using our operator in a reduction

    sub common-leading-paths(@paths, :$separator='/') {
         return join $separator, [common-prefix] @paths.map: *.split($separator);
    }

In this sub, which implements the core requirement of the challeng, the `common-prefix` operator is surrounded by `[...]` which turns it into a reduction operator. The simplest example of a reduction operator is `[+]` which gives the sum of its argument's contents. But there's nothing special about `[+]` and any infix operator, even user defined ones, can go inside those brackets.

### final result

So if our inputs are `'a/b/c'`, `'a/b/d'` and `'a/b/q'` then we first reduce (after splitting) `<a b c>` and `<a b d>`. Here's how those steps go:

* `'a' ~~ 'a'` matches so we get `'a'` as the first element.
* `'b' ~~ 'b'` matches so we get `'b'` as the second element.
* `'c' ~~ 'd'` does not match, so we abort the loop inside our operator

Next, we'll reduce that resulting list `<a b>` against the next split-up input, `<a b q>`:

* `'a' ~~ 'a'` matches so we get `'a'` as the first element.
* `'b' ~~ 'b'` matches so we get `'b'` as the second element.
* Because `Z` ends as soon as an input is exhaused and our intermediate result, `<a b>` was only two elements, we don't get to the `'q'`

Thus, the final result is `<a b>` which then gets re-joined with the separator, giving, `a/b`
