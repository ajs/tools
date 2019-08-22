#!/usr/bin/env perl6

use v6.d;

use Grammar::Tracer;

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

role GrammarErrors {
    # Return at most $count characters from the start (or :end) of $s
    sub at-most(Str $s is copy, Int $count, Bool :$end) {
        $s .= subst(/\n/, '\\n', :g);
        return $s if $s.chars <= $count;
        $end ?? $s.substr(*-$count) !! $s.substr(0,$count);
    }

    method syntax-error($match, :$context=20) {
        my $before = at-most($match.prematch ~ $match, $context, :end);
        my $after = at-most($match.postmatch, $context);
        my $where = "$before↓$after";
        $where .= subst(/\n/, '\\n');
        die "Problem reading {self.^name} at: [[$where]]";
    }
}

grammar StatBlock does GrammarErrors {
    rule TOP {^ <block> [$| {self.syntax-error($/)} ]}
    rule block { <title> <subtitle> <general> <section>+ }
    rule section-heading {
        :ignorecase
        'OFFENSE' | 'DEFENSE' | 'TACTICS' | 'STATISTICS' |
        'SPECIAL' 'ABILITIES'
    }
    rule title {
        :!ratchet
        $<name> = [.*?] <before :ignorecase ['CR' | 'XP'] > <title-stats>+
        <creature-race-class-info> <p-rules-citation>?
    }
    rule title-stats { <cr> | <xp> }
    rule cr { 'CR' <cr-number> }
    token cr-number { <integer> [ '/' <integer> ] | <vulgar-fraction> }
    token vulgar-fraction {
        # We want to allow for Unicode "vulgar fractions" like ½
        $<num> = [<:No>]
        # <:No> matches all strange number-like things in unicode, and then
        # we check to see if this number-like thing is composed from parts
        # involving a ⁄ which is the "Fraction Slash" codepoint.
        <?{ $<num>.Str.NFKD.grep(0x2044) }>
    }
    rule xp { 'XP' <integer> }
    rule creature-race-class-info {
        <gender>? <race> <multi-class>?
    }
    token gender { :ignorecase [ 'male' || 'female' ] }
    token race {
        # I can't tell you what race is, but I can tell you what it
        # isn't... is that social commentary?
        [
            <?wb>
            <!before
                   <gender> || <class> || '(' || <alignment>
                || <section-heading>
            >
            <alpha> [ \w || '-' ]+
        ]+  % \s+
    }
    rule multi-class {
        [<class> <archetype>? <level>]+ % '/'
    }
    token level { <integer> }
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
    rule archetype { '(' ~ ')' [ <alpha><[\w\s\-\:]>+ ] }
    token alignment { [ 'N' || 'C' || 'L' ] [ 'N' || 'G' || 'E' ] | 'N' }
    rule p-rules-citation { '(' ~ ')' <rules-citation> }
    rule rules-citation {
        [ <-[\,\(\)]>+ ]+ % [',' || '/']
    }
    token page { <integer> }
    rule subtitle { <alignment> <size> <creature-type> <creature-subtypes>? }
    token size {
        :ignorecase
        < Fine Diminutive Tiny Small Medium Large Huge Gargantuan Colossal >
        <.ws>
        [ '(' ~ ')' ['long' || 'tall'] ]?
    }
    token creature-type {
        :ignorecase

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
    rule section {
        [<defense> | <offense> | <tactics> | <statistics>]
    }

    rule defense { :ignorecase 'DEFENSE' <general> }
    rule offense { :ignorecase 'OFFENSE' <general> }
    rule statistics { :ignorecase 'STATISTICS' <general> }
    rule tactics { :ignorecase 'TACTICS' <tactic>+ }

    rule general { [<stat-thing> ';'?]+ }

    rule stat-thing {
        :!ratchet
        [
            <!before <section-heading>> <category>?
                <bonus>? <label> <stat-thing-suffix>? |
            <saving-throw> |
            <money>
        ]+ % [ ',' || 'or' ]?
    }
    rule stat-thing-suffix {
        [<!before <uses>> <bonus> | <uses> | <damage>] <parenthetical>?
    }
    rule saving-throw {
        <save> <bonus> <save-modifier>?
    }
    rule money {
        <coins>+ % ','
    }
    rule coins {
        <integer>\s*<coin-type>
    }
    token coin-type { :ignorecase < p g s c > [p s?]? }
    rule save-modifier {
        ';'? <save-modifier-body> | '(' ~ ')' <save-modifier-body>
    }
    rule save-modifier-body { <bonus> <vs>? }
    rule vs {
        :ignorecase
        'vs'<:Punctuation>?
        <label>+ % ','
    }
    token save { :i [ 'Fort' | 'Ref' | 'Will' ] }
    # No newline whitespace
    token nns { <+[\s]-[\n]>* }

    token category {
        'Senses' | 'Defensive' <.ws> 'Abilities' | 'Melee' | 'Ranged' |
        'Feats' | 'Skills' | 'Languages' | 'SQ' | 'Gear' |
        'Special' <.ws> 'Attacks' | <class> <.ws> 'Spells' <.ws> 'Known'
    }

    token label {
        <!before <category>>
        [
            <!before <section-heading>>
            <alpha> <[\’\'\w\-]>+
        ]+ % \s+
        <.ws> '*'? <.ws> <parenthetical>?
    }
    token parenthetical { '(' ~ ')' [<-[\(\)]>+] }
    rule bonus {
        :!ratchet
        [[ <score> <unit>? <parenthetical>? ]+ % ',']
    }
    rule uses { <integer> <frequency> | 'at' 'will' }
    rule unit { 'ft' '.'? }
    rule frequency {
        <time-unit>? ['/' | 'per' | 'each'] <time-unit>
    }
    token time-unit {
        rounds? | seconds? | minutes? | hours? | days? | combats? |
        encounters? | ''
    }
    token score { ['+' || '-']? <integer> }
    token damage { '(' ~ ')' <dice> | <dice> }
    token dice { [<integer> \s*]? 'd' <integer> <.ws> <score>? <.ws> <crit>? }
    token crit { '/' [ 'x' <integer> | <integer> ['-' <integer>]? ] }

    rule tactic { <tactic-category> <tactic-text> }
    rule tactic-category { 'Before' 'Combat' | 'During' 'Combat' | 'Morale' }
    token tactic-text {
        [
            <!before <tactic-category> | <section-heading>>
            \S+ <.ws>
            | <?before <section-heading>> [\w] <:Lowercase>+ <.ws>
        ]+
    }
    token integer { [\d+]+ % ',' }
}

sub MAIN(FileName $raw-file) {
    for RawFile.new(:$raw-file).blocks -> $block {
        given StatBlock.parse($block) -> $/ {
            die "Cannot parse block: \n$block\n" unless $/;
            say "Parsed Stat Block for {$<block><title>}";
        }
    }
}