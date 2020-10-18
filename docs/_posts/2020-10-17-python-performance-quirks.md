---
layout: single
title:  "Python Performance Quirks: in vs. or"
published: true
---

In Python, the standard way to check for equality is:

```Python
if a == b:
    ...
```

You would think that being explicit would be higher performance in Python,
and when it comes to explicitness for multiple chained comparisons, there's
nothing that quite beats:

```Python
if a == b or a == c:
    ...
```

But it turns out that that's not the highest performance way to code
the comparison. This code does the same logical job using `in` and a tuple:

```Python
if a in (b, c):
    ...
```

Now, to my eye, that looks like it should perform worse. There's a data
structure that must be iterated over and a value compared to each
iterated item from the data structure, whereas in the first example,
we have two explicit and very simple operations for whcih no complex
datastructures need to be read, unless a, b or c are more than trivial
values, and yet in performance testing:

```
$ time python3 -c 'n = sum(x for x in range(1000000000) if x == 1 or x == 3); print(f"n={n}")'
n=4

real    0m38.234s
$ time python3 -c 'n = sum(x for x in range(1000000000) if x in (1,3)); print(f"n={n}")'
n=4

real    0m34.211s
```

The difference is not large, but it's extremely consistent. The tuple version
is approximately 10% faster than the two `or`'ed comparisons... but how does this scale?
Shockingly! When I changed the above code to include `... or x == 7`, the tuple version
became 20% faster than the `or`'ed version! There's clearly something about
chained comparisons that's not nearly as efficient as it should be!

But some good news for expected results: `x == 1` is faster than `x in (1,)` by
a very small amount... so there's that.
