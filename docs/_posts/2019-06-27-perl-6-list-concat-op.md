---
layout: single
title:  "Perl 6 needs a list concatenation op"
published: true
---

Welcome to Perl 6 where everything is simple and easy to understand... sometimes?

Quick quiz: what does this code do?

    my @examples =
        (0,1,2,(3,4,5),[7,8,9]),
        [0, 1, 2, (3,4,5), [7,8,9]],
        gather do {.take for ^3; take (3,4,5); take [7,8,9]};

    for @examples {
      my $flat = .flat;
      say "{.WHO}: .flattens to {$flat.WHO}({$flat.gist})";
    }

Here's the output:

    List: .flattens to Seq((0 1 2 3 4 5 7 8 9))
    Array: .flattens to Seq((0 1 2 (3 4 5) [7 8 9]))
    Seq: .flattens to Seq((0 1 2 3 4 5 7 8 9))

Is that what _you_ expected? I think many would not. The subtle difference,
even after reading the documentation for `flat` isn't entirely clear.

This happens because an `Array` is not the same as those other types. It's
a "containerized" iterable. This means that you can't just take some value
that you know can be _iterated_ and call `.flat` on it without being
sure whether or not it's containerized. Ugly innit?

So, when you have two thingies and you want to bring them together
without flattening their contents, but as a single list, you can use
the slip operator, unary `|`, to flatten just the top-level of any
iterable thing into its expression. To put that in simpler terms:

    |$a, |$b

will give you the iterated contents of $a, followed
by the iterated contents of $b, all as a single thing (
called a `Slip`). It's a bit like:

    gather do {
      .take for $a;
      .take for $b;
    }

If you have many such sub-iterables that you want to
join together, you could join them using a map:

    @lists-of-lists.map: |*;

But this is klunky and not very clear. People don't think of `map`
as stripping levels of lists and a function that appears to return
two things, like this:

    sub foo($a, $b) { |$a, |$b }

should probably not be one that actually returns a single
list of the combined contents.

## Proposed solution

My solution (now available as [Operator::Listcat](https://github.com/ajs/perl6-Operator-Listcat))
is to add a new operator that performs this work as an
infix along with some extras:

    sub infix:<listcat>(@a, @b) is equiv(&infix:<~>) is export { |@a, |@b }
    sub infix:<< ⊕ >>(@a, @b) is equiv(&infix:<~>) is export { @a listcat @b }
    augment class List {
        method sling(List:D: *@lists) { [listcat] self, @lists }
    }

There are three things here:

* The infix operator "listcat" that works as `<a b c> listcat <x y z>` and
  returns `<a b c x y z>` but without flattening and further than one level.
* The Unicode alias `⊕` for listcat that evokes the Python (among a small
  number of other languages') convention of using
  `+` for this purpose without actually muddying the type waters.
* A modification to `List` that adds the `sling` method that performs
  a `listcat` between the `List` object that it's called on and its
  arguments, returning the unified list.

Note that in current rakudo, that last one doesn't work the way you might
expect. Derived classes currently do not resolve augmented methods in
their parents (see the discussion in https://github.com/rakudo/rakudo/issues/1923
for details).

