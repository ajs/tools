#!/usr/bin/env python3

import math
import random
import pytest
import argparse
import itertools


def odd_in_row(row):
    """Number of odd values in pascal's triangle at 1-indexed row 'row'."""

    return 2**(format(row-1, 'b').count("1"))

def main():
    """Pascal's triangle odd numbers"""

    parser = argparse.ArgumentParser("Odd numbers in pascal's traiangle")

    parser.add_argument(
        "target", nargs="?", default=128, type=int,
        help="Total number of odd numbers in pascal's triangle less than this")

    options = parser.parse_args()

    all_count = sum(range(options.target+1))
    odd_count = sum(odd_in_row(n) for n in range(1,options.target+1))

    print(f"all={all_count}, odd={odd_count} percent={float(odd_count)/all_count*100:f}%")


if __name__ == '__main__':
    main()
