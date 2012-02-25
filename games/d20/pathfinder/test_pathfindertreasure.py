#!/usr/bin/python

# Testing functions for the Pathfinde treasure generator

import unittest

from pathfindertreasure import D20Treasure

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

