---
layout: single
title:  "The Perl Family Queue"
published: true
---

> *Nothing's the same anymore*  
  \-Babylon 5

When it became clear that Perl 6 was not going to be just the next version of
Perl 5 but its own language, the community began to rumble. There were
discussions about whether or not to rename the language as early as the
mid-2000s, but today Perl 6 has been released and has had its first major
post-release update, 6.d. There are those in the community who want to rename
it, and Larry Wall&mdash;initial creator of Perl&mdash;[weighed in on the
resolution with the name,
"Raku"](https://twitter.com/zoffix/status/1058796898235105280) late last year.
Reflecting on this, though, it seems a bit late to rename. "Perl 6" as the
name of the language is embedded in the source, dozens of libraries, third
party tools, markup/down systems, online forums, books, etc. It's like RMS's
attempt to re-brand Linux systems as "GNU/Linux" which still has echos today
and many users end up wondering why Ubuntu is GNU/Linux but Red Hat is
Linux... do they differ that fundamentally? Is RedHat lacking essential GNU
tools? Does a Perl 6 syntax plugin for my editor work with Raku? Can I import
a Perl 6 module into a Rakudo Raku (or is that Raku Rakudo?) program? I know
that those are nonsensical questions, but users will have them for *years if
not decades* regardless of how many blog posts try to explain the (now)
history!

I'm frankly skeptical that a declarative name change would take, even if it
were a good idea...

And that's the rub. Is it a good idea? It breaks Perl 6 off as a non-Perl and
it's simply not that. Larry made an initial comment long ago that I think
actually solved the problem, but what he said didn't quite register with
everyone and no one followed it to its logical conclusion.

He said that Perl 6 and Perl 5 are both members of the Perl Family of
languages (I'm going to capitalize "Perl Family" as the name of the whole
collective). This has tremendous implications! Is Perl 7 some as-yet
unspecified language? If so, can it be *my pet language*? How Perl-like does it
need to be? Does 7 look more like 5 or 6? What would a major revision to the
Perl 5 language that doesn't stem from Perl 6 be numbered? Is there an
expectation that a language in the Perl Family will be initiated by those in
the development teams of an existing version?

As you can see, this introduces more questions than it answers, but I don't
think that's a bad thing. Indeed, most Perl innovations have been so. The goal
here is to answer a few of those questions and to set the groundwork for how
we can arrive at the next ones.

## The Queue

Larry's use of the word "family" brings to mind a group of people who are
related by no choice of their own, and might not necessarily get along or
agree to many, if any conventions. Instead, I'd like to agree that we can view
our family as a queue. One should have the expectation that it's possible to
get "pushed" onto this queue electively, in which case you receive the largest
index.

But we'll have Perl 7,000 the day after making such a plan available, so I'm
going to propose two parts of a solution. The first is the more conservative
and least impactful part that addresses what we have today, though it has
plenty of impact, and the second is a bit more speculative and the machinery
of it may or may not appeal to everyone.

## Version Numbering

If we are to accept that "Perl 5" is the name of a language, then it becomes
impossible for that language to ever change its major version number. That
stunts the language in an unreasonable way, and I think we need to re-align
expectations around that reality and re-calibrate versioning to remedy the
constraint. As such, I'd like to propose the following versioning scheme
across all Perl Family languages in the queue:

```
Version number: 5.30.0.1
Language Name: Perl 5
Language ID: 5
Major version: 30
Minor version: 0
Patch release: 1
```

This does ***not*** mean that there can't be a `5.30.0.1.1`, but it means that
across all languages in the queue, the above expectation should be valid. The
only constraint on this process being that users have a reasonable expectation
to patch releases not breaking their code due to specification changes while
minor releases should have some sort of deprecation cycle or other way of
ensuring that jumps between minor versions are not only possible, but
reasonable.

So the Language ID is a unique, integer key which identifies a language,
ordered in time with respect to all other entries by when the identifiers
were issued (which may or may not related directly to the age of the
language, see below).

But what does this relate to? Within the queue, all we care about is the
specification and the *existence* of one or more implementations.
Implementations and specifications might be the same (Perl 5)
or they might be closely related but separate (Perl 6). They could even be as
broadly detached as the ANSI C spec and GCC! That's all up to the
language. But the queue needs to know where the spec stands.

[Perl 5 has an interesting numbering
convention](http://learn.perl.org/faq/perlfaq1.html#Which-version-of-Perl-should-I-use).
It reserves the odd numbered "major" number for development releases. It's my
feeling, but obviously up to them, that this is a good thing to be
maintained, but should be pushed down one level. So `5.30.0.0` would be a
production release while `5.30.1.0` would be a development release. This
means that bumps to the major number could flag incompatible changes such as
a replacement to a major component such as the object system. Again, that's
all convention that's entirely up to the language itself, but it would make
some sense and would give everyone plenty of room to breathe.

Perl 6 has been using non-numeric versions like 6.d. This is also fine. It
would seem reasonable to require that a base-36 numeric sort of version
components is stable with respect to release date (e.g. in Perl 6,
`$major.parse-base(36)` increases for each subsequent major version component)
but other than that I don't think that the queue should care. There's no
requirement that a version use all 36 digits in a base-36 identifier, of
course, and Perl 5's mostly base-10 history is not a violation of this
specification.

## The Registration Process

This is a bit more speculative, and I'm well aware that it might not be the
most broadly accepted option, but please bear with me until the end and see
how you think the whole thing would operate.

The queue is composed of sequential numeric language identifiers. But what
kind of number? Obviously, it has a real part... but is there an imaginary
part? I think there should be. In fact, I think that solves the major problem
with the idea of a Perl Family language queue: the fact that language ideas
come and go ephemerally, but languages that we consider "real" are fewer and
further between. So, let's take the point of view of an aspiring language
designer. I first need to compose a basic outline of my language's name,
goals, ancestry within the family and major technical features. For Perl 6
this might be the initial announcement and RFC connected to the State of the
Onion 2000. It's not a high bar, and it might be that a language meeting this
bar never gets a line of code, much less a production-ready implementation. So
it is subjected to a basic amount of scrutiny by the community and then
assigned a complex number of the form:

    {m+n*i}.0.0.0

Where n is a monotonically increasing integer value assigned to each new
language proposal and m is the current next unallocated entry in the queue at
the time (e.g. currently 7). Thus, [the recent proposal for a Python-like Perl
6 variant](https://old.reddit.com/r/perl6/comments/bu0l00/pyrl/) might come in
at `7+1i.0.0.0`. It is now free to keep bumping that version as normal and can
remain with that versioning forever if it wishes. However, once my language
has a quasi-stable implementation (let's say Perl 6 back in the Pugs days or
Perl 1) then I can apply to actually allocate the next available number
without an imaginary component. By that time, perhaps some other language has
matured faster. Perhaps Perl `7+2i` has become stable enough that it has been
moved to **Perl 7**. So my language moves from `7+1i` to `8` and officially
becomes **Perl 8**. Does that mean that Perl 8 is ready for prime time? No,
but it does mean that it's demonstrated a level of seriousness about being in
the Perl Family that it is ready to begin allocating more prime real estate in
the versioning landscape.

This requires a registrar, but if we can manage CPAN as a shared resource
between Perl 5 and 6, I think it's possible to manage some version number
allocation.

It's also a bit hokey, and that's not accidental. I strongly believe that
there should be a sense that getting one of these imaginary identifiers
should feel less than permanent. It shouldn't be the case that applying to
become a fully realized (pun intended) language in the Perl Family feels
like an unnecessary extra step. Every imaginary Perl Family language should
want to grow up to be a *real* language!

Okay, that's enough puns... maybe.

## Other Bits

That's the proposal. Now on to some of my own thoughts as to what this all
means...

### All in the Family

So, what constitutes a Perl Family member language? That's hard, but I think
it requires a few things:

1. Its specification cannot be wholly within another language. That is, a
   simple slang in Perl 6 is not Perl 7. Perl 7 might get an implementation as a
   slang in Perl 6, but it should stand on its own as well. This is probably
   the hardest part to get right. It's a very fuzzy border, but there are
   definite black and white areas as well, so I think it works as a high-pass
   filter.

2. It should have a practical connection to its ancestor languages. If a
   language is further down the queue than you are (e.g. has a smaller number)
   then it should be a reasonable expectation that it is composed of features
   that either emulate, consciously drop, improve on or seek to correct features
   in that language. For example, one could see an argument that both PHP and
   Ruby were within the Perl Family in this sense (I'm retroactively deciding to
   call them `5+1i` and `5+2i` respectively and invite them to apply for real
   version numbers at their leisure...), but Java certainly was not. It
   doesn't take Perl into account much at all, and is much more clearly a branch
   from the C/C++ portion of the language space.

3. It must not be a trivial modification to an existing language. That is,
   Perl 5, but with Moose built-in is not a langauge specification. It might be
   the first step in creating one, but it needs to be more than "you don't have
   to 'use Moose'" to meet this criteria.

### Questions

Arising from the above, I have some questions.

* Would a JSON-like specification for Perl data be allowed to apply for a
  number? Should such DSLs get their own namespace (e.g. `Perl DSL 1.x.y.z`)
  or does it just not matter? I'm inclined to the latter.
* In a case like Ruby, where the new language has no real pretense of being
  a Perl Family member, what happens if someone applies *for them*?
* Would it make any more or less sense for imaginary languages to all get
  their real parts bumped whenever a new language ID was allocated? Is
  this a reasonable level of disruption given that the language is still
  in early specification stage?
* If we agree to the above, then do imaginary languages exist in a sparse
  namespace where new specs can claim now-realized languages' IDs?

### What's In a Name?

There is no requirement that a language treat its Perl Family queue identifier
as its "name". That is, Perl 7 might be more widely known to the world as
Gueuze, or it might be more complicated, as in the Perl 6 world where Perl 6
the spec is also known as Raku and there are many implementations current and
obsolete, all with their own names.

Being in the Perl Family merely means that the language can be considered
fundamentally "Perlish" but that doesn't mean that anyone ever calls it by its
maiden name...
