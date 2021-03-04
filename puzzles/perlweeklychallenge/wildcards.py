#!/usr/bin/env python3

import re
import pytest
import argparse

def wildcard(s, star_min=1):
    """
    Transform s such that it is a valid regex which
    matches the string in s, but allowing for:
     ? - Match any single character.
     * - Match any sequence of characters.
    The minimum number of characters matched by "*"
    is 1 by default, but can be changed with the
    parameter, star_min.
    """

    def _feed_parts(input_parts):
        for part in input_parts:
            if part == "*":
                if star_min == 0:
                    yield ".*"
                elif star_min == 1:
                    yield ".+"
                else:
                    yield f".{{{star_min},}}"
            elif part == "?":
                yield "."
            else:
                yield re.escape(part)

    return "".join(_feed_parts(re.split(r'([\?\*])', s)))

@pytest.mark.parametrize(
    'pattern, result', (
        ('abc', 'abc'),
        ('a*c', 'a.+c'),
        ('.bc', r'\.bc'),
        ('.*c', r'\..+c'),
        ('a?c', 'a.c'),
        ('', ''),
        ('*', '.+'),
        ('?', '.'),
    )
)
def test_wildcard(pattern, result):
    assert wildcard(pattern) == result, f"Check wildcard({pattern!r}) == {result!r}"

@pytest.mark.parametrize(
    'star_min, result', (
        (0, "a.*c"),
        (1, "a.+c"),
        (2, "a.{2,}c"),
    )
)
def test_wildcard_star_min(star_min, result):
    matcher = wildcard('a*c', star_min=star_min)
    assert matcher == result, f"Expect wildcard('a*c', star_min={star_min}) == {result!r}"
    assert re.match(matcher, "a" + ("b" * star_min) + "c"), f"Match with {star_min} chars"
    if star_min > 0:
        assert not re.match(matcher, "a" + ("b" * (star_min-1)) + "c"), f"Should not match with {star_min}-1 chars"

def match_wildcard(pattern, target, star_min):
    return re.match(wildcard(pattern, star_min=star_min) + '$', target)

def message(status, msg, quiet=False):
    if quiet:
        return "1" if status else "0"
    return msg

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-q', '--quiet', help="Quiet mode, just outputs 0 (no match) or 1 (match)")
    parser.add_argument('-s', '--star-min', type=int, default=1, help="Minimum characters matched by *")
    parser.add_argument('pattern', help="Pattern to look for with * and ? wildcards")
    parser.add_argument('target', help="Target string to compare against")
    options = parser.parse_args()

    if match_wildcard(options.pattern, options.target, star_min=options.star_min):
        print(message(True, "Match found", quiet=options.quiet))
    else:
        print(message(False, "No match", quiet=options.quiet))


if __name__ == '__main__':
    main()
