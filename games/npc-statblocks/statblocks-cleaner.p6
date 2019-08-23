#!/usr/bin/env perl6

use v6.d;

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
    rule TOP {^ <statblock> $}
    rule statblock {
        :!ratchet :ignorecase
            $<name> = [.*?]
        <cr-xp>
            $<race-class> = [.*?]
        <alignment>
            $<intro> = [.*?]
        'DEFENSE'
            $<defense-stats> = [.*?]
        'OFFENSE'
            $<offense-stats> = [.*?]
        [ 'TACTICS' $<tactics-block> = [.*?] ]?
        'STATISTICS' <abilities>
            [
                $<statistics-stats> = [.*?]
                [ 'ECOLOGY' $<ecology-stats> = [.*?] ]?
                'SPECIAL' 'ABILITIES' $<special> = [.*]
            ||  $<statistics-stats> = [.*]
            ]
    }
    rule cr-xp {
        [ ['CR'||'XP'] <rational> ]+
    }
    token alignment { < L N C > < G N E > | 'N' }
    rule abilities {
        :ignorecase
        [
            [
                $<ability> = < Str Dex Con Int Wis Cha >
                $<value> = [<dash> || <integer>]?
            ]+ % ','
        ]+
    }
    token integer {
          '0'
        | <[1..9]> <[0..9]> ** 0..2 [ ',' <[0..9]> ** 3 ]*
        | <[1..9]> <[0..9]> ** 3..*
    }
    token rational {
          <integer> [ <slash> <integer> ]?
        # Vulgar fraction
        | $<num> = [<:No>] <?{ $<num>.Str.NFKD.grep(0x2044) }>
    }
    token dash { <:Dash_Punctuation> }
    token slash {
        \c[SOLIDUS] || \c[FRACTION SLASH] || \c[DIVISION SLASH] ||
        \c[FULLWIDTH SOLIDUS]
    }
}

sub html-escape($s is copy) {
    for { '&' => 'amp', '<' => 'lt', '>' => 'gt' }.kv -> $c, $name {
        $s .= subst($c, "\&{$name};", :global);
    }
    $s;
}

sub output($match) {
    my $sb = $match<statblock>;
    my %parts = $sb.keys.map: { $_ => html-escape($sb{$_}) };

    my $html = "
        <h1> %parts<name> </h1>
        <p> %parts<cr-xp> </p>
        <p> %parts<race-class> </p>
        <p> %parts<alignment> %parts<intro> </p>
        <h2>DEFENSE</h2>
        <p> %parts<defense-stats> </p>
        <h2>OFFENSE</h2>
        <p> %parts<offense-stats> </p>";
    if %parts<tactics-block> and %parts<tactics-block>.trim {
        my $tb = %parts<tactics-block>;
        $tb .= subst(regex {
            :s :i
            <?after <:Punctuation> | ^>
            $<heading> = (Before Combat | During Combat | Morale)
            }, {" <span class='tactic-heading'> $<heading> </span> "}, :g);
        $html ~= "
            <h2>TACTICS</h2>
            <p> $tb </p>";
    }
    $html ~= "
        <h2>STATISTICS</h2>
        <p>";
    my $ab = $sb<abilities>;
    for $ab<ability> Z=> $ab<value> -> $ability {
        $html ~= "<span class='ability-name'>{$ability.key}</span> ";
        $html ~= "<span class='ability-score'>{$ability.value.trim or '-'}</span> ";
    }
    $html ~= "
        </p>
        <p> %parts<statistics-stats> </p>";
    $html ~= "
        <h2>ECOLOGY</h2>
        <p> %parts<ecology-stats> </p>" if %parts<ecology-stats>;
    $html ~= "
        <h2>SPECIAL ABILITIES</h2>
        <p> %parts<special> </p>" if %parts<special>;

    $html;
}

sub MAIN(FileName $raw-file) {
    for RawFile.new(:$raw-file).blocks -> $block {
        my $match = StatBlock.parse($block);
        die "Cannot parse block: \n$block\n" unless $match;
        put '<html>
            <head><title>NPCs</title>
              <link rel="stylesheet" href="statblock.css" />
            </head<body>';
        put output($match);
        put '</body></html>'
    }
}
