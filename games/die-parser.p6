#!/usr/bin/env perl6

use v6;

grammar Dice {
    rule TOP {^ <dice> $}
    rule dice { <die-desc>+ % ',' }
    rule die-desc {
        <ndn> | <number>
    }
    rule ndn {
        <prefix=number>? 'd' <faces=number> [
            | <offset>
            | <keep>
            | <reroll>
            | <success> ]*
    }
    rule offset { '+' <number> }
    rule keep { 'keep' $<low> = ['low''est'?]? <number> }
    rule reroll {
        'reroll' $<add> = 'add'? $<target>=('match' <abort>? | <number>)
    }
    rule abort { 'abort' <number> }
    rule success { 'success' 'on'? <number> }
    token ws { \s* }
    token number {
        <[0..9]>+ # No funky unicode numbers
    }
}

sub roll($dice, :$verbose) {
    sub check-options($options) {
        <offset keep reroll abort success>.map(-> $name {
            my $option = $options{$name};
            if not $option {
                ()
            } elsif $option.elems > 1 {
                die "Only one $name allowed";
            } else {
                $name => $option[0];
            }
        }).grep({$_})
    }

    given Dice.parse($dice) -> $/ {
        if not $/ {
            die "Unable to parse '$dice'"
        } else {
            gather for $<dice><die-desc> -> $d {
                if $d<number> {
                    take +$d<number>;
                } else {
                    my $ndn = $d<ndn>;
                    my $prefix = $ndn<prefix> || 1;
                    my $faces = $ndn<faces>;
                    take do-roll(
                        $prefix, $faces,
                        :$verbose,
                        :options(check-options($ndn)));
                }
            }
        }
    }
}

sub do-roll($count, $faces, :@options, :$verbose) {
    my @rolls = (1..$faces).roll($count);
    my $success = Nil;
    for @options -> (:$key, :$value) {
        given $key {
            when 'offset' { @rolls.push(+$value<number>) }
            when 'keep' {
                my $n = $value<number>;
                if $n > @rolls {
                    die "Cannot keep $n of {+@rolls} rolls";
                } elsif $n != @rolls {
                    my $low = ~$value<low> ?? 'low' !! 'high';
                    say "[keep $low $n of {@rolls}]" if $verbose;
                    my @sorted = @rolls.sort;
                    @sorted .= reverse if $low eq 'high';
                    @rolls = @sorted[^$n];
                }
            }
            when 'reroll' {
                my $target = $value<target>;
                my $sum = [+] @rolls;
                my $match = ~$target ~~ /match/ ?? [==] @rolls !! $sum == +$target;
                my $abort = $target<abort> ?? +$target<abort><number> !! False;
                if $match {
                    say "[abort on $sum]" if $abort and $sum == $abort and $verbose;
                    if !$abort or $sum != $abort {
                        say "[reroll on {@rolls}]" if $verbose;
                        my @subroll = do-roll($count, $faces, :@options);
                        if $abort and ([+] @subroll) == $abort {
                            @rolls = @subroll;
                        } elsif $value<add> {
                            @rolls.push: @subroll;
                        } else {
                            @rolls = @subroll;
                        }
                    }
                }
            }
            when 'success' { $success = +$value<number> }
            default { die "Unknown directive '$key'" }
        }
    }
    say "[rolled {@rolls}]" if $verbose;
    if $success {
        @rolls.grep(* >= $success).elems;
    } else {
        [+] @rolls
    }
}

sub MAIN(Str $dice, Bool :$verbose) {
    .say for roll($dice, :$verbose);
}
