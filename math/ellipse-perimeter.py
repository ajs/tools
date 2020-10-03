#!/usr/bin/env python3

import logging
import scipy
import scipy.special
import sympy
import numpy
import itertools


TUNE_DEFAULT=((0,5), (0,17), (0,5))


def perimeter_scipy(a, b=1):
    e = 1-numpy.divide(numpy.square(b), numpy.square(a))
    return 4 * a * scipy.special.ellipe(e)

def perimeter_sympy(majr, minr=1):

    a, b, w = sympy.symbols('a b w')

    x = a/2 * sympy.cos(w)
    y = b/2 * sympy.sin(w)

    dx = sympy.diff(x, w)
    dy = sympy.diff(y, w)

    ds = sympy.sqrt(dx**2 + dy**2)

    return 2*sympy.Integral(ds.subs([(a,majr),(b,minr)]), (w, 0, 2*sympy.pi)).evalf().doit()

def aaron_estimate(a, b=1, tune=TUNE_DEFAULT):
    r = numpy.divide(a, b) - 1
    basic = r*tune[0]+2*numpy.pi
    correct = numpy.sin(r*tune[1])/tune[2]
    return basic - correct

def error_of(estimate, a, b=1):
    actual = perimeter_scipy(a, b)
    return numpy.abs(numpy.divide((estimate-actual), actual))

def range_in(start, stop, steps):
    start = numpy(start)
    stop = numpy(stop)
    return [start + ((stop-start)/steps)*step for step in range(steps)]

def step_in(value_range, step, steps):
    vmin, vmax = value_range
    range_len = vmax - vmin
    return vmin + step*numpy.divide(range_len, steps)

def tune_step(values, steps):
    shape = itertools.permutations(range(steps), len(values))
    return [[step_in(values[i], step, steps) for i, step in enumerate(row)] for row in shape]

numpy.seterr(all='raise')
best = {}
for a in range(1,20):
    for tune in tune_step(TUNE_DEFAULT, 50):
        #print(tune)
        if tune[2] == 0:
            continue
        est = aaron_estimate(a, tune=tune)
        err = error_of(est, a)
        if a not in best or best[a]["error"] > err:
            #if a in best:
            #    print(f"Old: {best[a]!r}")
            #print(f"Select winner: a={a}, err={err:.5f}, {tune!r}")
            best[a] = {
                "error": err,
                "tune": tune,
            }
    best_a = best[a]
    err = best_a["error"]
    tune = best_a["tune"]
    print(f"Best a={a}, err={err:.5f}: ({tune[0]:.4f}, {tune[1]:.4f}, {tune[2]:.4f})")
