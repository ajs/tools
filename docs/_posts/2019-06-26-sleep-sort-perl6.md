---
layout: single
title:  "Sleep Sort in Perl6"
published: true
---

I've been following the series of sort articles by Andrew Shitov on
Perl 6 sorting, with the most recent being [Stooge Sort in Perl 6](https://perl6.online/2019/06/26/104-stooge-sort-in-perl-6/).

I thought I'd take this opportunity to talk about my favorite sort:
sleep sort. Here's the classic form of the sort in Unix Shell syntax:

    function sleep_and_echo {
      sleep "$1"
      echo "$1"
    }
     
    for val in "$@"; do
      sleep_and_echo "$val" &
    done

As you can see, the core "algorithm" is just a matter of sleeping
(Unix lingo for pausing the program for a number of seconds)
before outputting the value. But when given a sequence of integers,
this function sorts them!

The key insight is that it's parallel: each process sleeps n seconds
before printing that value and so the values come out in order.

## Complexity

The classic question to newbie programmers is: what is the run-time
complexity of this algorithm. The naive answer is `O(n)`, that is,
its runtime is the number of elements times some constant factor
(1 second). Thus, it is magically the most efficient sorting
algorithm of all time.

But this is false. Its actual run-time complexity is
`O(n log(n))` or thereabouts, depending on the system in question,
but figuring that out requires that you know what is actually
happening. In classic Unix-like systems (which, thanks to the
POSIX standard includes most everything these days) this code
results in _n_ insertions into the scheduler's datastructure that
tracks upcoming events like the need to wake a process up that is
currently sleeping. That insertion is a `log(n)` operation
(on average, assuming a binary tree) and
it must be performed _n_ times, thus the complexity is that
_n_ operations times the `log(n)` complexity of each operation.

But because the shell hides all of this from you, it seems
magically faster!

## Perl6

In Perl6 we have some powerful tools for parallelization,
including the "promises" functionality that has a very
convinient interface: `start`

    await gather for @*ARGS -> $n {
        take start {
            sleep $n;
            say $n;
        }
    }

This is the equivalent of the shell code, previous.

Though if you prefer terser code, this can be
_golfed_ down to:

    await @*ARGS.map(-> $n { start { sleep $n; say $n } })

To break down the code, let's walk from the inside out:

`sleep` and `say` are just the sleeping and printing
functions in Perl6. We wrap those with `start` which
returns a "promise" that when awaited will execute its
block of code. The `take` command saves this promise
in an iterator returned by the `gather` and await takes
an iterable sequence of promises and returns when they
have all finished.

## Optimizing and lies

That's it! Simplest sort ever, but here's a quick bit
of optimization:

    await gather for @*ARGS -> $n {
        take start {
            sleep +$n / 10;
            say $n;
        }
    }

This runs _10 times faster!_

But, of course, this speed increase doesn't scale well.
Parallelization can be non-deterministic when the system
is contending for resources or if Perl's thread
handling decides to batch these requests oddly. For
example, this fails spectacularly because of batching:

    await gather for (^100).roll(100) -> $n {
        take start {
            sleep +$n / 10;
            say $n;
        }
    }

But there's a simpler problem: the initial process of kicking off your background jobs has to finish
faster than your individual unit of sleep. If not, you are still adding new sleeps after the first
one may have finished!
