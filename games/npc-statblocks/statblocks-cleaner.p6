#!/usr/bin/env perl6

use v6.d;

use Grammar::Tracker;

subset FileName of Str where *.IO.f;

class RawFile {
	has $.handle;

	submethod BUILD(FileName :$raw-file) {
		$!handle = $raw-file.IO.open(:r);
	}

	method next-block(RawFile:D:) {
		my @block = gather for self.handle.lines -> $line {
			last if $line ~~ /^ :s '----' $/;
			take $line;
		}
		return @block.join("\n") if @block;
		return Nil;
	}

	method blocks(RawFile:D:) {
		lazy gather do loop {
			my $block = self.next-block;
			last unless $block;
			take $block;
		}
	}
}

grammar StatBlock {
	rule TOP {^ <block> $}
	rule block { <title> <subtitle> <section>* }
	rule section { <general-section> | <named-section> }
	rule named-section { <section-heading> <general-section> }
	rule section-heading {
		:ignorecase
		'OFFENSE' | 'DEFENSE' | 'TACTICS' | 'STATISTICS' |
		'SPECIAL' 'ABILITIES'
	}
	rule title {
		:!ratchet
		$<name> = [.*?] <before 'CR' | 'XP' > <title-stats>+
		<creature-racial-info> <class-levels>* <p-rules-citation>?
	}
	rule title-stats { <cr> | <xp> }
	rule cr { 'CR' <cr-number> }
	token cr-number { \d+ [ '/' \d+ ] | <vulgar-fraction> }
	token vulgar-fraction {
		# We want to allow for Unicode "vulgar fractions" like ½
		$<num> = [<:No>]
		# <:No> matches all strange number-like things in unicode, and then
		# we check to see if this number-like thing is composed from parts
		# involving a ⁄ which is the "Fraction Slash" codepoint.
		<?{ $<num>.Str.NFKD.grep(0x2044) }>
	}
	rule xp { 'XP' $<xp-number> = [\d+] }
	rule creature-racial-info {
		<gender>? <race> <sub-race>? <multi-class>?
	}
	token gender { :ignorecase [ 'male' || 'female' ] }
	rule race {
		# I can't tell you what race is, but I can tell you what it
		# isn't... is that social commentary?
		[
			<!before
				   <gender> || <class> || '(' || <alignment>
				|| <section-heading>
			>
			[ \w || '-' ]+
		]+  % \s+
	}
	rule multi-class {
		[<class> <level>]+ % '/'
	}
	token level { <:Number>+ }
	token class {
		:ignorecase
		# Classes
		   "Adept" || "Alchemist" || "Antipaladin" || "Arcanist"
		|| "Aristocrat" || "Barbarian" || "Bard" || "Bloodrager"
		|| "Brawler" || "Cavalier" || "Cleric" || "Commoner"
		|| "Druid" || "Expert" || "Fighter" || "Gunslinger"
		|| "Hunter" || "Inquisitor" || "Investigator" || "Kineticist"
		|| "Magus" || "Medium" || "Mesmerist" || "Monk"
		|| "Ninja" || "Occultist" || "Omdura" || "Oracle"
		|| "Paladin" || "Psychic" || "Ranger" || "Rogue"
		|| "Samurai" || "Shaman" || "Shifter" || "Skald"
		|| "Slayer" || "Sorcerer" || "Spiritualist" || "Summoner"
		|| "Swashbuckler"
		|| "Unchained Barbarian" || "Unchained Monk"
		|| "Unchained Rogue" || "Unchained Summoner"
		|| "Vampire Hunter" || "Vigilante" || "Warpriest" || "Warrior"
		|| "Witch" || "Wizard"
	}
	token alignment { [ 'N' || 'C' || 'L' ] [ 'N' || 'G' || 'E' ] | 'N' }
	rule p-rules-citation { '(' ~ ')' <rules-citation> }
	rule rules-citation {
		:!ratchet
		[ <-[\,\(\)]>+? <page>? ]+ % ','
	}
	token page { \d+ }
	rule subtitle { <alignment> <size> <creature-type> <creature-subtypes>? }
	token size {
		:ignorecase
		< Fine Diminutive Tiny Small Medium Large Huge Gargantuan Colossal >
		<.ws>
		[ '(' ~ ')' ['long' || 'tall'] ]?
	}
	token creature-type {
		< Aberration Animal Construct Dragon Fey Humanoid Ooze Outsider
		  Plant Undead >
		| 'Monstrous' <.ws> 'Humanoid' | 'Magical' <.ws> 'Beast'
	}
	rule creature-subtypes {
		'(' ~ ')' <creature-subtype-list>
	}
	rule creature-subtype-list { <creature-subtype>+ % ',' }
	token creature-subtype {
		"adlet" | "aeon" | "agathion" | "air" | "angel" | "aquatic" | "archon" |
		"asura" | "augmented" | "automaton" | "azata" | "behemoth" | "catfolk" |
		"chaotic" | "clockwork" | "cold" | "colossus" | "daemon" | "dark folk" |
		"deep one" | "demodand" | "demon" | "devil" | "div" | "dwarf" | "earth" |
		"elemental" | "elf" | "evil" | "extraplanar" | "fire" | "giant" | "gnome" |
		"goblinoid" | "godspawn" | "good" | "great old one" | "halfling" |
		"herald" | "hive" | "human" | "incorporeal" | "inevitable" | "kaiju" |
		"kami" | "kasatha" | "kitsune" | "kyton" | "lawful" | "leshy" | "mortic" |
		"mythic" | "native" | "nightshade" | "oni" | "orc" | "protean" |
		"psychopomp" | "qlippoth" | "rakshasa" | "ratfolk" | "reptilian" |
		"robot" | "samsaran" | "sasquatch" | "shapechanger" | "swarm" | "troop" |
		"udaeus" | "unbreathing" | "vanara" | "vishkanya" | "water" | "wayang" |
		"wild hunt"
	}
	rule general-section { .* }
}

sub MAIN(FileName $raw-file) {
	for RawFile.new(:$raw-file).blocks -> $block {
		given StatBlock.parse($block) -> $/ {
			die "Cannot parse block: \n$block\n" unless $/;
			say "Parsed Stat Block for {$<block><title>}";
		}
	}
}