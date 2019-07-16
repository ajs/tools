---
layout: single
title:  "Ackermann Challenge"
published: true
---

This week's Perl Weekly Challenge is to produce reductions of Ackermann
functions. If you've never run into the Ackermann function, it's a
mathematical construct (actually a family of them, but we'll focus on the
one in the challenge) that is described as a function that takes two
integers. Its result is either an integer or some combinations of
Ackermann functions. Here is the statement of the puzzle that explains a
bit:

> Create a script to demonstrate Ackermann function. The Ackermann function is defined as below, m and n are positive number:

```
  A(m, n) = n + 1                  if m = 0
  A(m, n) = A(m - 1, 1)            if m > 0 and n = 0
  A(m, n) = A(m - 1, A(m, n - 1))  if m > 0 and n > 0
```

> Example expansions as shown in wiki page.

```
 A(1, 2) = A(0, A(1, 1))
         = A(0, A(0, A(1, 0)))
         = A(0, A(0, A(0, 1)))
         = A(0, A(0, 2))
         = A(0, 3)
         = 4
```

Okay, so our goal is to take in something that looks like `A(m, n)` and step
through the reduction rules until we reach an integer result. My first
thought, here, was that this sounds like a parsing problem, and indeed,
there's quite a lot of meat on the bones of that approach. It allows us to
dig into Perl's parsing tools a bit, too.

So, let's start with a grammar that matches the Ackermann function:

```
grammar Ackermann {
	rule TOP {^ <ackermann> $}
	rule ackermann { <number> | <function> }
	token number { "-"? \d+ }
	rule function {
		'A' '(' $<m> = <ackermann> ',' $<n> = <ackermann> ')'
	}
}
```

This can be used directly to match any valid Ackermann funcion:

```
if Ackermann.parse("A(1, A(2, 3))") {
	say "We have Ackermann!"
}
```

But that is just the first step. To reduce an Ackermann function, we need
to know what parts of it are currently reducible. So we can add a rule to the grammar that
matches when a function just has two integer parameters:


```
	rule resolvable {
		'A' '(' $<m> = <number> ',' $<n> = <number> ')'
	}
```

Notice the extra variables, there? Those are storeing the numbers for easy
access.

Now, all we need to do is write the function that executes the match and
does the reduction:

```
sub regexA(UInt $m, UInt $n, :$verbose=False --> UInt) {
	my $ack = "A($m, $n)";
	say $ack if $verbose;
	while $ack !~~ /^ <Ackermann::number> $/ {
		$ack .= subst(
			/$<A> = <Ackermann::resolvable>/, 
			-> $/ {
				when $<A><m> eq "0" { $<A><n> + 1 }
				when $<A><n> eq "0" { "A({$<A><m> - 1}, 1)" }
				default { "A({$<A><m> - 1}, A($<A><m>, {$<A><n> - 1}))" }
			},
			:global);
		say "\t = $ack" if $verbose;
	}
	+$ack;
}
```

A few points here are worth analyzing:

When our replacement block (the second parameter to `.subst`) is called,
we get the special variable ($/) populated for us. I'm taking it as a
parameter, here, explicitly, just to make it clear that that's what's
going on, but this code works equally well if we take out the `-> $/`.

This special variable can be indexed normally as `$/<name>` to get the
named match within the angel-brackets, but there's a special case for `$/`
that lets us just refer to `$<name>`. Here, I use this to access
`$<A><m>` and `$<A><n>`, which is to say, what `Ackermann::resolvable`
matched (stored into `$<A>`, explicitly) and within that match, what
the first and second `<number>` matched (stored, respectively into
`$<m>` and `$<n>`).

Next up, notice that our strings contain code. Any string or regex in Perl 6
can contain a block of code, deliniated by `{...}` and it will cause
the block of code to be executed and its value interpolated (in a string) or
ignored (in a regex, in which it's used solely for side effects like failing
the match). So, all we have to do to format an Ackermann function is to put
it in a string:

```
"A({$m - 1}, 1)"
```

That's it. Our `$m` gets decremented and the stringification of that number
is interpolated into the resuling string, giving something like
`"A(0, 1)"`.

Finally, note that when `$verbose` is set, this function will print its
progress, per the rules of the challenge, like so:

```
$ ackermann.p6 --regex --verbose 2 1
A(2, 1)
	 = A(1, A(2, 0))
	 = A(1, A(1, 1))
	 = A(1, A(0, A(1, 0)))
	 = A(1, A(0, A(0, 1)))
	 = A(1, A(0, 2))
	 = A(1, 3)
	 = A(0, A(1, 2))
	 = A(0, A(0, A(1, 1)))
	 = A(0, A(0, A(0, A(1, 0))))
	 = A(0, A(0, A(0, A(0, 1))))
	 = A(0, A(0, A(0, 2)))
	 = A(0, A(0, 3))
	 = A(0, 4)
	 = 5
5
```

The full version of my solution, which includes five separate solutions,
each invoked via a different command-line option, can be found
here:

> [ackerman.p6](https://github.com/ajs/tools/blob/master/puzzles/perlweeklychallenge/ackermann.p6)

Here is a quick timing comparison of the various methods:

```
$ for mode in given multi iterative regex array ; do \
   echo "Mode: $mode"; \
   time ackermann.p6 --count=50 --$mode 3 1 >/dev/null \
     || break; \
  done

Mode: given

real	0m0.468s
user	0m0.707s
sys	0m0.036s

Mode: multi

real	0m0.612s
user	0m0.865s
sys	0m0.029s

Mode: iterative

real	0m0.559s
user	0m0.886s
sys	0m0.057s

Mode: regex

real	0m1.969s
user	0m2.313s
sys	0m0.032s

Mode: array

real	0m0.529s
user	0m0.889s
sys	0m0.024s
```
