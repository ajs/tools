#!/usr/bin/env python3

# https://perlweeklychallenge.org/blog/perl-weekly-challenge-102/

import argparse
import itertools
import math
import pytest
import re
import sys


# https://oeis.org/A035519
KNOWN_RARE = (
    65, 621770, 281089082, 2022652202, 2042832002, 868591084757,
    872546974178, 872568754178, 6979302951885, 20313693904202,
    20313839704202, 20331657922202, 20331875722202, 20333875702202,
    40313893704200)


def rare_last_digit(first):
    """Given a leading digit, first, return all possible last digits of a rare number"""

    if first == 2:
        return (2,)
    elif first == 4:
        return (0,)
    elif first == 6:
        return (0,5)
    elif first == 8:
        return (2,3,7,8)
    else:
        raise ValueError(f"Invalid first digit of rare number: {first}")


def py37_isqrt(n):
    """Return largest integer r such that r^2 <= n"""

    if n < 10000000000000000000000: # trial and error
        return math.floor(math.sqrt(n))
    else:
        # https://stackoverflow.com/a/53983683
        if n > 0:
            x = 1 << (n.bit_length() + 1 >> 1)
            while True:
                y = (x + n // x) >> 1
                if y >= x:
                    return x
                x = y
        elif n == 0:
            return 0
        else:
            raise ValueError("square root not defined for negative numbers")


@pytest.mark.parametrize(
    'n, result', (
        (1, 1),
        (10, 3),
        (16, 4),
        (99999980000001, 9999999),
        (152415787532388367501905199875019052100, 12345678901234567890),
        (152415787532388367501905199875019052101, 12345678901234567890),
        (152415787532388367526596557677488187880, 12345678901234567890),
        (152415787532388367526596557677488187881, 12345678901234567891),
    )
)
def test_isqrt(n, result):
    assert py37_isqrt(n) == result, f"Expect isqrt({n}) == {result}"


if sys.version_info.major == 3 and sys.version_info.minor >= 8:
    isqrt = math.isqrt
else:
    isqrt = py37_isqrt


def is_perfect_square(n):
    """Return True if n is a Perfect Square"""

    # These shortcuts actually take longer than just checking with isqrt
    #if n % 10 in (2, 3, 7, 8):
    #    return False
    #if digital_root(n) not in (1, 4, 7, 9):
    #    return False
    sqt = isqrt(n)
    return sqt * sqt == n


@pytest.mark.parametrize(
    'n, result', (
        (1, True),
        (2, False),
        (4, True),
        (1002001, True),
        (1002002, False),
        (152415787532388367526596557677488187881, True),
        (152415787532388367526596557677488187882, False),
    )
)
def test_is_perfect_square(n, result):
    assert is_perfect_square(n) is result, f"Expect is_perfect_square({n}) is {result!r}"


def digital_root(n):
    """Return the digital root of n by summing digits recursively"""

    root = n
    while len(str(root)) > 1:
        root = sum(int(d) for d in str(root))
    return root


@pytest.mark.parametrize(
    'n, result', (
        (1, 1),
        (10, 1),
        (19, 1),
        (38, 2),
        (12345678901234567890, 9),
    )
)
def test_digital_root(n, result):
    assert digital_root(n) == result, f"Expect digital_root({n}) == {result}"


def is_rare(n, rev=None):
    """Return True if n is a Rare Number"""

    # This is a good high-pass filter, but slow
    #if digital_root(n) not in (2, 5, 8, 9):
    #    return False
    if rev is None:
        rev = int(str(n)[::-1])
        # Assume if rev is passed in, this check was done
        if rev >= n:
            return False
    return is_perfect_square(n + rev) and is_perfect_square(n - rev)


@pytest.mark.parametrize(
    'n, result', (
        (1, False),
        (65, True),
        (66, False),
        (67, False),
        (621770, True),
        (22134434735752443122, True),
        (22134434535752443122, False),
        (61999171315484316965, True),
        (61999171315484316960, False),
        (65459144877856561700, True),
        (65459144877856561705, False),
    )
)
def test_is_rare(n, result):
    assert is_rare(n) is result, f"Expect is_rare({n}) is {result!r}"


def rare_second_digits(first, last):
    """
    Given the first and last digits, return tuples of all possible
    second, second-from-last digits in a rare number
    """

    if first == 2 or (first == 8 and last == 8):
        for n in range(10):
            yield (n, n)
    elif first == 4:
        for a in range(0, 10):
            for b in range((0 if a % 2 == 0 else 1), 10, 2):
                yield (a, b)
    elif first == 6:
        for a in range(0, 10):
            for b in range((1 if a % 2 == 0 else 0), 10, 2):
                yield (a, b)
    elif first == 8:
        if last == 2 or last == 8:
            for a in range(0, 10):
                yield (a, 9-a)
        elif last == 3:
            for a in range (0, 10):
                if a > 6:
                    yield (a, a-7)
                else:
                    yield (a, a+3)
        elif last == 7:
            for a in range(0, 10):
                if a > 1:
                    yield (a, 11-a)
                else:
                    yield (a, 1-a)


def _digit_pairs(filter_func):
    """Generate pairs of digits that meet filter_func's metric"""

    for a, b in itertools.product(range(10), repeat=2):
        if filter_func(a, b):
            yield (a, b)


@pytest.mark.parametrize(
    'first, last, expect, desc', (
        (2, 2, [(n,n) for n in range(10)], "B = P"),
        (4, 0, _digit_pairs(lambda a, b: (a - b) % 2 == 0), "|B - P| = zero or Even"),
        (6, 0, _digit_pairs(lambda a, b: (a - b) % 2 == 1), "|B - P| = Odd"),
        (8, 2, _digit_pairs(lambda a, b: a + b == 9), "B + P = 9"),
        (8, 3, _digit_pairs(lambda a, b: (a - b == 7 or b - a == 3)), "B - P=7 or P - B = 3"),
        (8, 7, _digit_pairs(lambda a, b: (a + b == 11 or a + b == 1)), "B + P = 11 or B + P = 1"),
        (8, 8, [(n,n) for n in range(10)], "B = P"),
    )
)
def test_rare_second_digits(first, last, expect, desc):
    msg = f"{first}, {last}: {desc}"
    result = set(rare_second_digits(first, last))
    expect = set(expect)
    assert result == expect, msg


def rare_numbers(digits):
    """Return all rare numbers of length `digits`"""

    if digits > 1:
        for lead_d in (2,4,6,8):
            for last_d in rare_last_digit(first=lead_d):
                if digits < 4:
                    for mid in ([""] if digits == 2 else "0123456789"):
                        n = int(str(lead_d) + mid + str(last_d))
                        if is_rare(n):
                            yield n
                else:
                    # Further constraints on second and second to
                    # last digits based on first and last.
                    # see http://www.shyamsundergupta.com/rare.htm
                    for mid_lead_d, mid_last_d in rare_second_digits(lead_d, last_d):
                        start = str(lead_d) + str(mid_lead_d)
                        end = str(mid_last_d) + str(last_d)
                        if digits == 4:
                            n = int(start + end)
                            rev = int(str(n)[::-1])
                            if n > rev and is_rare(n, rev=rev):
                                yield n
                        else:
                            # 1 followed by digits in middle piece
                            mid_range = 10 ** (digits - 4)
                            for mid in range(mid_range, 2 * mid_range):
                                # Drop the leading "1" for fast 0-padding
                                n = int(start + str(mid)[1:] + end)
                                # Perform a quich check and if it passes, call is_rare
                                # for the full check
                                rev = int(str(n)[::-1])
                                # All valid results will show check % 11 == 0,
                                # but that test is slower than is_rare
                                #check = n + rev if digits % 2 == 0 else n - rev
                                if n > rev and is_rare(n, rev=rev):
                                    yield n


def test_rare_numbers():
    """Check a simple range, others take too long..."""

    numbers = list(rare_numbers(2))
    assert len(numbers) == 1, "Expect one result for rare_numbers(2)"
    assert numbers[0] == 65, "Expect first rare number is 65"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('digits', metavar="N", type=int, help="Number of digits in result(s)")
    options = parser.parse_args()

    N = options.digits
    if N < 1:
        raise ValueError(f"Number of digits must be >= 1, not {N!r}")

    for rare in rare_numbers(digits=N):
        print(rare)

if __name__ == '__main__':
    main()
