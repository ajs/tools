---
layout: single
title:  "Zen and the Art of Perl 6"
published: true
---

I'm a Python programmer in my day job, and though it's less often heard than
in the early days of Python, the "Zen of Python" is still an oft-cited mantra.
It goes:

* Beautiful is better than ugly.
* Explicit is better than implicit.
* Simple is better than complex.
* Complex is better than complicated.
* Flat is better than nested.
* Sparse is better than dense.
* Readability counts.
* Special cases aren't special enough to break the rules.
* Although practicality beats purity.
* Errors should never pass silently.
* Unless explicitly silenced.
* In the face of ambiguity, refuse the temptation to guess.
* There should be one-- and preferably only one --obvious way to do it.
* Although that way may not be obvious at first unless you're Dutch.
* Now is better than never.
* Although never is often better than *right* now.
* If the implementation is hard to explain, it's a bad idea.
* If the implementation is easy to explain, it may be a good idea.
* Namespaces are one honking great idea -- let's do more of those!

I think that it's worth noting that Perl 6 ends up being aligned with the Zen
of Python on most points, and where it's not, it's clear that that's a choice,
not an artifact of failure to design. To that end, I want to go over each of
these (or a couple at a time where they relate to each other) and see how much
they can illuminate the philosophical similarities and differences of the two
languages.

## Beautiful is better than ugly

I find that Python programmers don't actually want beauty; they want Spartan
simplicity which can be beautiful in its own way, but so can many other sorts
of code. I would re-phrase what most Python folks mean by this as, "Classical
is better than Baroque."

Perl 6 believes that beauty is a key advantage in good code, and seeks the
most powerful array of tools to promote that beauty. How they are applied and
whose conception of beauty is being employed is strictly a matter for the
individual programmer or project (that is, the local culture) to determine.

## Explicit is better than implicit

Perl 6 actually walked away from a great deal of Perl 5's implicit behaviors.
It still has many (as does Python) but only where they tend to be the most
intuitive. Take this code for example:

    .say for @items;

The loop variable is implicit, but the *behavior* is explicit. Loop over
`@items` and do the `say` thing on them.

## Simple is better than complex

Simplifying code is something that Perl 6 constantly seeks to do, but it does
so by taking on that complexity, internally. For example, hyper-operators are
extremely complex because they have all of the behaviors of all of the
operators that use them. In this code:

    [==] @a <<->> @b

we return `True` if all of the differences between same-indexed entries in
`@a` and `@b` are the same (e.g. `@a=1, 2, 3` and `@b=5, 6, 7`). This is code
which anyone coming from other languages is going to have to puzzle out with
docs-in-hand, trying to understand the complexities of `<<...>>`
hyperoperation and `[...]` hyper-reduction. It's not simple stuff *for the
language or its learning curve*.

But once you know the language, the above is far, far simpler to read *and
maintain* than:

    for zip(@a, @b) -> ($a, $b) {
        state $diff;
        return False if $diff.defined and $a - $b != $diff;
        $diff = $a - $b;
    }
    return True;

This is because the symbolic density of hyper-operators also comes with a lack
of ambiguity and quite a bit of clarity of purpose.

* Complex is better than complicated.

I would argue that this is a guiding principle of Perl 6. The example in the
previous section is *complex* in terms of what it's doing, but it's not
complicated in the sense that it doesn't require the user who knows the
language to perform any kind of sleuthing to figure out what it means. The
docs are clear and the code is too. It's just complex code.

* Flat is better than nested.

Here is one place where Perl 6 and Python diverge, and it's clearly a choice.

There are two places that Perl 6 deals with heavily nested constructs:

It's sometimes necessary and desirable to flatten code, but Perl 6 supports
and encourages deeply nested constructs with `.map`, `.grep`, hyper-invocation
(`>>.`) of methods, etc.

We even end up seeing blocks of code mid-statement:

    my @key-info = @pairs>>.key.map(-> $name {
        $some-api.look-up-name($name);
    });

There are real differences in the philosophy of the two languages, here.
Python wants to take the parental approach of preventing behavior that *could*
result in maintainability problems while Perl does two things: it leaves the
case-by-case situation up to the programmer and at the same time takes on the
difficult challenge of trying to figure out what it is about that cumbersome
code that's difficult and solving the problem at the language level.

The second case is namespaces, and in that sense, Perl 6 is somewhat agnostic,
but most programmers don't seem to have any desire to create deeply nested
namespaces (e.g. `File::System::IO::Binary::ReadWrite::Read::Utilities`), so
it seems a rather academic point.

All that being said, I think that the driving idea here was a relatively new
one circa Python's introduction, and it's one that both languages embrace:
code should be broken up into comprehensible chunks where possible. A method
on a class should read more like a sentence than a paragraph, and certainly
not a chapter! That's a good guiding principle in *any* language.

## Sparse is better than dense

Perl 6 aims for *symbolic* density with its "Huffman coding the language"
approach, but that actually aims to reduce the density of *end-user code*. In
that respect, the two approaches are deeply aligned, but with very different
takes on implementation.

## Readability counts

I find Perl 6's readability features to be tremendously beneficial, from
regexes:

    regex{ <alpha> <alnum>* }

to comments:

    for get-keys #`(sorted list) -> $key { ... }

to the visual simplicity of passing variables as named arguments:

    my $db-handle = get-db-handle;
    my $object    = get-next-object;

    add-to-database(:$db-handle, :$object);

Perl 6 arms its uses with tools for readability, and then stands back and lets
them decide how to apply them. In the wild, I find that code tends to be
extremely readable as a result because users tend to like the idea of making
their code accessible *when doing so is made easy by the language*.

## Special cases aren't special enough to break the rules

This is another philosophical point that Perl 6 and Python *can* differ on,
though it's more nebulous than previously. For example, Perl 6 encourages
domain specific languages (DSLs) and other features that modify the language
itself to suit specific use-cases. "All's fair if you pre-declare," was a
foundational principle of Perl 6.

It's not yet all that clear how that will play out because we haven't seen
enough use of such advanced features in the wild, yet, but in other languages
that support such features they have always been tremendously beneficial.

## Although practicality beats purity

I would argue that here, we're into the territory of rules that Perl 6 takes
more closely to heart than most other languages. DSLs are, again, a great
example of how that's the case. Even regexes are a divergence from the purity
of the language into a wholly separate sub-language that is non-the-less a
first-class element of the specification. Why? Because it's practical to be
able to freely riff between the assertive style of regexes and the
process-oriented style of "normal" code.

## Errors should never pass silently

## Unless explicitly silenced

Perl 6 supports `fail`. This is an important concept in Perl 6, and
fundamental to many sorts of state-driven behavior (obviously regexes, but
also lots of lazy operations). Core to `fail` is the idea that certain types
of errors should not be execution-stoppers until/unless there is an attempt to
use them. For example, the `Math::Sequences::Integer` module has many integer
sequences that have a few sample values, but no generating function. These
look like:

    @sequence = 1, 2, 3, 4, {fail "not implemented"} ... *;

To the user of the library it looks like a valid sequence of integers. It can
be copied around and its values stored, etc. But any attempt to check the
contents of a value after the fifth one will result in an exception.

That being said, the core concept, here, is that code should deal with
exceptional circumstances rather than ignoring them, and I doubt that there
are many who would disagree.

## In the face of ambiguity, refuse the temptation to guess

This one has always confused me. It's not clear what this is a call to...
Cultural norms? Online forums? Reading the docs? I think this one could have
been clearer if it was just "In the face of ambiguity, read the docs." In
general, the negative assertions in this list are less helpful than the
positive ones.

## There should be one-- and preferably only one --obvious way to do it

Yeah, so I don't think anyone is surprised that this is a split between the
two... but what if I told you that it wasn't?

Perl 6 seeks to provide many ways to do the same thing, but it's almost always
the case that there's a right way and a wrong way to approach a problem for
some set of contextual criteria. Python tries to posit a universal set of
criteria, and that's obviously false (just ask a numpy programmer and a "pure"
Python programmer). Different tasks have different optimization criteria.
Sometimes it's performance, sometimes it's code size, sometimes it's long-term
maintainability, sometimes it's readability by programmers outside the
language's cultural niche, sometimes it's lack of external dependencies.
Usually it's some weighted combination of all of the above.

For example, here are three ways of testing a string for being all upper-case
in Perl 6:

    /^ <upper>* $/

    .uc eq $_

    not .comb.grep({not .uniprop('Uppercase')})

The first, I think many would consider the most readable and maintainable. The
second has more conceptual overhead than the others and accepts different
inputs, but in current implementations happens to be the fastest. The third is
the most generalizable to future needs if you expect to have to add in more
criteria that aren't easily matched in a regex.

So, ultimately, the burden falls to the programmer in any language to
determine what their code, users and maintainers need. Does that mean that the
language has no responsibility in resolving ambiguity? No! Indeed, Python's
fanatical focus on a lack of ambiguity has borne some valuable fruit, and
while I would never subject Perl 6 programmers to such fanaticism, I might
reap some of the benefit of Python programmers having suffered that pain for
us...

For example, having a comprehensive cookbook of Perl 6 tasks with well
surveyed trade-offs, best practices and considerations would certainly help
users to write maintainable code.

## Although that way may not be obvious at first unless you're Dutch

Being Dutch is an advantage, agreed. :-)

## Now is better than never

## Although never is often better than *right* now

I would add an addendum to these two: lazy is often better than either!

## If the implementation is hard to explain, it's a bad idea

This is just patently false. The implementation of an Adversarial NN is very
hard to explain, but it's certainly not a bad idea! I would re-phrase this:

If the implementation cannot be broken down into easily explained components,
then it is a bad idea. Both Perl 6 and Python would generally tend to agree on
this modified statement.

## If the implementation is easy to explain, it may be a good idea

This isn't really a positive or negative assertion, so we can all agree that
it's too hard to explain and thus a bad idea. :-)

## Namespaces are one honking great idea -- let's do more of those!

Ah, the 90s! It was a simpler time! Programming languages have moved on. Perl
6 is carving out some of its own niches in the language capabilities
landscape.

## The Zen of Perl 6

So, to recap, here's what I believe is the true Zen of Perl 6:

* Beautiful is better than ugly.
* Explicit is better than enigmatic.
* Clarity is better than clever.
* Modularity is better than fugue.
* Readability counts.
* All's fair if you pre-declare.
* But play fair with your pre-declarations.
* Practicality beats purity.
* Errors should be presented to those that need to deal with them.
* If the right solution isn't clear, lean on the community.
* For any given context, the most optimal solution should be available.
* Lazy can be better than immediate.
* If components are too complex to explain then they're too complex to be
  components.
* Grammars are one honking great idea -- let's do more of those!
