#!/usr/bin/env python3

# Perl weekly challenge

# TASK #1: Isomorphic Strings

# You are given two strings $A and $B. Write a script to check if the
# given strings are Isomorphic. Print 1 if they are otherwise 0.

import pytest
import argparse


def numify(s):
    """
    Return an iterator with a single number for each characer in the
    input string. For each unique character in the input, the output
    will have a corresponding unique number, starting at 0.
    """

    mapping = {}
    n = 0

    for c in s:
        if c not in mapping:
            mapping[c] = n
            n += 1
        yield mapping[c]
        
@pytest.mark.parametrize("input_string, numify_output", [
    ("aaaa", [0,0,0,0]),
    ("word", [0,1,2,3]),
    ("tilt", [0,1,2,0]),
    ("", []),
])
def test_numify(input_string, numify_output):
    """Perform unit tests on numify"""

    assert list(numify(input_string)) == numify_output, f"numify({input_string!r}) expects f{numify_output!r}"


def main():
    """Compare two strings and determine isomorphism"""

    parser = argparse.ArgumentParser(description="Isomorphic string comparison")
 
    parser.add_argument("string", nargs=2, help="Strings to compare")
    parser.add_argument("--verbose", action="store_true", help="Verbose output")

    options = parser.parse_args()

    inputs = options.string
    assert len(inputs) == 2, "Expect two input strings"
    input_numify = [list(numify(s)) for s in inputs]
    if (input_numify[0] == input_numify[1]):
        print("1")
        if options.verbose:
            print(f"Strings match: isomorphic patterns: {input_numify!r}")
    else:
        print("0")
        if options.verbose:
            print(f"Strings do not match: isomorphic patterns: {input_numify!r}")


if __name__ == '__main__':
    main()
