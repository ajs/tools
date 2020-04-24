#!/usr/bin/env perl6

#Task #2

# Write a script to validate a given bitcoin address.
# Most Bitcoin addresses are 34 characters. They consist
# of random digits and uppercase and lowercase letters,
# with the exception that the uppercase letter “O”,
# uppercase letter “I”, lowercase letter “l”, and the
# number “0” are never used to prevent visual ambiguity.
# A bitcoin address encodes 25 bytes. The last four bytes
# are a checksum check. They are the first four bytes of
# a double SHA-256 digest of the previous 21 bytes. For
# more information, please refer wiki page. Here are some
# valid bitcoin addresses:

use v6;

use Digest::SHA256::Native;

grammar BitcoinAddress {
	rule TOP {^ <bitcoin-address> $}
	token bitcoin-address {
		<bitchar>**34
	}
	token bitchar { <+alnum-[IlO0_]> }
}

subset CoolInt of Int where {$^x.Num.narrow ~~ Int}
subset CoolUInt of CoolInt where * >= 0;

sub infix:<divmod>(CoolInt $a , CoolInt $b) is equiv(&infix:<div>) {
	$a div $b, $a mod $b;
}

our %to-base58-lut = (^128).map({.chr}).grep({/<BitcoinAddress::bitchar>/}).pairs;
our %from-base58-lut = %to-base58-lut.kv.map(-> $k, $v {$v => $k});
sub to-base58(CoolUInt $n is copy) {
	[~] reverse gather loop {
		($n, my $remain) = $n divmod 58;
		take %to-base58-lut{$remain};
		last if $n == 0;
	}
}
sub from-base58(Str $base58) {
	[+] gather for $base58.flip.comb -> $c {
		state $radix = 1;
		take %from-base58-lut{$c} * $radix;
		$radix *= 58;
	}
}

say %from-base58-lut.perl;
say (100 divmod 58).perl;
say to-base58(100);
say from-base58(to-base58(100));

# From https://en.bitcoin.it/wiki/Base58Check_encoding

#Base58Check has the following features:

# * An arbitrarily sized payload.
# * A set of 58 alphanumeric symbols consisting of easily distinguished
#   uppercase and lowercase letters (0OIl are not used)
# * One byte of version/application information. Bitcoin addresses use
#   0x00 for this byte (future ones may use 0x05).
# * Four bytes (32 bits) of SHA256-based error checking code. This code
#   can be used to automatically detect and possibly correct
#   typographical errors.
# * An extra step for preservation of leading zeroes in the data.

