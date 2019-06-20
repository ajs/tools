#!/usr/bin/env perl6

# A Perl 6 code golf challenge on /r/perl6

sub context-pad(+@nums) {
	@nums.map: {.fmt: "\%0{state $m = @nums.map({.chars}).max}d"}
}
sub lunar_add(+@nums) is export(:support) {
	+ [~] [Zmax] context-pad(@nums).map: {.comb }
}
sub lunar_mul($a, $b) is export(:support) {
    my @diga = $a.flip.comb;
    my @rows = gather for $b.flip.comb.kv -> $i, $d {
        take flip [~] gather do {
            take 0 for ^$i;
            for @diga -> $dd {
                take min($d, $dd);
            }
        }
    }
    lunar_add @rows;
}
use Test;
is lunar_add(234, 321), 334, "lunar_add two three-digit numbers";
is lunar_add(1,2,3,4), 4, "lunar_add four digits";
is lunar_mul(4,5), 4, "lunar_mul two digits";
is lunar_mul(234, 321), 23321, "lunar_mul two three-digit numbers";
is lunar_add(23, 321), 323, "lunar add shorter left";
is lunar_add(234, 32), 234, "lunar add shorter right";
