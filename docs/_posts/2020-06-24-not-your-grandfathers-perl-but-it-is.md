---
layout: single
title:  "Perl 7: Not Your Grandfather's Perl... But It Is"
published: true
---

## Perl 7 cometh

When the Perl 5 community forced Perl 6 to change its name, I held out
a modicum of hope that this would turn out to be for the best. Perl 5
*could* turn things around. They *could* use this as an opportunity to
release a Perl 7 that took the best of Perl 6 that it could without engaging
in another 10-year development hell and release a modern langauge to
rival the likes of Python 3 and newer entrants.

But ... no. It's basically Perl 5, but with some startup pragmas turned on.
That's it. Yes, it supports Perl 5's kind of hackish, half-way
function signatures so you can (optionally, still) use formal parameter
passing. Yes, it turns off support for one old crufty bit of syntax.

But it's still Perl 5 more or less.

## Perl 8?

So, the plan is that Perl 7 is not a destination, but a starting point.
The plan currently involves a series of semi-experimental steps forward
and then a Perl 8 that's the "real future". Do I believe this? No.

Why? Because in the past amost 30 years, Perl 5 hasn't managed to do that,
even though it has tried several times. Perl 5 is a language, but it's also
a culture, and that culture is founded on the notion that everything
is more or less valid. So when considering what to jetison to move
forward, the answer has always been, "well, maybe something, but not
anything *good*!" Of course "good" turns out to be just about everything
from someone's perspective.

## Python's object lesson

In the before time, Python 3 was mocked by the Perl community for being
not ambitious enough, and yet somehow too much of a step forward, losing
the trust of its users by making changes like forcing a clumsy Unicode
implementation on everyone.

But Python learned from the mistakes it made, and hadn't bitten off so
much in the transition that it lost its way. It turns out, in retrospect
to have been a poorly managed, but highly valuable exercise in
shaking up the language. Many old users wandered away, but hundreds of
thousands, if not millions of new ones embraced it. Python, today, is
shockingly easier to use than Perl, even providing tools for many of the
features that Perl long held as its advantages (such as interpolating
variables into strings).

Meanwhile, Perl 7 *still* has not turned on Unicode I/O by default.

## Is Perl finally dead?

It might be. Or it could be that the Perl 7 gambit succeeds and draws in
a new crop of developers who want to work on and improve the language.
I'm hoping for, but not betting my career on the latter.
