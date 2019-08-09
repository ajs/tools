---
layout: single
title:  "Perl 6 Is Not a Dialect"
published: true
---

Perl 6 is, sadly, once again undergoing a "should we rename the language"
debate. Those of us who have been around here for nearly two decades, now,
are really, really tired of this, but it happens from time to time like
Southern California earthquakes, and you learn to just casually stroll over
to a door-frame and mostly ignore them unless they get out of hand.

But I think there's an interesting element of this debate whenever it comes
up: that of the assertion that Perl 6 is a dialect of Perl 5. From the
title of this article, you know where I'm going to end up, but as J.
Michael Straczynski once said: the interesting part isn't where you end
up, it's how you got there and what happened along the way.

## What is a dialect?

> *The impossibility of stating precisely how many “languages” or
“dialects” are spoken in the world is due to the ambiguities of meaning
present in these terms, which is shown to stem from the original use of
“dialect” to refer to the literary dialects of ancient Greece. In most
usages the term “language” is superordinate lo “dialect,” but the nature
of this relationship may be either linguistic or social, the latter
problem falling in the province of sociolinguistics.*

> \- Einar Haugen<sup>1</sup>

> *Language and dialect exist on a continuum, and it is
often difficult to determine where a dialect ends and a language begins.*

> \- Walt Wolfram<sup>2</sup>

There is no universally acknowledged definition of a dialect (yes, you
can go to the dictionary and look up "the definition", but a dictionary's
job is to present the broadest semblance of a consensus on a moving
target as if it were a well-defined mapping... a very utilitarian lie).<sup>2</sup>
In the world where exceptions and specifics must be taken into account
(academia) there is no such clear consensus on a formal definition, but
we can outline it in basic terms.

"Language" delineates two "linguistic norms,"<sup>1</sup> that is, ways that we
communicate ideas. In Perl, we have a dual meaning for "communicate," as we
are both trying to communicate our intent with other programmers and
to communicate to a computer the specific steps that we wish for it
to take. This is why languages that seem excellent for communicating
intent to other humans are sometimes not good programming languages:
they do not suit this second function.

In spoken languages the distinction is typically based on the ability of
a speaker or writer to be understood by someone fluent in a regional or
social sub-division of the larger norm within which the two exist.
But this is complicated by political and cultural issues. For example,
Chinese has a number of "dialects" which are not universally
intelligible by other Chinese speakers. Meanwhile Norwegian and Swedish
are regarded as different "languages," yet their speakers can generally
understand each other.<sup>2</sup>

## Perl as language family

Perl is certainly a part of a larger language family. It is clearly
an Algol-descended language like most of the modern programming languages
in use. It is specifically closely related to C, AWK and C++ in terms
of the early development from versions 1 through 5, mostly during the 1990's
and very late 1980's.

It is also the ancestor of several languages in this family: PHP, Ruby
and to a lesser extent languages like JavaScript and Python which adopted
popular features from Perl and, in some cases, specifically diverged from
Perl syntax rather than merely happening to be different.

The Perl language family in these two senses is akin to the Romance and
Indo-European language families. If we think of Perl 1-5 as being equivalent
to Latin, then there are a whole tree of related languages like PHP, Perl 6
and the various pidgins of Perl created within the CPAN repository.
Meanwhile, if we think of Algol as Proto-Indo-European and all of the
branches on _its_ tree as being like the various Indo-European language
sub-families (Germanic, Romance, Greek, etc.)<sup>5</sup> then a picture emerges of
Perl as a significant branch-point in a very large continuum.

Perl 6 is not, strictly speaking, a sister-language of Perl 5, as Larry
offhandedly (and, I don't think with any intention of making a rigorous
claim<sup>4</sup>) referred to it. He's probably right to cast it in those terms,
though. While it's not strictly true that the two independently derived from
a common ancestor, it is true that they share language constructs in a loose
way that might suggest to a casual observer that this was the case.

## Perl 6

So, we arrive at what Perl 6 is. To dig into this, we need to look at where
its influences came from and how they evolved.

The language began, as most constructed languages do, with a coalescing of
diverse ideas in a prioritized way, but interestingly, this constructed
language was initially opened up to the entire Perl 5 community in an
"RFC" process which Larry Wall and others then boiled down into an essential
list of features from which Larry wrote the first Apocalypses, the core
statements of the goals, shape and specifics of the language.<sup>6</sup>

Perl 6's most obvious influences are from Perl 5, C++/Java,
Haskell and Smalltalk. Its lesser influences are legion, ranging from
CommonLisp on the niche historical side to Python on the modern
and popular side.

Typically, related languages are broken down into loose (and sometimes
highly varying) categories<sup>7, 7.1</sup> of:

* jargon - A simple set of adopted or invented words.
* pidgins - A pseudo-language that has no native speakers, but erupts from
  the interaction between two or more existing languages. Typically has
  little syntactic difference from its root language.
* creole - A hybridization of two or more languages that has native
  speakers.
* dialect - As discussed above, but typically with much more syntactic
  and structural differences than a pidgin.
* language - Again, as discussed above, but with the implication that there
  is a "language barrier" between speakers of different languages, or at
  least a significant enough cultural barrier as to serve the same purpose.

It is clear that Perl 6 would minimally meet the criteria for a creole,
as it will (may even already) have native speakers (people whose first
programming language was Perl 6). It also meets the requirements of a
dialect, having substantial structural differences between it and
any one of its contributing languages. These differences range from the
simple meaning of `%`, `@` and `$` to the entirety of its meta-object
system (which, just to confuse the point, has been partially back-ported
to Perl 5).

So that leaves us with only one distinction to make: can Perl 5 programmers
read Perl 6 code and visa versa?

I'm going to say a highly qualified "no". It's true that code like this
is not only readable in both languages, but means the same (or largely the
same) thing:

    my $x = 10;
    my @y = sort(0..($x-1));

But this is a contrived similarity. The fact that the above is more
naturally written, in Perl 6, as:

    my $x = 10;
    my @y = (^$x).sort;

highlights how even highly similar code differs substantially.

But to look at a more typical piece of Perl 6 code (from a previous
article):

    sub primes() {
        (2,3,*+2 ... *).grep: {.is-prime}
    }

It's probably not unreasonable to expect a programmer in any language to
be able to more or less puzzle out what's going on here, but there are so
many individual language constructs that the Perl 5 programmer will be
unfamiliar with that they are going to have to guess based on context,
rather than understand, just as the Python or C++ programmer would.

To me, this strongly suggests that Perl 6 is, in fact a language in its
own right, not merely a dialect of Perl 5. But now we come to the question
of culture. Is the separation of the cultures significant enough to warrant
solidifying that conclusion. Here I think it's less up to question.

The question you have to ask is this: would the two ever "re-join"
willingly? There are some practical issues, there, but ignoring those,
I think the answer is "no". Perl 5 is happy being Perl 5 and its users
don't necessarily *want* to be Perl 6. And obviously ditto the other way
around. In fact, Perl 6 has many users who don't *like* Perl 5 and never
programmed in it!

This, I think cements the answer: Perl 6 is not a dialect of Perl 5. They
are both Perl, surely, but they are not merely dialects.

## References

1. Haugen, Einar. "Dialect, Language, Nation 1." American anthropologist
   68.4 (1966): 922-935.
2. Wolfram, Walt. "Language ideology and dialect: Understanding the Oakland
   Ebonics controversy." Journal of English Linguistics 26.2 (1998):
   108-121.
3. Rickford, John. "LSA Resolution on the Oakland “Ebonics” Issue."
   Linguistic Society of America 1 (1997).
4. [The Slashdot Interview With Larry Wall](https://developers.slashdot.org/story/16/07/14/1349207/the-slashdot-interview-with-larry-wall).
   Slashdot (July 18, 2016)
5. Stria, Ida. "Inventing languages, inventing worlds. Towards a linguistic
   worldview for artificial languages." (2016).
6. Wall, Larry. [Apocalypse 1: The Ugly, the Bad, and the Good](https://www.perl.com/pub/2001/04/02/wall.html/).
   Perl.com (April 2, 2001)
7. Mühlhäusler, Peter. Pidgin and creole linguistics. Oxford: Blackwell, 1986.
   1. _via:_ Muysken, Pieter, and Norval Smith. "The study of pidgin and creole languages." Pidgins and creoles: An introduction (1995): 3-14.
