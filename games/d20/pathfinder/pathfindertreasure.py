#
# A module for generating Pathfinder treasure.
#

import re
import yaml
import random
import logging

logging.basicConfig(level=logging.DEBUG)

class D20Treasure(object):
    def __init__(self, value, sale_value, name, description):
        self.value = value
        self.sale_value = sale_value
        self.name = name
        self.description = description

    def mergeable(self):
        return False

    def describe(self):
        return "%s: %s" % (self.name, self.description)

class D20Coin(D20Treasure):
    @staticmethod
    def pp(num):
        """Convert a number of platinum coins to the internal form"""
        return int(float(num) * 1000)

    @staticmethod
    def gp(num):
        """Convert a number of gold coins to the internal form"""
        return int(float(num) * 100)

    @staticmethod
    def sp(num):
        """Convert a number of silver coins to the internal form"""
        return int(float(num) * 10)

    @staticmethod
    def cp(num):
        """Convert a number of copper coins to the internal form"""
        return int(num)

    @staticmethod
    def coin_value(num, use_plat=False):
        """Return a string representation of a coin value"""

        parts = []
        if use_plat and num >= 1000:
            pp_part = int(num/1000)
            num -= pp_part*1000
            parts.append("%dpp" % pp_part)
        if num >= 100:
            gp_part = int(num/100)
            num -= gp_part*100
            parts.append("%dgp" % gp_part)
        if num >= 10:
            sp_part = int(num/10)
            num -= sp_part*10
            parts.append("%dsp" % sp_part)
        if len(parts) == 0 or num > 0:
            cp_part = int(num)
            parts.append("%dcp" % cp_part)

        return " ".join(parts)

    def __init__(self, pp=0, gp=0, sp=0, cp=0):
        value = D20Coin.pp(pp) + D20Coin.gp(gp) + D20Coin.sp(sp) + \
            D20Coin.cp(cp)
        self.pps = pp
        self.gps = gp
        self.sps = sp
        self.cps = cp
        super(D20Coin, self).__init__(
            value,
            value,
            "coin",
            self.describe_coin())

    def describe_coin(self):
        types = []
        if self.pps != 0:
            types.append("%dpp" % self.pps)
        if self.gps != 0:
            types.append("%dgp" % self.gps)
        if self.sps != 0:
            types.append("%dsp" % self.sps)
        if self.cps != 0:
            types.append("%dcp" % self.cps)
        return " ".join(types)

    def merge(self, coin):
        """Merge this coin treasure and another"""
        self.value += coin.value
        self.sale_value += coin_value
        self.pps += coin.pps
        self.gps += coin.gps
        self.sps += coin.sps
        self.cps += coin.cps
        self.description = self.describe_coin()

    def mergeable(self):
        return True

class D20Weapon(D20Treasure):
    def __init__(self, name, weapon_type, weapon_data):
        self.combat = weapon_data['combat']
        cost = D20Coin.gp(float(weapon_data['cost']))
        self.material = weapon_data.get('material', 'metal')
        self.count = weapon_data.get('count', 1)
        self.heads = weapon_data.get('heads', 1)
        self.weight = float(weapon_data.get('weight', 0))
        self.heft = weapon_data.get('heft', None)
        super(D20Weapon, self).__init__(
            value=cost,
            sale_value=cost/2,
            name=name,
            description="%s %s weapon" % (weapon_type, weapon_data['combat']))

    def describe(self):
        name = self.name
        if self.count > 1:
            name += " (x%d)" % self.count
        return name

    @staticmethod
    def get_weapons(max_value=None):
        weapons = TableCache.get_table('core_weapon_list')
        if max_value is None:
            return weapons
        else:
            affordable_weapons = []
            for weap in weapons:
                if int(weap.cost) <= max_value:
                    affordable_weapons.append(weap)
            return affordable_weapons

    @staticmethod
    def get_weapon_frequencies():
        return TableCache.get_table('weapon_frequency_table')

    @staticmethod
    def random_weapon(max_value=None, masterwork='random'):
        freq = D20Weapon.get_weapon_frequencies()
        weapon_type = Roller.roll_on_table(freq)[0]
        weapons = D20Weapon.get_weapons(max_value=max_value)
        weapon_data = Roller.pick_one(weapons[weapon_type])
        weapon = D20Weapon(weapon_data['name'], weapon_type, weapon_data)

        special_material = Roller.d100()
        sm_desc = None
        sm_cost = 0
        sm_masterwork = masterwork
        if special_material >= 95:
            if masterwork is not False:
                if weapon.material == 'wood':
                    sm_desc = 'darkwood'
                    sm_cost = D20Coin.gp(10*weapon.weight)
                    sm_masterwork = True
                elif weapon.material == 'metal':
                    metals = ('adamantine', 'cold iron', 'mithral',
                              'alchemical silver')
                    metal = Roller.pick_one(metals)
                    sm_desc = metal
                    if metal == 'adamantine':
                        if weapon.count > 1:
                            sm_cost = D20Coin.gp(60 * weapon.count)
                        else:
                            sm_cost = D20Coin.gp(3000)
                        sm_masterwork = True
                    elif metal == 'cold iron':
                        # The rules say you can have one head be cold
                        # cold iron and another head be something else.
                        # I say that's silly.
                        sm_cost = weapon.value * weapon.heads
                    elif metal == 'mithral':
                        sm_cost = D20Coin.gp(500 * weapon.weight)
                        sm_masterwork = 1
                    elif metal == 'alchemical silver' and weapon.heft:
                        if weapon.count > 1:
                            sm_cost = D20Coin.gp(2)
                        elif weapon.heft == 'light':
                            sm_cost = D20Coin.gp(20)
                        elif weapon.heft == '1-handed':
                            sm_cost = D20Coin.gp(90)
                        else:
                            sm_cost = D20Coin.gp(180)

        if sm_desc is not None:
            if max_value is None or weapon.value + sm_cost <= max_value:
                weapon.name = sm_desc + ' ' + weapon.name
                weapon.value += sm_cost
                weapon.sale_value += sm_cost/2
                masterwork = sm_masterwork

        if masterwork is False:
            return weapon
        elif masterwork == 'random':
            mwkroll = Roller.d100()
            if mwkroll < 90:
                return weapon

        if weapon.count > 1:
            new_value = weapon.value + D20Coin.gp(6 * weapon.count)
        else:
            new_value = weapon.value + D20Coin.gp(300 * weapon.heads)

        if max_value is not None and new_cost > max_value:
            return weapon

        weapon.name = "masterwork " + weapon.name
        weapon.value = new_value
        weapon.sale_value = new_value / 2
        return weapon

class Roller(object):
    """Various tools for rolling dice"""

    DICE_RE = re.compile(r'^\s*(\d+)?[Dd](\d+)\s*(\+\s*(\d+))?')

    @staticmethod
    def roll1(sides=100, add=0):
        return int(random.randrange(sides)) + 1 + add

    @staticmethod
    def roll(sides=100, count=1, add=0):
        return reduce(
            lambda x,y: x+y,
	    (Roller.roll1(sides, add=add) for c in range(count)))

    @staticmethod
    def roll_parser(dice_str):
        """Parse a dice string and roll the requested dice"""

        m = Roller.DICE_RE.match(dice_str)
        if not m:
            raise TreasureError("Cannot parse dice directive: %s" % dice_str)
        count = (m.group(1) and int(m.group(1))) or 1
        sides = int(m.group(2))
        add = (m.group(3) and int(m.group(3))) or 0
        return Roller.roll(sides=sides, count=count, add=add)

    @staticmethod
    def plus_or_minus(value, plus, minus):
        """Return value modified up by plus percent or down by minus"""
        value = float(value)
        min = value - (value * (float(minus)/100.0))
        max = value + (value * (float(plus)/100.0))
        return int(random.randint(int(min), int(max)))

    @staticmethod
    def roll_on_table(table):
        """
        Given a list of lists where each sub-list begins with a number
        between 1 and 100, inclusive, return the remaining elements of
        the inner list corresponding to the smallest number that is
        not less than a randomly selected number in the range 1:100,
        inclusive.

        This simulates a lookup table with percentile ranges for
        each item.
        """

        pick = random.randint(1,100)
        for row in table:
            if int(row[0]) >= pick:
                return row[1:]
        return None

    @staticmethod
    def d6():
        return Roller.roll1(sides=6)

    @staticmethod
    def d20():
        return Roller.roll1(sides=20)

    @staticmethod
    def d100():
        return Roller.roll1(sides=100)

    @staticmethod
    def pick_one(table):
        """Return one random element of a sequence or dict"""

        try:
            return table[random.sample(table.keys(), 1)[0]]
        except AttributeError:
            return random.sample(table, 1)[0]

class TableCache(object):
    TABLES={}
    @staticmethod
    def get_table(table_name):
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

    def generate_horde(self, count=1):
        horde = []
        for horden in range(count):
            value = self.get_value()
            horde.append(self.treasure_of_value(value))
        return horde

    def get_value(self):
        """Return an internal form of the gp value listed by party level"""

        self.values = TableCache.get_table('treasure_values_per_encounter')
        return Roller.plus_or_minus(
            D20Coin.gp(self.values[self.track][self.apl-1]),
            plus=20,
            minus=20)

    def treasure_of_value(value):
        return D20Treasure(
            value=value,
            sale_value=value,
            name="generic treasure",
            description="Unspecified")
