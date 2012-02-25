#
# A module for generating Pathfinder treasure.
#

import random

class D20Treasure(object):
    def __init__(self, value, sale_value):
        self.value = value
        self.sale_value = sale_value

class Roller(object):
    @staticmethod
    def roll1(sides=100, add=0):
        return random.randrange(sides) + add
    @staticmethod
    def roll(sides=100, count=1, add=0):
        return reduce(
            lambda x,y: x+y, (Roller.roll1(sides, add=add) for c in count))

class TableCache(object):
    TABLES={}
    @staticmethod
    def get_tables(table_name):
        if table_name not in TableCache.TABLES:
            TableCache.TABLES[table_name] = yaml.load(
                open(table_name + '.yaml'))
        return TableCache.TABLES[table_name]

class TreasureGenerator(object):
    def __init__(self, apl, track='medium'):
        if track not in ('slow', 'medium', 'fast'):
            raise TreasureError("Track, '%s', is not slow medium or fast" %
                track)
        self.apl = apl
        self.track = track
    def __iter__(self):
        return self
    def next(self):
        return self.generate()
    def generate(self, count=1):
        horde = []
        for horden in range(count):
            value = self.get_value()
            horde.append(self.treasure_of_value(value))
        return horde
    def get_value(self):
        self.values = TableCache.get_table('treasure_values_per_encounter')
        return Roller.plus_or_minus(
            self.values[self.track][self.apl-1],
            plus=1,
            minus=1)
    def treasure_of_value(value):
        return D20Treasure(
            value=value,
            sale_value=value,
            name="generic treasure",
            description="Unspecified")
