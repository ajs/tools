---
layout: single
title:  "Perl 6 needs a list concatenation op"
published: true
---

Here's a mistake that's all too easy to make:

    sub things() {
      my @thing1 = get-things();
      my @thing2 = get-more-things();
      return flat @thing1, @thing2;
    }

Looks good, right? Nope! The `flat` routine will flatten _everything_ in
its arguments, and that's probably not what you wanted, here. You meant to
return the things that `get-things` returned joined with the things that
`get-more-things` returned, but you probably didn't mean to flatten
every data structure under those...

The correct code would be:

    sub things() {
      my @thing1 = get-things();
      my @thing2 = get-more-things();
      return |@thing1, |@thing2;
    }

If you have many such sub-lists you could join them using a map:

    @lists-of-lists.map: |*;

But this is klunky and not very clear. People don't think of `map`
as stripping levels of lists and a function that appears to return
two things should probably not be one that actually returns a
list of things.

## Proposed solution

    sub infix:<listcat>(@a, @b) is equiv(&infix:<~>) is export { |@a, |@b }
    our &infix:<⊕> is export := &infix:<listcat>;
    augment class List {
        method sling(List:D: *@lists) { [⊕] self, @lists }
    }

There are three things here:

* The infix operator "listcat" that works as `<a b c> listcat <x y z>` and
  would return `<a b c x y z>` but without flattening.
* The Unicode alias `⊕` for listcat that evokes the Python convention of using
  `+` for this purpose without actually muddying the type waters.
* A modification to `List` that adds the `sling` method that performs
  a `listcat` between the `List` object it's called on and its
  arguments, returning the unified list.

Note that in current rakudo, that last one doesn't work the way you might
expect. Derived classes currently do not resolve augmented methods in
their parents (see the discussion in https://github.com/rakudo/rakudo/issues/1923
for details). But if I write this into a module, I'll manually define it
in relevant classes until the long-term fix is in.
