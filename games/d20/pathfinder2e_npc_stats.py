#!/usr/bin/env python3

import argparse
import requests
import urllib.parse
import datetime
import time
import re
import logging
import io
import csv
import sys
from lxml import html
from cached_property import cached_property


def scrub(value):
    """Scrub trailing garbage from a string"""

    if value:
        return re.sub(r'\s*([,;]+\s*)$', '', value).strip()
    return value

def aon_xpath_basic(name):
    """The xpath for a basic attribute"""

    return f"//b[text()='{name}']"

def aon_xpath_linked_list(name, target):
    """The xpath for a list entry with linked values"""

    return aon_xpath_basic(name) + f"/following-sibling::a[contains(@href, '{target}')]"

class AonObject:
    """A generic Archives of Nethys object"""

    def __init__(self, html_content, url=None, logger=None):
        self.html_content = html_content
        self.url = url
        self.logger = logger or logging.getLogger(__name__)

    @property
    def content_io(self):
        return io.StringIO(self.html_content)

    @cached_property
    def elements(self):
        return html.parse(self.content_io)


class AonNpc(AonObject):
    xpath_npc = "//span[@id='ctl00_MainContent_DetailedOutput']"
    xpath_npc_details = {
        "name": "./h1[@class='title']/a",
        "level": "./h1[@class='title']/span",
        "image": "./a/img[@class='thumbnail']",
        "alignment": ".//span[@class='traitalignment']",
        "size": ".//span[@class='traitsize']",
        "traits": ".//span[@class='trait']",
        "source": aon_xpath_linked_list("Source", "paizo.com/products"),
        "perception": aon_xpath_basic("Perception"),
        "skills": ".//b[text()='Skills']/following-sibling::a[contains(@href, 'Skills.aspx')]",
        "languages": aon_xpath_linked_list("Languages", "Languages.aspx"),
        "str": aon_xpath_basic("Str"),
        "dex": aon_xpath_basic("Dex"),
        "con": aon_xpath_basic("Con"),
        "int": aon_xpath_basic("Int"),
        "wis": aon_xpath_basic("Wis"),
        "cha": aon_xpath_basic("Cha"),
        "items": aon_xpath_basic("Items"),
        "ac": aon_xpath_basic("AC"),
        "fort_save": aon_xpath_basic("Fort"),
        "ref_save": aon_xpath_basic("Ref"),
        "will_save": aon_xpath_basic("Will"),
        "hp": aon_xpath_basic("HP"),
        "speed": aon_xpath_basic("Speed"),
        "melee": "./span[@class='hanging-indent' and ./b/text()='Melee']",
        "ranged": "./span[@class='hanging-indent' and ./b/text()='Ranged']",
        "spells": "./b[contains(., 'Spells')]",
        "other": "./span[@class='hanging-indent' and not(./b/text()='Melee' or ./b/text()='Ranged')]",
    }
    text_fields = { "name", "level", "alignment", "size" }
    list_fields = {
        "source", "traits", "skills", "languages", "items", "items_shield",
        "melee", "ranged", "spells", "other",
    }
    numeric_fields = {
        "perception", "str", "dex", "con", "int", "wis", "cha", "ac", "fort_save",
        "ref_save", "will_save", "hp",
    }
    all_fields = (
        "name", "url", "level", "image", "alignment", "size", "traits", "source",
        "perception", "skills", "languages", "str", "dex", "con", "int",
        "wis", "cha", "items",
        "ac", "fort_save", "ref_save", "will_save",
        "hp", "speed", "melee", "ranged", "spells", "other",
    )

    # Applied to melee and ranged nodes
    xpath_npc_combat_traits = ".//a[contains(@href, 'Traits.aspx')]"
    xpath_npc_combat_damage = aon_xpath_basic("Damage")

    @cached_property
    def npc(self):
        """The body of the NPC definition"""

        return self.elements.xpath(self.xpath_npc)[0]

    def xpath_get_detail(self, name):
        return self.npc.xpath(self.xpath_npc_details[name])

    def __getattr__(self, name):
        """Fallback for fetching NPC fields"""

        def content(value):
            value = value.tail or value.text
            return scrub(value)

        self.logger.debug(f"Requested dynamic field {name}")
        if name in self.xpath_npc_details:
            value = self.xpath_get_detail(name)
            self.logger.debug(f"field {name} value is {value!r}")
            if not name in self.list_fields:
                if value:
                    value = value[0]
                    self.logger.debug(f"Grabbed first element of {name}: {value!r}")
                else:
                    value = None
            if value is None:
                return value
            elif name in self.text_fields:
                value = content(value)
            elif name in self.list_fields:
                list_func = f"{name}_list"
                if hasattr(self, list_func):
                    value = ", ".join(scrub(item) for item in getattr(self, list_func)() if item)
                else:
                    value = ", ".join(content(e) for e in value if e.text or e.tail)
            else:
                value = content(value)
            return value

        raise AttributeError(f"Unknown NPC attribute {name}")

    def skills_list(self):
        skills = self.xpath_get_detail("skills")
        for skill in skills:
            detail = skill.xpath("./u")
            if not detail:
                continue
            detail = detail[0]
            tail = scrub(detail.tail or skill.tail)
            yield f"{detail.text} {tail}"

    def traits_list(self):
        traits = self.xpath_get_detail("traits")
        for trait in traits:
            detail = trait.xpath("./a")
            if detail:
                yield scrub(detail[0].text)

    def source_list(self):
        sources = self.xpath_get_detail("source")
        for source in sources:
            detail = source.xpath("./i")
            if detail:
                yield scrub(detail[0].text)

    def languages_list(self):
        sources = self.xpath_get_detail("languages")
        for source in sources:
            detail = source.xpath("./u")
            if detail:
                yield scrub(detail[0].text)

    def melee_list(self):
        values = self.xpath_get_detail("melee")

        for value in values:
            yield self.element_str(value)

    def ranged_list(self):
        values = self.xpath_get_detail("ranged")

        for value in values:
            yield self.element_str(value)

    def spells_list(self):
        values = self.xpath_get_detail("spells")

        for value in values:
            yield "".join(
                self.element_str(element)
                for element in self.to_end_of_line(value))

    @property
    def items(self):
        values = self.xpath_get_detail("items")

        if values:
            items = self.to_end_of_line(values[0])
        else:
            return None
        if items:
            items.pop(0)
        return "".join(
            self.element_str(element)
            for element in items)

    def other_list(self):
        values = self.xpath_get_detail("other")

        for value in values:
            yield self.element_str(value)

    def element_str(self, element):
        return str(html.tostring(element, method="text", encoding="utf8"), encoding="utf8")

    def to_end_of_line(self, element):
        """Scan from the current element to end of line and return all elements"""

        elements = []
        if element is None:
            return []
        while element is not None:
            elements.append(element)
            element = element.getnext()
            if hasattr(element, "tag") and element.tag and element.tag in ('hr', 'br'):
                break
        return elements

    @property
    def image(self):
        values = self.xpath_get_detail("image")
        if values:
            return values[0].get("src")
        else:
            return None

    @property
    def level(self):
        try:
            return scrub(self.xpath_get_detail("level")[0].text.split(" ")[1])
        except (IndexError, ValueError):
            return None

    def as_dict(self):
        """Return NPC as dict"""

        return {field: getattr(self, field) for field in self.all_fields}


class AonBrowser:
    NPCS_LIST = "https://2e.aonprd.com/NPCs.aspx?Letter=All"
    # Should also use xpath for this...
    NPCS_LIST_RE = re.compile(r'href=\W*(NPCs\.aspx\?ID=\d+)\W+?\<u\>\s*([^\<]+?)\s*\<\/u', re.IGNORECASE)

    def __init__(self, delay_offset=1, timeout=10, logger=None):
        self.delay_offset = delay_offset
        self.delay_last = None
        self.timeout = timeout
        self.logger = logger or logging.getLogger(__name__)
        self.session = requests.Session()
        self.__last_url = None

    def aon_get(self, url, reason="get AoN page", headers=None):
        if self.delay_last:
            offset = datetime.timedelta(seconds=self.delay_offset)
            end_delay = self.delay_last + offset
            waiting = (end_delay - datetime.datetime.now()).total_seconds()
            if waiting > 0:
                self.logger.debug(f"{reason}: pause {waiting} sec")
                time.sleep(waiting)
        self.delay_last = datetime.datetime.now()

        self.logger.debug(f"{reason}: get {url}")
        request_headers = {'Content-Type': 'text/html'}
        if headers:
            request_headres.update(headers)
        if self.__last_url:
            url = urllib.parse.urljoin(self.__last_url, url)
        result = self.session.get(url, timeout=self.timeout, headers=request_headers)
        result.raise_for_status()
        # Only update on success
        self.__last_url = url

        return result

    def aon_clean(self, result):
        """Return the result text after scrubbing"""

        text = result.text
        text = text.replace('script async', 'script ')
        return text

    def get_npcs(self):
        npcs_list = self.aon_get(self.NPCS_LIST, reason="NPC list")
        for npc_match in self.NPCS_LIST_RE.finditer(self.aon_clean(npcs_list)):
            yield self.get_npc(*npc_match.groups())

    def get_npc(self, url, name):
        npc_page = self.aon_get(url, reason=name)
        return AonNpc(self.aon_clean(npc_page), url=self.__last_url, logger=self.logger)


def main():
    parser = argparse.ArgumentParser(description="Data reader for Archives of Nethys")
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Debugging output")
    parser.add_argument(
        "-o", "--output",
        action="store",
        choices=("text", "csv"),
        default="text",
        help="Output format")
    parser.add_argument(
        "--source",
        action="store",
        choices=("npc",),
        default="npc",
        help="Source listing to read from AoN")
    parser.add_argument(
        "--limit",
        action="store",
        type=int,
        metavar="N",
        default=None,
        help="Limit fetched records to N")
    parser.add_argument(
        "--limit-fields",
        action="store",
        default=None,
        help="Comma-separated list of fields to select")

    options = parser.parse_args()

    logger = logging.getLogger(__name__)
    if options.debug:
        logging.basicConfig(level=logging.DEBUG)
        logger.setLevel(logging.DEBUG)
    limit_fields = re.split(r'\s*,\s*', options.limit_fields) if options.limit_fields else None
    aon = AonBrowser(logger=logger)
    if options.source == "npc":
        if options.output == "csv":
            writer = csv.DictWriter(sys.stdout, fieldnames=limit_fields or AonNpc.all_fields)
            writer.writeheader()
        for row, npc in enumerate(aon.get_npcs()):
            if options.limit and options.limit == row:
                break
            npc_dict = npc.as_dict()
            if limit_fields:
                npc_dict = {field: npc_dict[field] for field in limit_fields}
            if options.output == "csv":
                writer.writerow(npc.as_dict())
            elif options.output == "text":
                print(repr(npc.as_dict()))
            else:
                raise ValueError(f"Unknown output mode {options.output}")
    else:
        raise ValueError(f"Unknown source: {source}")


if __name__ == '__main__':
    main()
