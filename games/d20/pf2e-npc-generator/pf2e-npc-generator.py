# A random NPC generator

import pathlib

import yaml


class DataSources:
    def __init__(self, directory=None):
        """Load the data files"""

        self.directory = directory
        self.racial = self.get_racial_data()
        self.occupations = self.get_occupation_data()

    def path_from_file(self, filename):
        path = pathlib.Path(filename)
        if self.directory:
            return path.relative_to(self.directory)

    def get_racial_data(self):
        with open(self.path_from_file("npc_racial_data.yaml")) as data_file:
            return yaml.load(data_file.read())

    def get_occupation_data(self):
        with open(self.path_from_file("npc_occupation_data.yaml")) as data_file:
            return yaml.load(data_file.read())


@dataclass.dataclass
class Npc:
    race: str
    level: int
    occupation: str



class NpcMaker:
    def __init__(self):
        self.sources = DataSources()

    def make_npc(self, level, race, occupation):
        
