#!/usr/bin/python

# Testing functions for the Pathfinde treasure generator

import logging
import unittest

from pathfindertreasure import \
    D20Treasure, Roller, TreasureGenerator, D20Coin, D20Weapon

class TestD20Treasure(unittest.TestCase):
    """Unit tests for the D20Treasure class"""

    def setUp(self):
        pass

    def test_simple(self):
        """Test simple treasure creation"""

        name="nothing useful"
        description="Realy, nothing useful."

        treasure = D20Treasure(
            value=10,
            sale_value=20,
            name=name,
            description=description)

        self.assertEqual(treasure.value, 10)
        self.assertEqual(treasure.sale_value, 20)
        self.assertEqual(treasure.name, name)
        self.assertEqual(treasure.description, description)

class TestD20Coin(unittest.TestCase):
    """A test suite for the D20Coin class"""

    def test_convert_coin_types(self):
        """Try the four coin type conversions"""

        self.assertEqual(D20Coin.pp(1), 1000)
        self.assertEqual(D20Coin.gp(1), 100)
        self.assertEqual(D20Coin.sp(1), 10)
        self.assertEqual(D20Coin.cp(1), 1)

    def test_coin_treasure(self):
        """Create a coin-only treasure object"""

        treasure = D20Coin(pp=1, gp=2, sp=3, cp=4)
        self.assertEqual(treasure.value, 1234)
        self.assertEqual(treasure.sale_value, 1234)
        self.assertEqual(treasure.name, "coin")
        self.assertEqual(treasure.description, "1pp 2gp 3sp 4cp")

class TestRoller(unittest.TestCase):
    """A test suite for the Roller class"""

    def test_roll_one_die(self):
        """A single die roll test"""
        for n in range(10):
            self.assertTrue(Roller.roll(sides=6) in (1,2,3,4,5,6))

    def test_roll_parser(self):
        """Roll dice by using string specs"""

        r = Roller.roll_parser("d1")
        self.assertEqual(r, 1)
        r = Roller.roll_parser("1d1")
        self.assertEqual(r, 1)
        r = Roller.roll_parser("1d1+1")
        self.assertEqual(r, 2)

class TestTreasureGenerator(unittest.TestCase):
    """A test suite for the TreasureGenerator class"""

    def test_constructor(self):
        """Just construct a TreasureGenerator"""

        treasure = TreasureGenerator(apl=10)
        self.assertTrue(treasure is not None)

    def test_get_value(self):
        """Call the get_value method"""

        value = TreasureGenerator(apl=10).get_value()
        self.assertTrue(value >= D20Coin.gp(int(5450.0-(5450.0*0.2))))
        self.assertTrue(value <= D20Coin.gp(int(5450.0+(5450.0*0.2))))

class TestD20Weapon(unittest.TestCase):
    """A test suite for the D20Weapon class"""

    def test_random(self):
        """Generate a random weapon"""

        weap = D20Weapon.random_weapon()
        self.assertTrue(weap.value > 0)
        self.assertTrue(weap.sale_value > 0 and weap.sale_value < weap.value)
        self.assertTrue(weap.combat is not None)
        self.assertTrue(weap.material is not None)

if __name__ == '__main__':
    unittest.main()
