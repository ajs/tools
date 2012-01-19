#!/usr/bin/python

class LoUUnitType(object):
    def __init__(self, type_name):
        self.type_name = type_name

class LoUAttackType(object):
    TYPE_NAMES = {
	'assault': {
	    'battle_intensity': 50,
	    'scouts_only': False,
	    'require_defender_castle': True, 
	    'continuous': False,
	    'plunder': True, },
	'siege': {
	    'battle_intensity': 10,
	    'scouts_only': False,
	    'require_defender_castle': True,
	    'continuous': True,
	    'plunder': False, },
	'plunder': {
	    'battle_intensity': 10,
	    'scouts_only': False,
	    'require_defender_castle': False,
	    'continuous': False,
	    'plunder': True, },
	'scout': {
	    'battle_intensity': 50,
	    'scouts_only': True,
	    'require_defender_castle': False,
	    'continuous': False,
	    'plunder': True, },
    }
    def __init__(self, attack_type_name):
	if attack_type_name in TYPE_NAMES:
	    self.update(TYPE_NAMES[attack_type_name])
	else
	    raise TypeError("No such attack type: %s" % attack_type_name)

class LoUUnit(object):
    def __init__(self, unit_type, advanced=0, n=1):
        self.unit_type = unit_type
        self.advanced = advanced
        self.n = n

class LoUArmy(object):
    def __init__(self, units):
        self.units = units

class LoUDefender(LoUArmy):
    def __init__(self, units, traps=[], wall_level=0, water_access=False):
	self.units = units
	self.traps = [] ; self.traps.extend(traps)
	self.wall_level = wall_level
	self.water_access = water_access

class LoUCombat(object):
    def __init__(self, attacker, defender, attack_type, 
