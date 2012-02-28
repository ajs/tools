#!/usr/bin/python
from pathfindertreasure import D20Weapon, D20Coin
import sys

n = (len(sys.argv) > 1 and int(sys.argv[1])) or 20
for n in range(n):
    w = D20Weapon.random_weapon()
    print "%s: cost %s" % (w.describe(), D20Coin.coin_value(w.value))
