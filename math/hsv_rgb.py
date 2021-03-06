#!/usr/bin/env python3

import argparse
import colorsys

argparser = argparse.ArgumentParser("Print RGB values for all hues")
argparser.add_argument("-t", "--steps", type=int, default=100, help="Number of steps to go through")
argparser.add_argument("-s", "--saturation", type=float, default=1.0, help="Saturation level 0 to 1")
argparser.add_argument("-v", "--value", type=float, default=1.0, help="Value level 0 to 1")
options = argparser.parse_args()

assert options.steps >= 1, "Positive number of steps (--steps) required"
assert 0 <= options.saturation <= 1, "Saturation (--saturation) must be 0.0 to 1.0"
assert 0 <= options.value <= 1, "Value (--value) must be 0.0 to 1.0"

for hue in range(options.steps):
    rgb = colorsys.hsv_to_rgb(hue/float(options.steps), options.saturation, options.value)
    print(",".join("{:02x}".format(int(value*255)) for value in rgb))
