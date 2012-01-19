#!/usr/bin/python
#
# A quick-and-dirty example of how to generate primes.
#
# Written in 2001 (c) by Aaron Sherman. 
# This code was based on algorithms from Applied Cryptography
# Thank you, uncle Bruce!
# Re-written in Python in 2009 by Aaron Sherman
# You can distribut this program under the terms of the GNU General
# Public License.
#

import os
import sys
import re
from math import log
from optparse import OptionParser

global verbose, options, tab

verbose = 0             # How much tracing info
tab = ''                # Indentation for $verbose mode
previous = None         # Previous value

# Static primes.
# In the perl version, these were tucked away at the end of the file after
# the documentation. In python we have to define this before using it.
static_primes = (
            2, 3, 5, 7, 9, 11, 13, 15, 17, 19, 23, 25, 29, 31, 35, 37,
            41, 43, 47, 49, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101,
            103, 107, 109, 113, 121, 127, 131, 137, 139, 143, 149, 151,
            157, 163, 167, 169, 173, 179, 181, 191, 193, 197, 199, 211,
            223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277,
            281, 283, 289, 293, 307, 311, 313, 317, 323, 331, 337, 347,
            349, 353, 359, 361, 367, 373, 379, 383, 389, 397, 401, 409,
            419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479,
            487, 491, 499, 503, 509, 521, 523, 541, 547, 557, 563, 569,
            571, 577, 587, 593, 599, 601, 607, 613, 617, 619, 631, 641,
            643, 647, 653, 659, 661, 673, 677, 683, 691, 701, 709, 719,
            727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809,
            811, 821, 823, 827, 829, 839, 853, 857, 859, 863, 877, 881,
            883, 887, 907, 911, 919, 929, 937, 941, 947, 953, 967, 971,
            977, 983, 991, 997, 1009, 1013, 1019, 1021, 1031, 1033, 1039,
            1049, 1051, 1061, 1063, 1069, 1087, 1091, 1093, 1097, 1103,
            1109, 1117, 1123, 1129, 1151, 1153, 1163, 1171, 1181, 1187,
            1193, 1201, 1213, 1217, 1223, 1229, 1231, 1237, 1249, 1259,
            1277, 1279, 1283, 1289, 1291, 1297, 1301, 1303, 1307, 1319,
            1321, 1327, 1361, 1367, 1373, 1381, 1399, 1409, 1423, 1427,
            1429, 1433, 1439, 1447, 1451, 1453, 1459, 1471, 1481, 1483,
            1487, 1489, 1493, 1499, 1511, 1523, 1531, 1543, 1549, 1553,
            1559, 1567, 1571, 1579, 1583, 1597, 1601, 1607, 1609, 1613,
            1619, 1621, 1627, 1637, 1657, 1663, 1667, 1669, 1693, 1697,
            1699, 1709,
    )
last_static = static_primes[-1]

# Returns number of bits in integer parameter
def bits_in(n):
    # In some cases, python's log will introduce some inacuracy.
    # thus, we round to the precision we care about:
    return int(log(n,2)+0.000001)

# Return true/false if we're sure about the primality of the number.
# Return None if we're uncertain. The return value is in the form
# of a tuple. The second value is a textual reason.
def quick_prime_test(p):
    global last_static, static_primes
    small = p < last_static
    if p == 1:
        return (False, "number is one: not prime")
    # Test for divisibility by a low prime
    for sp in static_primes:
        if small and p == sp:
            return(True, "known, small prime")
        if (p%sp) == 0:
            return(False, "divisible by small prime %d"%sp)
    if p < last_static**2:
        return (True, "small number, not prime divisible")
    return(None, "unknown")

# Given a number of bits (default = 512) generate a prime of that bit-length and
# return it.
def generate_prime(bits=None, old=None):
    if bits is None: bits = 512
    # Generate an initial random number
    initial_p = old or p_random(bits=bits)
    # Permute the number so that the high- and low-bits are set
    if initial_p%2 == 0: initial_p = initial_p + 1
    high = 2**(bits-1)
    if initial_p < high: initial_p = initial_p + high
    if verbose > 1: print "Random starting point:", initial_p
    # Now loop over p, p+2, p+4, ... testing for primality
    for p in sequence_by_2(initial_p):
        if verbose > 1:
            strp = "%d"%p
            try:
                strp = re.compile(r'^(\d{5}).*(\d{5})$').sub(r'\1[...]\2',strp)
            finally:
                pass
            print "Testing potential prime (%s)"%strp
        elif verbose:
            sys.stdout.write(".")
        if is_prime(p,bits):
            return p
    raise "Can't get here?!"

# Given a number of bits and an optional maximum value, generate a random number
# of that many bits, optionally < the maximum.
def p_random(bits=512, max=None):
    n = 0
    bitsmask = reduce(lambda x,y: x|(1<<y), range(bits), 0)
    while n==0 or (max and n > max):
        if max:
            bits = bits_in(max)
        # Read a number of bytes which will fit our required number of
        # bits.
        bytes = int(bits/8+1)
        bitstring = os.urandom(bytes)
        n = 0
        for byte in range(bytes):
            bs_byte = ord(bitstring[byte])
            n = n | (bs_byte << (byte*8))
        n = n & bitsmask
    n = int(n) # just to be sure
    return n

# A simple generator for counting by 2
def sequence_by_2(start=0):
    n = start
    while 1:
        yield n
        n = n + 2

# Test to see if p is prime. Return true/false
def is_prime(p, bits, recursive=False):
    global options, tab
    if not bits: bits = bits_in(p)
    # Our quick test returns a true/false only if it's sure,
    # otherwise we must test the long way.
    isp, why = quick_prime_test(p)
    if isp is not None:
        if verbose > 1:
            isnot = ""
            if not isp: isnot = "Not "
            print "", isnot, "prime:", why
    else:
        isp, why = rm_prime_test(p)
        if verbose > 1:
            if isp:
                print " RM: is prime:", why
            else:
                print " RM: not prime:", why
        if isp and not recursive and options.strong:
            # If we require strong primes, test (p-1)/2 for primality too
            if verbose > 1:
                tab = "\t"
                print " Testing prime for strength"
            elif verbose:
                sys.stdout.write("(")
            isp = is_prime((p-1)>>1, bits, True)
            if verbose:
                tab = tab[:-1]
                if verbose == 1:
                    if isp:
                        sys.stdout.write("~")
                    else:
                        sys.stdout.write("?")
                    sys.stdout.write(")")
    return isp

# Given a potential prime p, return True if the Rabin-Miller test says it's
# prime and False if not.
# Return value is in the form of a list. Second value of the list is the
# textual reason.
def rm_prime_test(p):
    global options, tab
    # Generate b = the number of 2s in the prime factors of p-1
    pp = p - 1
    r = pp
    b = 0
    while (r%2) == 0:
        b += 1
        r /= 2
    m = pp/(2**b)
    i = 0
    while i < options.rm_passes:
        i += 1
        if verbose>1: print tab, "Rabin-Miller iteration", i
        if verbose==1: sys.stdout.write("R")
        # Generate random integer a < p
        a = p_random(max=p)
        if verbose > 1: print tab, "a=", a
        j = 0
        # Generate z=a**m mod p
        z = mod_exp(a,m,p)
        if z == 1 or a == pp:
            if verbose==1: sys.stdout.write("*")
            continue # Passed
        #RM_ITERATION:
        while True:
            if j > 0 and z == 1:
                if verbose>1: print tab, "Not prime"
                if verbose==1: sys.stdout.write("-")
                if i > 0:
                    if verbose > 1:
                        print tab, "Rare:", i, "passes in, Rabin-Miller failed"
                    if verbose==1: sys.stdout.write("^")
                return(False, "RM failed on pass %d"%i)
            j += 1
            if j < b and z != pp:
                z = mod_exp(z, 2, p)
                if verbose > 1: print tab, "Next pass"
                if verbose == 1: sys.stdout.write("+")
                continue
            if z == pp:
                if verbose > 1: print tab, "Probably prime"
                if verbose == 1: sys.stdout.write("!")
                break
            if verbose > 1: print tab, "Not prime (dropped out)"
            if verbose == 1: sys.stdout.write("_")
            if i > 1:
                if verbose > 1:
                    print tab, "Rare: %d passes in, Rabin-Miller failed"%i
                if verbose == 1: sys.stdout.write("^")
            return(False, "RM failed on pass %d"%i)
    # p is prime
    return(True, "%d RM passes indicate primeality"%i)

# Given x, y, n return (x**y)mod n
def mod_exp(x,y,n):
    s = 1
    while y:
        if y & 1: s = (x*s) % n
        x = (x*x) % n
        y>>=1
    return s

# I just want to say that while Python is a nifty language, and I like a great
# deal of what it has to offer, its command-line processing features leave
# much to be desired to someone coming from Perl.
parser = OptionParser()
parser.add_option("-v", "--verbose", dest="verbose", default=0, action="store_const", const=1)
parser.add_option("-V", "--extra-verbose", dest="verbose", action="store_const", const=2)
parser.add_option("-b", "--bits", dest="bits", default=512, type="int")
# --help should be handled internally by OptionsParser
parser.add_option("-m", "--man", dest="man", default=False, action="store_true")
parser.add_option("-c", "--count", dest="count", default=1, type="int")
parser.add_option("-r", "--rabin-miller-iterations=", dest="rm_passes", default=5, type="int")
parser.add_option("-s", "--strong", dest="strong", default=False, action="store_true")
parser.add_option("-S", "--sequential", dest="sequential", default=False, action="store_true")
options, args = parser.parse_args()

verbose = options.verbose

if options.bits < 2:
    print "Minimum number of bits is 2"
    exit(1)

if verbose == 1:
    # Unbuffered output
    sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

if options.strong and verbose:
    print "Note: You reduce the overall number of primes available by using -s"

if not options.sequential and len(args) > 0:
    for p in args:
        if verbose: print "Prime given on command line:", p
        isp,why = quick_prime_test(p)
        if isp is not None:
            isp = is_prime(p)
            if verbose == 1: print ""
        else:
            if verbose: print "Quick test:", why
        if isp:
            isnot = " not"
        else:
            isnot = ""
        print "Number is%s prime:"%isnot
        print p
    exit()

if options.sequential and len(args) > 0:
    n = args.pop(0)
    if len(args) > 0:
        print "Only one seed can be used with -S"
    n = int(n)
    options.bits = bits_in(n)
    if n % 2 == 0: n = n + 1
    previous = n - 2
    if n  < 1:
        print "Sorry, starting point was too small"
        exit(1)

for i in range(options.count,):
    new = None
    if previous is not None: new = previous+2
    p = generate_prime(options.bits,new)
    if options.sequential: previous = p
    if verbose > 1:
        isstrong = ""
        if options.strong: isstrong = "cryptographically strong "
        print "Generated", isstrong, "prime:"
    elif verbose:
        print ""
    print "%d"%p

exit()

# The original scirpts docs. Use "perldoc" on this program to extract and
# display
perldoc = '''
__END__

=head1 NAME

mkprime - Generate large prime numbers randomly

=head1 SYNOPSIS

  mkprime [--help] [--man] [-hvVRsS] [-b <bits>] [-c <count>]
       [-t <nthreads>] [-r <rabin-miller-iterations>] [<number>]

  mkprime [-v] [-V] [-S] [-r <iterations>] <number>...

       -h              Usage summary
       -m              Show manual page
       -v              Verbose mode
       -V              More vebosity
       -B <library>    Math::BigInt implementation library name
       -b <bits>       Number of bits in result [128]
       -c <count>      Number of primes to generate [1]
       -r <iterations> Number of iterations of Rabin-Miller prime test
       -R              Force use of non-pseudorandom number gen
       -s              Require cryptographically strong primes
       -S              Sequential numbers instead of random
       -t <nthreads>   Number of threads to run in parallel

=head1 DESCRIPTION

Gernate a large prime number. This algorithm is used to generate a
random number which has a high degree of likelyhood to be prime.
While it is very hard to determine that a number is prime (which
would require proving that it cannot be factored, a problem believed
to be as hard as actually factoring it), it is trivial to verify
that a number is very likely to be prime using a sieve called the
Rabin-Miller test.

This program uses that test in 5 passess to virtually guarantee that
the number is a prime. Finding a number that meets that requirement,
however, can take some time, depending on the number of bits requested
(see the C<--bits> option). The number of passes can be increased
for greater accuracy (see the C<--iterations> option).

=head1 WARNINGS

Performance can vary radically depending on your version of Perl and/or
your installed modules. You will, at a minimum, want to install the latest
C<Math::BigInt::GMP> and run perl 5.8.8 or later (5.10 was used in development).

Also, be aware that threading support is dodgy at best because of a known bug.
See the C<--threads> option for more details.

See also, B<THREADING ISSUES>, below.

=head1 OPTIONS

=over 5

=item C<-h>

=item C<--help>

Generate a short usage summary.

=item C<--man>

Print this manual.

=item C<-v>

=item C<--verbose>

=item C<-V>

=item C<--extra-verbose>

C<-v> or C<--verbose> will turn on some useful, but cryptic
status information as generation procedes.

C<-V> or C<--extra-verbose> will turn on very verbose output
that will give a textual description of the progress.

=item C<-B>

=item C<--bigint-library>

Given the name of a library such as FastCalc, force the use of that library.

This primarily exists to override the workaround where C<--threads> disables
the use of the GMP backend C<Math::BigInt::GMP>. The relevant bug is at:

 https://rt.cpan.org/Ticket/Display.html?id=49336

If that bug has been resolved in your installed version of
C<Math::BigInt::GMP>, then you can use C<-B GMP -t n> to force the
use of I<n> threads while continuing to use the fast backend.

If that bug has not been fixed, then expect the above switches to cause
a segentation fault (internal perl crash).

=item C<-b>

=item C<--bits>

Takes an integer as a parameter and generates a prime of that many
bits.

=item C<-c>

=item C<--count>

Takes an integer as a parameter and generates that many primes.

=item C<-R>

=item C<--no-pseudorandom>

Prevents the use of the system's pseudo-random number generation.
This program relies on the system's F</dev/urandom> generator
by default, but when using this option, the use of F</dev/random>
is forced. The difference between the two is the behavior
when the system's entropy pool is depleted. F</dev/random> will
block, waiting for more entropy, while F</dev/urandom> will fall
back to a pseudo-random generator, seeded by the last available
entropy. For most purposes the default should be sufficient.

=item C<-r>

=item C<--rabin-miller-iterations>

=item C<--iterations>

Takes an integer as a parameter and sets the number of Rabin-Miller
iterations to use to perform. This test is performed on any number
which might be a prime, and each iteration increases the assurance
that the number is, in fact a prime. The default is 5, which should
be sufficient for most purposes.

To quote Wolfram MathWorld:

"Monier (1980) and Rabin (1980) have shown that a composite number
passes the test for at most 1/4 of the possible bases I<C<a>>. If I<C<N>> multiple
independent tests are performed on a composite number, then the
probability that it passes each test is I<C<1/4^N>> or less."

So, the probability of a number being composite after passing 5
iterations would be 1/4^5 or about 0.01%, which is considered
sufficient for this application, given that a static search of many
low prime factors is also applied, further decreasing the chances
of a false positive. For a 0.0015% chance, set C<--iterations> to
8, and so on.

=item C<-s>

=item C<--strong>

Turn on "strong" mode, where we test C<(p-1)/2> for primality too.
If both I<C<p>> and I<C<(p-1)/2>> are prime, then the number is
well suited for cryptographic applications.

=item C<-S>

=item C<--sequential>

When used in combination with C<--count>, specifies that sequential
primes should be generated, rather than picking a random starting point
for each subsequent prime.

Normally, when a number is specified on the command-line, it is tested
for primality alone. However, with the C<--sequential> option, that
number is treated as a the starting point, and sequential primes are
searched for, from that point.

See B<THREADING ISSUES> for information on the combination of
C<--threads> and this argument.

=item C<-t>

=item C<--threads>

Given a number, sets that number as the maximum number of threads. The
default is 1. Each number to be considered is evaluated in its own thread.
There is no thread pooling, but fairly few threads need to be created when
compared the amount of raw computation going on, so the thread creation
overhead should be very small.

See B<THREADING ISSUES> for information on the combination of
C<--threads> and this argument.

=back

=head1 DIAGNOSTICS

Most of the output of this program is self-expanitory. However, there are
two diagnostic "verbosity" modes. When you use C<-V> you get human-readable
output that is very verbose. When you use C<-v> you get a terse output that
indicates what progress is being made, but needs some explanation.

Each character in the C<-v> output indicates some sort of status:

 . - A new prime is being tested
 R - The Rabin-Miller test is being applied
 + - Rabin-Miller test is positive, but inconclusive
 _ - Rabin-Miller failed for this number (not prime)
 * or ! - Rabin-Miller passed (probably prime)
 (...) - Sub-test when using -s
 ~ - Sub-test passed
 ? - Sub-test failed
 ^ - An unusual result in Rabin-Miller

The Rabin-Miller test is applied multiple times, so you will often see
something like this:

 R*R++!R+!R++!R*

Indicating that there were five passes. The first and the last passed
immediately. The middle three were inconclusive at first and required
more testing.

=head1 THREADING ISSUES

When using C<--threads> to test multiple potential primes at once, it is
possible to also use C<--sequential>. However, when you use these two
options together, the guarantees given buy C<--sequential> are modified.
You are only guaranteed that each reported result will be larger than the
previous. Intermediate results may be lost.

This can be especially problematic when searching from a fixed point. For
example, the result of C<mkprime -S -c 8 50> and of the same command-line
with C<-t 2> added will typically be different, skipping the 73 for example.

It is important to be aware of this limitation so that assertions are not
made about the sequential nature of results when running in threaded mode.

The results are otherwise just as correct, just not sequential.

=head1 AUTHOR

Written in 2001 by Aaron Sherman.

Permission to use and distribute this program is granted under the the
same terms as Perl 5.10.0, itself
(see L<http://perldoc.perl.org/perlartistic.html>)

=head1 SEE ALSO

L<perl>, L<Math::BigInt>, L<Math::Prime::XS> L<Crypt::Primes>

=cut

Primes that are used for testing. This list is a trade-off between
the amount of time that it takes to test against each number and the
number of composits it will help us discover.

'''
