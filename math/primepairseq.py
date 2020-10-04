#!/usr/bin/env python3

import math
import random
import pytest
import argparse
import itertools


LOW_PRIMES = (
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59,
    61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127,
)


def miller_rabin(p):
    """
    Miller-Rabin statistical prime check algorithm.

    Note that this implementation assumes the input is an
    odd integer > 2.
    """

    m = p - 1
    k = 0
    while m % 2 == 0:
        m //= 2
        k += 1
    a = random.randint(2, p-1)
    x = pow(a, m, p)
    if x == 1 or x == p-1:
        return True
    while k > 1:
        x = pow(x, 2, p)
        if x == 1:
            return False
        if x == p-1:
            return True
        k -= 1
    return False


def is_prime(p, repeat=20):
    """
    Is p a prime integer?

    This is a combination of a fast check followed by a slower,
    statistical check. The fast check will only return True or False
    if the primality of the value can be determined with certainty.
    Otherwise, it will defer to the statistical check.

    Repeat defaults to 20, denoting iterations of the Miller-Rabin check,
    which is extreme overkill for anything we'll need.

    All finite, real numeric inputs are handled.
    """

    # High level quick check:
    if p < 2 or p != int(p):
        return False
    for n in LOW_PRIMES:
        if p == n:
            return True
        if p % n == 0:
            return False
    # Statistical check:
    for i in range(repeat):
        if not miller_rabin(p):
            return False
    return True


def seq_lens(start_len, until_fail=False):
    """Return the sequence lengths to try"""

    while True:
        yield start_len
        if not until_fail:
            break
        start_len += 1


def is_solved(potential):
    """Is this a valid solution?"""

    prev = None
    for n in potential:
        if prev is not None:
            if not is_prime(prev+n):
                return False
        prev = n
    return True


def asymetric_permutations(input_seq):
    input_seq = list(input_seq)
    input_len = len(input_seq)
    first = [input_seq.pop(0)]
    center = input_len/2.0
    for pos in range(math.ceil(center)):
        if pos <= center-1:
            rest_perm = itertools.permutations(input_seq)
        else:
            # For the case where first becomes the center-pivot
            rest_perm = asymetric_permutations(input_seq)
        for rest in rest_perm:
            rest = list(rest)
            yield rest[0:pos] + first + rest[pos:]


def solve(nseq, seq_len=None, remove_symetry=False):
    """Check for solutions in the given sequence"""

    if seq_len is None:
        seq_len = len(nseq)
    if remove_symetry:
        perms = asymetric_permutations(nseq)
    else:
        perms = itertools.permutations(nseq, seq_len)
        
    for nseq_check in perms:
        if is_solved(nseq_check):
            record_solution(nseq_check)
            yield nseq_check


def speculative_solution(solution, next_value):
    """Try to find the next solution by appending or pre-pending next_value"""

    for prev_seq in solution:
        prev_seq = list(prev_seq)
        for spec_seq in (prev_seq+[next_value], [next_value]+prev_seq):
            if is_solved(spec_seq):
                record_solution(spec_seq, "concatenated")
                yield spec_seq


SOLUTION_LEN = 0
ALL_SOLUTIONS = False


def record_solution(solution, mode=None):
    """Report a result"""

    global SOLUTION_LEN
    global ALL_SOLUTIONS

    solution = list(solution)
    if ALL_SOLUTIONS or len(solution) > SOLUTION_LEN:
        if mode:
            print(f"Solution ({mode}) length {len(solution)}: {solution!r}")
        else:
            print(f"Solution length {len(solution)}: {solution!r}")
        SOLUTION_LEN = len(solution)


def main():
    """Prime sequence pairs puzzle"""

    parser = argparse.ArgumentParser("Prime sequence pairs puzzle")

    parser.add_argument("-F", "--until-fail", action="store_true", help="Keep trying until we fail")
    parser.add_argument("-s", "--start", action="store", type=int, default=1, help="Starting point")
    parser.add_argument("--speculate", action="store_true", help="Try some speculative concatenation on previous results")
    parser.add_argument("-r", "--remove-symetry", action="store_true", help="Remove results that are mirror images of previous results")
    parser.add_argument("-a", "--all", action="store_true", help="Show all results for each length, not just the first")
    parser.add_argument("length", nargs="?", default=9, type=int, help="Length of sequence")

    options = parser.parse_args()

    if options.all:
        ALL_SOLUTIONS = True

    if options.until_fail:
        print("Going until failure")

    prev_solutions = None
    did_len = set()
    for seq_len in seq_lens(options.length, options.until_fail):
        if seq_len in did_len:
            continue
        else:
            did_len.add(seq_len)
        nseq = range(options.start, seq_len + options.start)
        solution = solve(nseq, seq_len, options.remove_symetry)
        first = solution.__next__()
        if options.all:
            for s in solution:
                pass
        if first and options.speculate:
            for seq_len in seq_lens(seq_len+1, options.until_fail):
                if first is not None:
                    solution = itertools.chain([first], solution)
                solution = speculative_solution(solution, seq_len+options.start-1)
                try:
                    first = solution.__next__()
                    if first is not None:
                        did_len.add(seq_len)
                except StopIteration:
                    break
        if not options.until_fail or not first:
            if options.until_fail:
                print(f"Stopping at {seq_len}, no results.")
            break


@pytest.mark.parametrize('n, prime', [
    # Some specific values to check, plus a few values from
    # http://oeis.org/A000668, https://oeis.org/A014233 and
    # https://oeis.org/A090659
    (-2, False),
    (0, False),
    (1, False),
    (2, True),
    (2.5, False),
    (5, True),
    (10, False),
    (25, False),
    (2047, False),
    (10007, True),
    (35461, True),
    (769231, True),
    (1373653, False),
    (9080191, False),
    (25326001, False),
    (2147483647, True),
    (3215031751, False),
    (27277700491, False),
    (1125897758834689, False),
    (2305843009213693951, True),
])
def test_is_prime(n, prime):
    """Test our is_prime test for primality"""

    assert is_prime(n) is prime, f"Expect is_prime({n}) -> {prime!r}"


@pytest.mark.parametrize('inseq, outseq', [
    ([1,2,3], ([1, 2, 3], [1, 3, 2], [2, 1, 3])),
    ([1,2], ([1,2],)),
])
def test_asymetric_permutations(inseq, outseq):
    """Test creation of asymertric permutations over single-digit values"""

    outseq_set = set("".join(str(e) for e in elems) for elems in outseq)
    for result in asymetric_permutations(inseq):
        result_str = "".join(str(e) for e in result)
        assert result_str in outseq_set, f"{result!r} returned, should be expected"
        outseq_set.remove(result_str)
    assert not outseq_set, f"Remaning values {outseq_set!r} should be empty"


if __name__ == '__main__':
    main()
