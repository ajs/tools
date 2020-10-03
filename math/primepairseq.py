#!/usr/bin/env python3

import argparse
import itertools
import random


LOW_PRIMES = (
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59,
    61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127,
)


def milrab(p):
    """Miller-Rabin statistical prime check algorithm"""

    if p == 1: return False
    if p == 2: return True
    if p % 2 == 0: return False
    m, k = p-1, 0
    while m % 2 == 0:
        m, k = m // 2, k+1
    a = random.randint(2, p-1)
    x = pow(a, m, p)
    if x == 1 or x == p-1: return True
    while k > 1:
        x = pow(x, 2, p)
        if x == 1: return False
        if x == p-1: return True
        k = k-1
    return False


def is_prime(p, r=20):
    """Is p prime (r defaults to 20 iterations of the Miller-Rabin check"""

    # High level quick check:
    if p < 2 or p != int(p):
        return False
    for n in LOW_PRIMES:
        if p == n:
            return True
        if p % n == 0:
            return False
    # Statistical check:
    for i in range(r):
        if not milrab(p):
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


def solve(nseq, seq_len):
    """Check for solutions in the given sequence"""

    for nseq_check in itertools.permutations(nseq, seq_len):
        if is_solved(nseq_check):
            print(f"Length {seq_len} sequence: {nseq_check!r}")
            yield nseq_check


def speculative_solution(solution, next_value):
    """Try to find the next solution by appending or pre-pending next_value"""

    for prev_seq in solution:
        for spec_seq in (list(prev_seq)+[next_value], [next_value]+list(prev_seq)):
            if is_solved(spec_seq):
                print(f"Length {len(spec_seq)+1} sequence: {spec_seq!r}")
                yield spec_seq


def main():
    """Prime sequence pairs puzzle"""

    parser = argparse.ArgumentParser("Prime sequence pairs puzzle")

    parser.add_argument("-F", "--until-fail", action="store_true", help="Keep trying until we fail")
    parser.add_argument("-s", "--start", action="store", type=int, default=1, help="Starting point")
    parser.add_argument("--speculate", action="store_true", help="Try some speculative concatenation on previous results")
    parser.add_argument("length", nargs="?", default=9, type=int, help="Length of sequence")

    options = parser.parse_args()

    if options.until_fail:
        print("Going until failure")

    prev_solutions = None
    for seq_len in seq_lens(options.length, options.until_fail):
        nseq = range(options.start, seq_len + options.start)
        solution = solve(nseq, seq_len)
        first = solution.__next__()
        if not options.until_fail or not first:
            if options.until_fail:
                print(f"Stopping at {seq_len}, no results.")
            break
        if first and options.speculate:
            for seq_len in seq_lens(seq_len+1, options.until_fail):
                solution = itertools.chain([first], solution)
                solution = speculative_solution(solution, seq_len+options.start)
                try:
                    first = solution.__next__()
                except StopIteration:
                    pass
            break


if __name__ == '__main__':
    main()
