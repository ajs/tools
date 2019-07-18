#!/usr/bin/env python3

# From the announcement:

# PERL WEEKLY CHALLENGE - 017

# Task #1

# Create a script to demonstrate Ackermann function. The Ackermann function
# is defined as below, m and n are positive number:

#  A(m, n) = n + 1                  if m = 0
#  A(m, n) = A(m - 1, 1)            if m > 0 and n = 0
#  A(m, n) = A(m - 1, A(m, n - 1))  if m > 0 and n > 0

#Example expansions as shown in wiki page.

# A(1, 2) = A(0, A(1, 1))
#         = A(0, A(0, A(1, 0)))
#         = A(0, A(0, A(0, 1)))
#         = A(0, A(0, 2))
#         = A(0, 3)
#         = 4


import sys
import numpy
import argparse


def recurseA(m, n):
	if m == 0:
		return n + 1
	elif n == 0:
		return recurseA(m - 1, 1)
	else:
		return recurseA(m - 1, recurseA(m, n - 1))

def numpyA(m , n):
	ack = numpy.array([m, n])
	while len(ack) > 1:
		if ack[-2] == 0:
			# A(0, n) = n + 1
			n = ack[-1]
			ack.resize(len(ack) - 1)
			ack[-1] = n + 1
		elif ack[-1] == 0:
			# A(m!=0, 0) = A(m - 1, 1)
			ack[-2] -= 1
			ack[-1] = 1
		else:
			# A(m!=0, n!=0) = A(m - 1, A(m, n - 1))
			m = ack[-2]
			n = ack[-1]
			ack[-2] = m - 1
			ack[-1] = m
			numpy.append(ack, n - 1)
	return int(ack[0])

def listA(m, n):
	ack = [m, n]
	while len(ack) > 1:
		if ack[-2] == 0:
			# A(0, n) = n + 1
			n = ack.pop()
			ack[-1] = n + 1
		elif ack[-1] == 0:
			# A(m!=0, 0) = A(m - 1, 1)
			ack[-2] -= 1
			ack[-1] = 1
		else:
			# A(m!=0, n!=0) = A(m - 1, A(m, n - 1))
			m = ack[-2]
			n = ack[-1]
			ack[-2] = m - 1
			ack[-1] = m
			ack.append(n - 1)
	return ack[0]

def doA(m, n, count, A=listA, **kwargs):
	for _ in range(count):
		print(A(m, n, **kwargs))

def get_args():
	parser = argparse.ArgumentParser(description="Ackermann functions")
	parser.add_argument('--mode',
		action='store',
		default='list',
		choices=('list', 'numpy', 'recurse'),
		help="Select the mode to run in")
	parser.add_argument('--count',
		action='store',
		type=int,
		default=1,
		help="Number of times to resolve")
	parser.add_argument('m', type=int, help="First argument (m in A(m, n))")
	parser.add_argument('n', type=int, help="Second argument (n in A(m, n))")
	return parser.parse_args()


if __name__ == '__main__':
	args = get_args()
	funcmap = {
		'list': listA,
		'numpy': numpyA,
		'recurse': recurseA,
	}
	doA(args.m, args.n, count=args.count, A=funcmap[args.mode])
