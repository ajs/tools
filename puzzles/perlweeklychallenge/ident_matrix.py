#!/usr/bin/env python

# From : https://perlweeklychallenge.org/blog/perl-weekly-challenge-011/

# Challenge #2
# Write a script to create an Indentity Matrix for the given size. For
# example, if the size is 4, then create Identity Matrix 4x4. For more
# information about Indentity Matrix, please read the wiki page.

# This is a straight translation of the Perl 6 solution.


import sys
import argparse


def main():
    parser = argparse.ArgumentParser(
            description='Generate the Identity Matrix of the given size (nxn)')
    parser.add_argument('size', type=int, nargs='?', default=4)
    size = parser.parse_args().size

    for row in range(size):
        print(' '.join(str(int(col == row)) for col in range(size)))

if __name__ == '__main__':
    main()
