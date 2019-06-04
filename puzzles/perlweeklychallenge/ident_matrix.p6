#!/usr/bin/env perl6

use v6.d;

# From : https://perlweeklychallenge.org/blog/perl-weekly-challenge-011/

# Challenge #2
# Write a script to create an Indentity Matrix for the given size. For
# example, if the size is 4, then create Identity Matrix 4x4. For more
# information about Indentity Matrix, please read the wiki page.

#= Generate the Identity Matrix of the given size (nxn)
sub MAIN(Int $size=4) {
	for ^$size -> $row {
		put (^$size).map: {Int($^col == $row)};
	}
}