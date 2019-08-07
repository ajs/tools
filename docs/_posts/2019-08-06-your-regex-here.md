---
layout: single
title:  "Your Regex Here"
published: true
---

Usually, in this blog, I've been demonstrating Perl 6 programs and
techniques, but that's not what this post is about. It's also quite a
lot longer than most of my posts. It's intended as a proposal to
those who develop, extend or maintain other languages as to how they
could adapt Perl 6 Regexes (AKA Rules) to their language.

If you just want to see what this would look like, feel free to skip to
the end of this post to see a full parser for JSON as an example.

Before we go there, let's cover why that's a good idea.

I measure regular expressions in 5 epochs or generations, with a
zeroth generation for the purely mathematical idea of a regular
expression.

In the early days of Unix, there was a regular expression library.
I call this the first generation.
Not very long after that it was "standardized" by extending it and
changing/mutilating the syntax. This is the POSIX regular expression
standard.

Then we entered the boom times of regular expression development
when Perl introduced its improvements to the traditional Unix and
POSIX regular expressions. Sometime between POSIX and Perl, regular
expressions also stopped being regular in the mathematical sense
because of backtracking.

Perl, PCRE, Python and Java all had a hand in the evolution of the
basic third generation regular expression into what I'll call the
fourth generation: the regular expressions that you're probably familiar
with, today. These include features like named groups (first introduced
in Python) and some implementations have extensions for full Unicode
support.

And then along came Perl 6! Perl 6 calls its system "regexes" and
technically they're a full grammar engine, but realistically that's
not all that much of a departure from modern regular expression engines,
many of which support features such as back-referencing, look-ahead and
look-behind, and Perl 5 even supports a primitive sort of recursive
sub-rule!

What's truly interesting about these 5th-generation regular expressions
is that they're not just an extension, but a complete re-imagining
of the basic Unix regular expression syntax.

## Toward a Language-Neutral 6th Generation

The goal, here, is to come up with the core of Perl 6 regexes in order
to allow future innovators in other languages to move toward the 6th
generation just as they did when Perl enhanced regular expressions back in
the early 90s.

Nothing here is meant to be locked in to Perl-like syntax. For example,
while braces are used to enclose rules by default, there is nothing
stopping a language like Python from defining rules in terms of
indentation levels. Dollar signs are used for back-referencing, but
this can be thought of as part of the regex syntax, not a generic
variable naming convention, just as backslashed back-references were
treated in previous implementations.

Let's begin...

## Code, not strings

Many languages implement regular expressions as strings that are parsed
at run-time to produce a matching structure. Regexes aren't like that.
They are designed to be first-class code in the native language. As such
they can fail at the time the rest of the program is parsed if malformed
and they can include nested code execution.

Thinking of regexes in this way can be misleading however. There is
an ephemeral nature to this execution that is unlike most other forms of
code execution because of the inherent backtracking that occurs within a
regex, potentially undoing bindings created within match objects and
invalidating previous state.

## Keywords and Whitespace

Perl 6 is very, very free with introducing keywords. It can do this because
the namespace is pretty well guarded and user-defined values rarely
conflict with these keywords. As such, there are a profusion of ways to
introduce a regex. I'm going to use three basic keywords, here:

* `grammar` - Something like "class" in most modern OO languages, but
  the body isn't a set of properties and methods, but rather regexes.
* `rule` - Introduces a regex that uses significant whitespace by default
* `token` - Introduces a regex that does not use significant whitespace
  by default.

If your language is very restrictive with keywords, only the grammar keyword
is really necessary, as the other two are nested within grammars.

So, what is this significant whitespace thing? An example may help:

Here's a typical regex in just about any modern language:

    \d+ \d+

This is read, in most languages, as "one or more digits followed by a
literal space followed by one or more digits". But inside a rule, it is
actually shorthand for:

    \d+<.ws>\d+

We'll cover the specifics of what that means later, but for now, just
understand that it means "match whitespace smartly".

In tokens, however, literal whitespace is completely ignored unless
quote or escaped. This is the core difference between the two keywords.

Comments are also allowed. I'm not going to go into all of the funky Perl 6
style comment formats, and I will simply include:

    \d+ # Digits

A comment is simply ignored, much like whitespace in a token.

## Literals

Any "word" character which includes alphanumeric characters and underscores
(`_`) can simply be matched as-is:

    token { apple }

But anything more complex must be escaped (prefixed with `\\`) character-by
character or quoted:

    token {
        \. '.' "." # all equivalent
    }

## Simple non-literals

As with most other regular expression formats, `.` matches any
non-newline and there are the various character class escapes:

* `\s` matches whitespace
* `\w` matches word characters (alphanumeric, underscore)
* `\n` matches newlines (actually a "logical newline" which is
  platform-agnostic)
* `\t` matches a tab
* `\h` matches horizontal whitespace
* `\v` matches vertical whitespace
* `\d` matches a digit

All of the above can also be negated by using their upper-case equivalent,
e.g.:

    \w\S*

Matches a word character followed by any non-whitespace.

There are also a more verbose form of these and many other builtin,
named sub-rules:

* `<alpha>` - Alphabetic characters
* `<digit>` - Same as `\d`, a digit
* `<xdigit>` - Hexadecimal digit
* `<alnum>` - Same as `\w`, a word character
* `<punct>` - Punctuation characters
* `<graph>` - `<+<alnum>+<punct>>`
* `<space>`- Same as `\s`, a whitespace character
* `<cntrl>` - Control characters
* `<print>` - `<+<graph>+<space>-<cntrl>>`
* `<blank>` - Same as `\h`, horizontal whitespace
* `<lower>` - Lowercase
* `<upper>` - Uppercase
* `<same>` - Between two of the same character
* `<wb>` - A word boundary
* `<ws>` - Smart whitespace (match whitespace and/or a word boundary)
* `<ww>` - Match within a word

When used outside of `<+...>` character classes, these are
sub-rules (see below), and may be preceded (within the `<...>`) by `.` in order to avoid
capturing the matched value, like any other sub-rule.

Unicode properties can also be matched. For example:

    <:Script('Latin')>

Matches any character with the Unicode "Script" property, "Latin", while:

    <:Block('Basic Latin')>

Matches any character in the "Basic Latin" "Block". These are terms from
the Unicode standard, not from Perl 6.

The following properties are supported in both short and long versions
as `<:property>`:

* `Letter` or `L`
* `Cased_Letter` or `LC`
* `Uppercase_Letter` or `Lu`
* `Lowercase_Letter` or `Ll`
* `Titlecase_Letter` or `Lt`
* `Modifier_Letter` or `Lm`
* `Other_Letter` or `Lo`
* `Mark` or `M`
* `Nonspacing_Mark` or `Mn`
* `Spacing_Mark` or `Mc`
* `Enclosing_Mark` or `Me`
* `Number` or `N`
* `Decimal_Number or digit` or `Nd`
* `Letter_Number` or `Nl`
* `Other_Number` or `No`
* `Punctuation or punct` or `P`
* `Connector_Punctuation` or `Pc`
* `Dash_Punctuation` or `Pd`
* `Open_Punctuation` or `Ps`
* `Close_Punctuation` or `Pe`
* `Initial_Punctuation` or `Pi`
* `Final_Punctuation` or `Pf`
* `Other_Punctuation` or `Po`
* `Symbol` or `S`
* `Math_Symbol` or `Sm`
* `Currency_Symbol` or `Sc`
* `Modifier_Symbol` or `Sk`
* `Other_Symbol` or `So`
* `Separator` or `Z`
* `Space_Separator` or `Zs`
* `Line_Separator` or `Zl`
* `Paragraph_Separator` or `Zp`
* `Other` or `C`
* `Control or cntrl` or `Cc`
* `Format` or `Cf`
* `Surrogate` or `Cs`
* `Private_Use` or `Co`
* `Unassigned` or `Cn`

Again, these are directly from the Unicode specification.

So, you might match a title-case string as such:

    token titlestring { <:Titlecase_Letter> <:Lowercase_Letter>* }

To negate a property, simply follow the colon with a `!`.

## Character classes

So far, these have all been expressed as "sub-rules". But you can
also use them in "character class" constructions that can
only ever match a single character and can be built up in pieces.

Character classes can be explicit lists of characters:

    <[a..z]> # lower ascii alpha

Or they can be constructed from other classes:

    <+<alpha>-<:Uppercase_Letter>>

Which is to say, "the alpha class, but excluding the upper case
letters".

Unicode codepoints can also be referenced by hexadecimal number:

    \x1234 # always four digits

or:

    \x[12]

Or by name:

    \c[GREEK SMALL LETTER ALPHA]

## Quantifiers

The typical regular expression quantifiers are supported:

* `+` - Match the preceding "atom" (single matching literal, group, sub-rule
  or class) one or more times.
* `*` - Match the preceding atom zero or more times.
* `** min[..max]` - Match the preceding atom min to max (* means forever)
  times.

These constructs modify preceding quantifiers:

* `?` - Match non-greedily
* `!` - Match greedily (the default)
* `:` - Do not perform backtracking for the previous quantifier
* `%` - Match the preceding atom _with quantifier_ separated by the following
  atom (e.g. `\w+ % ','` which matches comma-separated words)
* `%%` - Same as `%`, but allows a trailing separator.

## Conjunctions

The `|` of most regular expression syntaxes is now `||`. This will match
on the first matching alternative between the left and right hand sides.

    'a' || 'aa' # will never match the right

While the `|` now matches the longest of the two, as most BNF-like
parser specifications expect, so:

    'a' | 'aa' # will only ever match the right

The `&&` conjunction requires that its left and right hand sides both
match the _same substring_. There is a `&` which is mostly identical
to `&&`. It only differs in that `&` and `|` nominally allow evaluation
of their left and right hand sides in any order (and this carries over to
chains of these operators) enhancing potential for parallelization.

## Anchors

* `^` Start of string
* `$` End of string
* `^^` Start of newline-separated line within the string
* `$$` End of newline-separated line within the string
* `<?w>` Word boundary
* `<!w>` Not a word boundary
* `<?ww>` Within a word (no boundary)
* `<!ww>` Not within a word
* `<<` Left word boundary (a non-word character or start of string on the
  left and a word character on the right.
* `>>` Right word boundary (a word character on the left and a non-word
  character or end of string on the right)

Note that all of these constructs match an anchor condition, not any of
the text. They are all zero-width.

There are other zero-width assertions that are more complex:

We've already seen some examples of look-around assertions, which are
of the form:

    <?class> # positive look-around

or

    <!class> # negated look-around

In this latter example, do not confuse a look-around, which does not
consume any characters from the input with a negative character class:

    <-class> # negative character class

which does consume the matched character. Look-around matches appear to
match non-zero-width entities, but because they do not consume them,
they are technically zero-width.

You can also turn a full regex into a zero-width assertion in two ways:

    <?before 'apple'> # match before apple, but do not eat it

and

    <?after 'apple'> # match after apple, but do not eat it

In the latter case, if the previous part of the regex had already
consumed the characters matched by the body of the `after`, then
this does not change. The `before` and `after` zero-width assertions
are just that: assertions about the text being matched without any
change in the current position of the match.

Both of these can be negated:

    <!after '.'> <!before '-'>

## Grouping and capturing

A group is specified with parentheses, just like old style regular
expressions:

    'fruit:' ('apple' || 'pear')

Which will match `"fruit:apple"` or `"fruit:pear"`.

Parentheses always capture their matches in the numbered match placeholders
`$n` where n is associated with parenthetical groups in the following way:

* Counting open-parens left-to-right
* But alternation (`|`, `||`, `&` and `&&`) reset the numbering
* If alternations have differing numbers of groups, then the longest
  "wins" in the sense that subsequent groups will be numbered from
  the highest number used thus far.

For example:

    'a' ( ('b') | ('c') ('d') ) ('e')

Would match `"abe"`, capturing `$0` and `$1` as `"b"`, leaving
`$2` undefined and capturing `$3` as "e".

These captured values can be matched later on:

    f (o+) $0

Would match an even number of "o"'s after the "f".

_Note that Perl 6 requires a code assertion between the group and
back-reference in order to cause the back-reference to be available.
This is not part of the generalized specification, and is considered
an implementation detail of Perl 6._

There is also a non-capturing group:

    a [ b || c ]

In this case, grouping is performed, but no capture is saved. This
can improve performance and simplify access to captured groups.

## Named captures

You can also save any match (whether capturing or not) to a specific
name:

    'fruit:' $<fruit> = [ 'apple' || 'pear' ]

In this case, the name, "fruit" is associated with the following
group or other atom as if it were a sub-rule (see below).

## Adverbs

Adverbs are colon-prefixed directives that change the behavior of the
regex engine itself. Their effect lasts until the end of the
inner-most group, rule or token within which they appear. These include:

* `:ignorecase` or `:i` - Match upper and lower-case interchangeably
* `:ignoremark` or `:m` - Match base Unicode characters, ignoring any combining elements (e.g. `:m u` would match "ü")
* `:ratchet` or `:r` - Do not perform _any_ backtracking
* `:sigspace` or `:s` - Treat whitespace as in rules
* `:exhaustive` or `:e` - Perform all possible backtracking, even after a successful match

Any adverb may be negated by using `:!` e.g.:

    'fruit:' [:ignorecase 'apple' | :!ignorecase 'FruitClass']

Would match "fruit:appLE", "fruit:FruitClass" but not "fruit:fruitclass".

## Sub-rules

A sub-rule is like a subroutine call. All `rule` and `token` blocks
introduce a sub-rule, which can be referenced by any other sub-rule
using angel-brackets:

    rule identifier { <word> | <number> }

    token word { \w+ }

    token number { \d+ }

sub-rules capture by default, saving the result under the name of the
sub-rule. If the sub-rule is matched more than once or has a quantifier,
then its capture will be a list of matches. For example, if the above
code also included:

    rule sequence { <identifier>+ % ',' }

Then any comma-separated list of identifiers would be matched with
the named capture under "identifier" containing a list of the
matches that occurred. These captured matches are nested. You can
think of a match as being a data structure that contains a numbered
set of indexes and a named set of indexes, independently. How this
is implemented is language-specific, but a match can contain a whole
tree of matches from sub-rules, and indeed this is how most grammars
work, turning input test into a tree of match results that can be
transformed into an AST or directly acted upon.

## Code interpolation

There are several ways to interpolate native language structures
and code into a regex:

* `{...}` - Execute the enclosed expression, but ignore its result.
* `<?{...}>` or `<!{...}>` - Execute the enclosed expression and match if it evaluates
  as true (or false if `!` is used).
* `<$variable>` - The contents of `variable` are coerced into a regex
  in a language-specific way and then interpolated into the current regex.
* `<@variable>` - The contents of `variable` are coerced into a list of
  regexes in a language-specific way and then interpolated into the current
  regex as `|` alternations.

The word "expression" is used, here, but what this means should be
re-interpreted in a language-specific way.

All `<...>` interpolations of external code will save to a numbered
group as if they were within parens, but can be named like so:
`<name=?{code}>` or `<name=$variable>`.

## Example

The following is a complete parser for the [ECMA-404 2nd Edition
/ December 2017](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf)
specification:

```
grammar JSON {
    rule TOP {^ <value> $}

    rule value {
        <object> | <array> | <number> | <string> | <name>
    }

    rule name { <true> | <false> | <null> }

    token true  { 'true'  }
    token false { 'false' }
    token null  { 'null'  }

    rule object {
        '{' ( <string> ':' <value> )* % ',' '}'
    }

    rule array {
        '[' <value>* % ',' ']'
    }

    token number {
        '-'?
        [ '0' | <[1..9]> <digit>* ]
        [ '.' <digit>+ ]?
        [:i <[e]> <[\+\-]>? <digit>+ ]?
    }

    token digit { <[0..9]> }

    token string {
        '"' ~ '"' <stringbody>*
    }

    token stringbody {
        # anything non-special:
        <-[\"\\\x[0000]\x[001f]]> |
        # or a valid escape
        '\\' <escape>
    }

    token escape {
        # An escaped special of some sort
        <[\"\\\/bfnr]> |
        # or a Unicode codepoint
        'u' [:i <+[0..9]+[a..f]>] ** 4
    }
}
```