---
layout: single
title:  "Perl6 Integer Sequences Needs You!"
published: true
redirect_from:
  - /2019/06/12/perl6-integer-sequences.html
---

The Perl6 library [Math::Sequences](https://github.com/ajs/perl6-Math-Sequences)
has quite a lot of utility buried in it, from defining helper functions like
binary partitions to the somewhat frivolous FatPi that gives you a rational
representation of pi to any desired precision. But at its core is the list
of "[core OEIS sequences](http://oeis.org/wiki/Index_to_OEIS:_Section_Cor)"
which are the most widely used sequences of integers.

These sequences include things like the prime numbers, the digits of pi and
the sequence of all zeroes. They come in handy for all sorts of important
applications and the `Math::Sequences` library collects them for everyone
to use.

There's just one problme: it's a lot of work, and we need you to help!

## Failing with style

Currently, there are many squences that are defined, but most are just
stubbed like this:

    # A000005 / divisors
    our @A000005 is export = 1, &NOSEQ ... *;

In this example, the `A000005` sequence (the "divisors") is defined
as `1`, followed by this `&NOSEQ` thing which generates all of the rest.

It turns out that NOSEQ is defined by our library and just returns a
"failure" exception that says "This sequence has not yet been defined."

The great thing about fialures is that they don't happen until you try
to use the value. So we can improve this stub by giving it the canned
values from the [OEIS page for the sequence](https://oeis.org/A000005).

    our @A000005 is export = 1, 2, 2, 3, 2, 4, 2, 4, 3, 4, 2, &NOSEQ ... *;

How many canned values to grab from the OEIS entry is arbitrary, but
I usually try to keep the entry to one, reasonble length line.

## But really...

Of course, this is just an improved stub that has some real values
people can use, but what we ideally want is the complete list!

So we could define this sequence correctly:

    our @A000005 is export = ℕ.map: -> $n {
        factors($n, :self).unique.elems + 1;
    };

The `factors` function is defined in the `Math::Sequences::Integers`
module as a utility helper, though it doesn't currently have a
`:self` flag, which I'm using notationally here to mean that we
include 1 and the `$n` itself, so that functionality would also
have to be added to the `factors` helper.

## How can you help?

What this module needs is two-fold. The firs part can be done by
anyone with time. The second part really requires people who know
more than high school math and Perl 6 to craft the final
implementations of the currently undefined sequences.

So for anyone that has time, here's what I need:

* Fork the repo https://github.com/ajs/perl6-Math-Sequences on github
* For the sequences currently defined as `1, &NOSEQ ...` replace
  that `1` with a short list from the actual canned values on
  the OEIS site for that sequence. The canned values should not be
  too long--try to keep it to a single line of reasonable width.
* Run the tests via `perl6 -I lib t/OEIS.t` which validates
  that you didn't typo anything.
* Save that work on a branch and issue a pull request against my
  repo with your work.

If you know the math behind a given sequence or can puzzle it out
from the description on the OEIS site, then you could actually
define the sequence fully and get rid of the `&NOSEQ`, but both
sorts of work are needed.

For the full implementations, don't be afraid to add helper
functions to the module. Each helper should include the
`is export(:support)` modifier if it is something that others
would benefit from using.

I've already done quite a few of the sequences, but there are
a lot of them, and some require more understanding than I have.
Your help is greatly appreciated!
