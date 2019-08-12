#!/usr/bin/env perl6
#
# Treasure generator based on the d20 SRD
#
# (c) By Aaron Sherman, 2005, 2019
# Distributed under the Open Gaming License (OGL 1.0a)
# Note that all item and ability names are part of the d20
# system from Wizards of the Coast.
#

use YAML;

=begin pod

The old code...

# Globals used for command-line options
our $cr = 1;
our $verbose = 0;
our $debug = 0;
our $nonstandard = 0;
our $force;
our $save_random = 0;
our $random_seed = undef;
our $count = 1;
our $psionics = 0;
our $large_items = 0;
our $curses = 0;
our $dragon = 0;
our $pathfinder = 0;
our $multiplier = 1;
our $rand_fudge = 0; # when /dev/random is not available, make
		     # sure we don't repeat a seed
our $forceint = 0; # Force intelligence

our %table_map; # Tables loaded from YAML files
our @tablepath = grep {$_} $ENV{MKTREASURE_PATH}, '.', 'd20-treasure';
# Mappings for subroutines that handle special cases
our %specials = (
	coin                 => \&special_coin,
	gems                 => \&special_gems,
	art                  => \&special_art,
	art_name             => \&special_art_name,
	mundane              => \&special_mundane,
	mundane_armor        => \&special_mundane_armor,
	masterwork_weapon    => \&special_masterwork_weapon,
	minor                => \&special_minor,
	medium               => \&special_medium,
	major                => \&special_major,
	magic_armor          => \&special_magic_armor,
	magic_weapon         => \&special_magic_weapon,
	magic_potion         => \&special_magic_potion,
	magic_scroll         => \&special_magic_scroll,
	magic_ring           => \&special_magic_ring,
	magic_rod            => \&special_magic_rod,
	magic_staff          => \&special_magic_staff,
	magic_wand           => \&special_magic_wand,
	wondrous_item        => \&special_wondrous_item,
	psionic_armor        => \&special_psionic_armor,
	psionic_weapon       => \&special_psionic_weapon,
	psionic_cognizance   => \&special_psionic_cognizance,
	psionic_dorje        => \&special_psionic_dorje,
	psionic_power_stone  => \&special_psionic_power_stone,
	psicrown             => \&special_psicrown,
	psionic_tatoo        => \&special_psionic_tatoo,
	psionic_universal_item => \&special_psionic_universal_item,
	knowledge            => \&special_knowledge,
	instrument           => \&special_instrument,
	element              => \&special_element,
	spellworm            => \&special_spellworm,
	book                 => \&special_book,
	two_abilities        => \&special_two_abilities,
	bane                 => \&special_bane,
	spell_storing        => \&special_spell_storing,
	absorption           => \&special_absorption,
	useful_items         => \&special_useful_items,
	efreeti_bottle       => \&special_efreeti_bottle,
	horn_of_valhalla     => \&special_horn_of_valhalla,
	iron_flask           => \&special_iron_flask,
	robe_of_the_archmagi => \&special_robe_of_the_archmagi,
	pearl_of_power       => \&special_pearl_of_power,
	deck_of_illusions    => \&special_deck_of_illusions,
	concatenate          => \&special_concatenate,
	specific_cursed_item => \&special_specific_cursed_item);
# Parse command-line
Getopt::Long::Configure('auto_abbrev','bundling');
GetOptions(
           'h|?|help' => sub {pod2usage(-verbose => 0)},
           'man' => sub {pod2usage(-verbose => 2)},
           'v|verbose' => sub {$verbose = 1},
           'd|debug' => sub {$debug = 1; $verbose = 1},
	   'count=i' => \$count,
	   'c|cr|challenge-rating=i' => \$cr,
	   'n|non-standard' => \$nonstandard,
           'force=s' => \$force,
	   'psionics' => sub { $psionics = 10 }, # Base 10% chance of psi
	   'p|pf|pathfinder' => \$pathfinder,
	   'only-psionics' => sub { $psionics = 100 },
	   'pct-psionics=i' => \$psionics,
	   'l|large-items' => \$large_items,
	   'cursed' => sub { $curses = 5 },
	   'only-cursed' => sub { $curses = 100 },
	   'dragon' => \$dragon,
           'save-random' => \$save_random,
	   'm|multiplier=i' => \$multiplier,
           'random-seed=s' => \$random_seed,
	   'P|table-path=s' => \@tablepath,
	   'I|intelligent' => \$forceint
) or pod2usage(-verbose => 0);

# Simple optimization for the non-verbose case
eval "sub v { }" unless $verbose;
eval "sub dbg { }" unless $debug;

=end pod

class CoinType {
    has $.name;
    has $.abbrev;
    has $.cp-value;
    method gist { $!abbrev }
}
our $gold-piece = CoinType.new(:name<gold>, :abbrev<gp>, :cp-value<100>);
our $silver-piece = CoinType.new(:name<silver>, :abbrev<sp>, cp-value<10>);
our $copper-piece = CoinType.new(:name<copper>, :abbrev<cp>, :cp-value<1>);
our $platinum-piece = CoinType.new(:name<platinum>, :abbrev<pp>, cp-value<1000>);
class Treasure {
    has CoinType @.coin-types =
        $platinum-piece, $gold-piece, $silver-piece, $copper-piece;
    has Int %.coins{CoinType} =
        $gold-piece => 0,
        $silver-piece => 0,
        $copper-piece => 0,
        $platinum-piece => 0;
    has @.items;

    # Generators
    method for-cr(Treasure:U: Int $cr) { ... }

    method add(Treasure:D: Treasure:D $other) {
        my $new = Treasure.new;
        $new.coins.append(self.coins.pairs)
    }
    method value(Treasure:D) { ... }
    method sale-price(Treasure:D) { ... }
}

multi sub infix:<+>(Treasure:D $a, Treasure:D $b) { $a.add($b) }

foreach my $n (1..$count) {
    my($tmp_price, $tmp_sale, $tmp_coins) =
      ($force?force_treasure($force):treasure_for_cr($cr));
    $price += $tmp_price;
    $sale_price += $tmp_sale;
    for(my $i=0;$i<@coins;$i++) {
        $coins[$i] += $tmp_coins->[$i];
    }
    print "----\n" unless $n == $count;
}
if ($count > 1) {
    local $\ = "\n";
    print "====";
    if (grep {$_} @coins) {
        my $i = 0;
        print "Total coins: ", join(" ",map {commas($coins[$i++]).$_} qw(pp gp sp cp));
    }
    $price = int($price*100)/100;
    $sale_price = int($sale_price*100)/100;
    print "Grand total: ",as_gold($price);
    print "Sales grand total: ",as_gold($sale_price);
}
if ($save_random) {
    print "Re-run with '--random-seed $random_seed' for the same result\n";
}
exit(0);

############################################################
# That's it. Everything else is subroutines.
############################################################

# This is the core subroutine for CR-based treasure generation
# Takes just a CR does everything, including print the results.
# Returns the total price, total sale price, and an array ref
# to the four coin values (pp,gp,sp,cp).
sub treasure_for_cr {
    my $cr = shift;
    my $treasure = get_table('treasure-by-cr');
    my $table = $treasure->[$cr-1];
    die "No treasure table entries available for CR $cr\n" unless $table;
    local $\="\n";
    my $sale_price = 0;
    my $price = 0;
    my @coin = (0,0,0,0);
    foreach my $section (@$table) {
        # And this is where the lookup table is actually consulted
	my @items;
	push @items, grep {$_ && %$_} percentile_lookup($section, -1) foreach 1..$multiplier;
	merge_coins(\@items);
	foreach my $item (@items) {
	    if (!defined $item->{price}) {
		die "Commies! Item has no value: ".Dumper($item);
	    }
	    my($name,$p,$s) = printable_name($item);
	    print $name;
	    $price += $p;
	    $sale_price += $s;
            if ($item->{coin}) {
                for(my $i=0;$i<@coin;$i++) {
                    $coin[$i] += $item->{coin}[$i];
                }
            }
	}
    }
    print "Total value: ".as_gold($price);
    print "Resale value: ".as_gold($sale_price) if $sale_price != $price;
    return($price,$sale_price,\@coin);
}

sub merge_coins {
	my $items = shift;
	my @new;
	my @coin = (0,0,0,0);
	foreach my $item (@$items) {
		if ($item->{coin}) {
			for(my $i=0;$i<@coin;$i++) {
				$coin[$i] += $item->{coin}[$i];
			}
		} else {
			push @new, $item;
		}
	}
	push @new, coins_to_data(@coin) if grep { $_ } @coin;
	@$items = @new;
}

# This is the core routine used when generating treasure by type, rather than
# by CR.
# Takes the type as a string of the form:
#   [level-][psionic-]base[xn]
# where "level" is any of minor, medium or major. "psionic" is the literal
# word, "psionic". "base" is the base item type such as coin, ring or
# psicrown. And finally, "n" is a count indicating how many are desired.
# Returns the same value list as treasure_for_cr: price, sale price,
# and array ref of pp,gp,sp,cp amounts. The treasure generated is
# printed.
sub force_treasure {
    my $type = shift;
    my $n = 1;
    $n = $1 if $type =~ s/\s*x\s*(\d+)$//;
    my %levels = ( minor => 0, medium => 1, major => 2);
    my $level = 0;
    $level = $levels{$1} if $type =~ s/^(minor|medium|major)(\s+|-)?//;
    my %generators =
      (
       coin    => [ [
		     [  29,  -1,  -1 ] => sub { dbg("copper"); copper(d6()*1000) },
		     [  52,  24,  -1 ] => sub { dbg("silver"); silver(($_[0]?d10(2)*1000:d8()*100)) },
		     [  95,  79,  65 ] => sub { dbg("gold"); gold(($_[0]?($_[0]==1?d4(6)*100 : d8(3)*1000) : d8(2)*10)) },
		     [ 100, 100, 100 ] => sub { dbg("plat"); plat(($_[0]?($_[0]==1?d6(5)*10  : d10(3)*100) : d4()*10))  } ] ],
       art     => sub { (art(1))[0] },
       gem     => sub { (gems(1))[0] },
       mundane => sub { (mundane(1))[0] },
       armor   => \&magic_armor,
       weapon  => \&magic_weapon,
       potion  => \&magic_potion,
       ring    => \&magic_ring,
       rod     => \&magic_rod,
       scroll  => \&magic_scroll,
       staff   => \&magic_staff,
       wand    => \&magic_wand,
       wonder  => \&wondrous_item
       );
    if ($psionics) {
	my %psi_generators =
	    (
	     armor         => \&psionic_armor,
	     weapon        => \&psionic_weapon,
	     cognizance    => \&psionic_cognizance,
	     dorje         => \&psionic_dorje,
	     'power-stone' => \&psionic_power_stone,
	     psicrown      => \&psicrown,
	     tatoo         => \&psionic_tatoo,
	     universal     => \&psionic_universal_item
	     );
	@generators{keys %psi_generators} = values %psi_generators;
    }
    if ($dragon) {
	$generators{Dragon} = \&dragon_item;
    }
    if ($type eq 'item' or exists $generators{$type}) {
        local $\="\n";
        my $price = 0;
        my $sale = 0;
        for(my $i=0;$i<$n;$i++) {
            my $item;
	    if ($type eq 'coin') {
		$item = percentile_lookup($generators{$type},$level);
	    } else {
		my $tmptype = $type;
		if ($type eq 'item') {
		    my @types = grep { $_ ne 'coin' &&
				       $_ ne 'art' &&
				       $_ ne 'gem' &&
				       $_ ne 'mundane' } keys %generators;
		    if ($level == 0) {
			# These item types don't come in "minor"
			@types = grep {$_ ne 'staff' &&
				       $_ ne 'rod'   &&
				       $_ ne 'psicrown'} @types;
		    }
		    if ($forceint) {
			@types = grep { $_ ne 'staff' &&
					$_ ne 'wand' &&
					$_ ne 'potion' &&
					$_ ne 'scroll' &&
					$_ ne 'dorje' &&
					$_ ne 'power-stone' &&
					$_ ne 'tatoo' } @types;
		    }
		    if ($psionics == 100) {
			@types = grep { $_ =~ /armor|weapon|cognizance|dorje|
					       power-stone|psicrown|tatoo|
					       universal/x } @types;
		    }
		    $tmptype = $types[int mktrand(@types)];
		}
		if ($dragon && $tmptype ne 'Dragon' && mktrand(100) >= 99) {
		    $item = $generators{Dragon}->($level,$tmptype);
		}
                $item or $item = $generators{$tmptype}->($level);
            }
            my ($n,$p,$s) = printable_name($item);
            print $n;
            $price += $p;
            $sale += $s;
        }
        return($price,$sale,[0,0,0,0]);
    } else {
        die "Unknown treasure type: '$type'\n";
    }
}

# A helper used by treasure_for_cr and force_treasure
sub printable_name {
    my $item = shift;
    my $price = $item->{price};
    my $sale_price = $price;
    # Only coins gems and art can be sold for full-price.
    # This is based on the SRD, and the assumption that
    # there is no other reason to list a price for items
    # such as gems and art other than to know what they
    # sell for, so these are assumed not to be retail
    # prices. "Trade goods" are also full price, but
    # there are no such goods in the random treasure
    # tables (like wheat or silk).
    # See also:
    # http://boards1.wizards.com/showthread.php?t=694322
    my $type = $item->{type};
    unless ($type eq 'coin' || $type eq 'gem' || $type eq 'art') {
	$sale_price /= 2;
    }
    my $name = $item->{name};
    if ($type eq 'art' || $type eq 'gem' || $type eq 'mundane') { 
	$name = "$type: $name";
	if ($item->{subtype}) {
	    $name = "$item->{subtype}, $name";
	}
    }
    my $strprice = as_gold($price) .
	(($type eq 'coin' || $name =~ /\n/) ?" value":"");
    $name .= " ($strprice)";
    return($name,$price,$sale_price);
}

sub copper { dbg("$_[0] cp"); coin($_[0]/100, 3) }
sub silver { dbg("$_[0] sp"); coin($_[0]/10, 2) }
sub gold   { dbg("$_[0] gp"); coin($_[0], 1) }
sub plat   { dbg("$_[0] pp"); coin($_[0]*10, 0) }

#### From here on we start returning "treasure items". These are a common
#### datastructure format, represented as a hash ref with the following
#### fields:
####   name - A textual name (does not include pricing)
####   type - A string type name such as "coin" or "weapon"
####   subtype - Optional sub-type name
####   coin - Array ref to the number of pp,gp,sp,cp contained

# Given a number (possibly fractional) of gold pieces, come up with a
# coin "item" that's equal to that many gold (+/-10%). Number of each
# coin type will be decided based on the strategies cited below.
sub coin {
    my $count = shift;
    my $focus = shift;
    # 50% of the time, add or subtract a random amount up to 10%
    # This avoids always having round numbers
    if (d2() == 1) {
	$count *= 1 + (mktrand(1)/5-1/10);
	$count = int($count*100)/100;
	dbg("Modified to ".as_gold($count)) if $verbose;
    }
    # Strategies:
    # 1. gp/sp/cp in minimum number of coins
    # 2. SRD style (just one coin type)
    # 3. random distribution
    my $strategy = d6();
    my($pp,$gp,$sp,$cp) = (0,0,0,0);
    if ($strategy == 1) {
	dbg("Strategy 1: as gold");
	# Try to minimized number of coins, but without plat
        $gp = int($count);
        $sp = int(($count-$gp)*10);
        $cp = int(($count-($gp+$sp/10))*100 + 0.5);
    } elsif ($strategy <= 4) {
	dbg("Strategy 2: SRD");
	# Like the SRD, but round since we might be +/- 10%
        if ($focus == 0) {
            $pp = int($count/10 + 0.5);
        } elsif ($focus == 1) {
            $gp = int($count + 0.5);
        } elsif ($focus == 2) {
            $sp = int($count*10 + 0.5);
        } elsif ($focus == 3) {
            $cp = int($count*100 + 0.5);
        }
    } else {
	dbg("Strategy 3: distribution");
        $pp = int($count/10);
        $gp = int($count-$pp*10);
        $sp = int((($count-$pp*10)-$gp)*10);
        $cp = int(((($count-$pp*10)-$gp)*10-$sp)*10 + 0.5);
	# Let's say we have 200pp. We subtract 0-99 of them and
	# add that to gold. Let's say that was 50pp (now 500gp).
	# We subtract 0-99gp and add them to silver. Let's
	# say that was 40gp (now 400sp). We continue in this
	# way, trying to even out the amounts between pp, gp,
	# sp and cp.
	# We determine how many to subtract from each by
	# rounding the current amount down to the nearest
	# power of 10 and then choosing a random number between
	# 0 and one less than that power of 10. So, for 10-99,
	# we subtract 0-9 coins. For 100-999, we subtract
	# 0-99 coins, and so on. This gives us a fairly even
	# mix of coins, with plenty of randomness.
        if ($pp) {
            my $n = ($pp>9?
		     int mktrand 10**(int(log($pp)/log(10))) :
		     d($pp,1));
            $pp -= $n;
            $gp += $n * 10;
        }
        if ($gp) {
            my $n = ($gp>9?
		     int mktrand 10**(int(log($gp)/log(10))) :
		     d($gp,1));
            $gp -= $n;
            $sp += $n * 10;
        }
        if ($sp) {
            my $n = ($sp>9?
		     int mktrand 10**(int(log($sp)/log(10))) :
		     d($sp,1));
            $sp -= $n;
            $cp += $n * 10;
        }
    }
    return coins_to_data($pp,$gp,$sp,$cp);
}

sub coins_to_data {
	my($pp,$gp,$sp,$cp) = @_;
	return
	   { name => sprintf("coin: %spp %sgp %ssp %scp",
			     map {commas($_)} $pp, $gp, $sp, $cp),
             coin => [ $pp, $gp, $sp, $cp ],
	     price => $pp*10+$gp+$sp/10+$cp/100,
	     type => 'coin' };
}

# Given a count, generate and return that may gem items
sub gems {
    my $count = shift;
    my $gem_names = get_table('gem-names');
    if ($nonstandard) {
	my $gem_names = dclone($gem_names);
	push @{$gem_names->[3]}, 'pale blue topaz';
	for(my $i = 1;$i<@$gem_names;$i++) {
	    push @{$gem_names->[$i]}, map {"large $_"} @{$gem_names->[$i-1]};
	    push @{$gem_names->[$i-1]}, map {"small $_"} @{$gem_names->[$i]};
	}
    }
    my @gems = ( 25 => sub { gem_value(d4(4), $gem_names->[0]) },
	      50 => sub { gem_value(d4(2)*10, $gem_names->[1]) },
	      70 => sub { gem_value(d4(4)*10, $gem_names->[2]) },
	      90 => sub { gem_value(d4(2)*100, $gem_names->[3]) },
	      99 => sub { gem_value(d4(2)*1000, $gem_names->[4]) },
	      100 => sub { gem_value(d4(2)*1000, $gem_names->[5]) }
	      );
    return map {percentile_lookup(\@gems,-1)} 1..$count;
}

# Used by gems. Gim a gp value and a list of names, choose
# a name and construct the gem item
sub gem_value {
    my $gp = shift;
    my $names = shift;
    my $name = $names->[int mktrand @$names];
    return { name => "$name", price => $gp, type => 'gem' };
}

sub art {
    my $count = shift;
    my $art_items = get_table('art');
    return map {percentile_lookup($art_items,-1)} 1..$count;
}

# Helper used by art. Takes a gp value and list of names.
# Chooses a name and returns the appropriate art item.
sub art_value {
    my $gp = shift;
    my $names = shift;
    my $name = $names->[int mktrand @$names];
    return { name => $name, price => $gp, type => 'art' };
}

# Given a count, generate and return that many mundane items
sub mundane {
    my $count = shift;
    my $mundane = get_table('mundane-treasure');
    my @items;
    foreach my $n (1..$count) {
	push @items, map {mundane_fix({%$_, type => 'mundane'})} percentile_lookup($mundane,-1);
    }
    return @items;
}

# Parse the count field and roll dice
sub mundane_fix {
    my $item = shift;
    if ($item->{count}) {
	my $count = parse_die($item->{count});
	$item = { %$item, name => "$item->{name} ($count)",
		  price => $item->{price} * $count };
    }
    return $item;
}

# Takes no parameters and returns an item structure for a masterwork (but
# otherwise mundane) weapon.
sub mwk_weapon {
    my $size = rollsize();
    my $type = item_weapon_type();
    return { name => "$size masterwork $type->{name}", type => 'weapon', subtype => $type->{type},
	     price => $type->{price} };
}

# minor, medium and major are just front-ends to magic
sub minor { magic(0,@_) }
sub medium { magic(1,@_) }
sub major { magic(2,@_) }

# Take a "level" (a convention used often from here on, 0=minor, 1=medium
# and 2=major; we use numbers because they index the lookup tables),
# and a count. Return that many "magic items". Magic can include psioncs
# when $psionics is set, and otherwise includes the full spread of potions,
# scrolls, weapons, armor, etc.
sub magic {
    my $level = shift;
    my $count = shift;
    my @items;
    foreach (1..$count) {
	push @items, random_item($level);
    }
    return @items;
}

# Takes a level and returns a (usually) single random magic item.
# This is where the basic random magic item table from the SRD
# lives. We have a variant here when psionics are desired. Then,
sub random_item {
    my $level = shift;
    my $item_table = get_table('item-type');
    if ($psionics) {
	my $psi = $psionics;
        # 10% chance of psioncs, otherwise magic.
        $item_table =
          [ [ [$psi,$psi,$psi ] => sub { psionic_item($level) },
              [ 100, 100, 100 ] => [ @$item_table ] ]
          ];
    }
    if ($dragon) {
	$item_table =
	  [ [ [   1,   1,   1 ] => sub { dragon_item($level) },
	      [ 100, 100, 100 ] => [ @$item_table ] ]
	    ];
    }
    percentile_lookup($item_table,$level);
}

#NOTE: Items that follow are from Dragon Magazine, and are NOT
# OGL content. Their names and issue references are listed only,
# in the hopes that this does not constitute a violation
# of the OGL.
sub dragon_item {
    my $level = shift;
    my $type = shift;
    my $dragon_items = get_table('dragon-items');
    if ($curses) {
	my $cursed = get_table('dragon-items-cursed');
	$dragon_items = [ @$dragon_items,  map {{%$_, name => "CURSED: ".$_->{name}}} @$cursed ];
    }
    if ($type) {
            $dragon_items = [grep { $_->{type} eq $type } @$dragon_items];
    }
    # Determine the roll required for each item dynamically
    my $low = 8000; # Minor items cost less than this
    my $high = 30000; # Major items cost this or higher
    my $range = 15; # % overlap between price ranges
    my $topmod = ((100+$range)/100);
    my $botmod = ((100-$range)/100);
    my @odds;
    for(my $i=0;$i<@$dragon_items;$i++) {
	my $item = $dragon_items->[$i];
	my $price = $item->{price};
	if ($price < $low*$topmod) {
	    push @{$odds[0]}, $item;
	}
	if ($price > $low*$botmod && $price < $high*$topmod) {
	    push @{$odds[1]}, $item;
	}
	if ($price > $high*$botmod) {
	    push @{$odds[2]}, $item;
	}
    }
    my @dragon_items = ();
    for(my $i=0;$i<3;$i++) {
	my $items = $odds[$i] || [];
	my $count = @$items;
	my @slots = (-1,-1,-1);
	for(my $n=0;$n<$count;$n++) {
	    my $roll = int(($n+1)/$count*100+0.5);
	    $slots[$i] = $roll;
	    die "Bad entry in dragon_treasure" unless $items->[$n]{name};
	    push @dragon_items, [ @slots ] => $items->[$n];
	}
    }
    @dragon_items = ( [ @dragon_items ] );

    my $item = percentile_lookup(\@dragon_items, $level);
    return $item unless $item;
    my $name = $item->{name};
    my $price = $item->{price};
    if ($name eq 'sling boulder') {
    	my $n = d4(2);
    	$name .= " ($n stones)";
	$price *= $n;
    }
    my $itype = $item->{type};
    if ($itype eq 'weapon' || $itype eq 'shield' || $itype eq 'armor') {
	my $size = rollsize();
	$name = "$size $name";
    }
    my $issue = $item->{issue};
    $name = "$name (Dragon issue \#$issue)";
    $item = roll_intelligence({ %$item, name => $name, price => $price });
    my $pnc = price_and_charges($item);
    return $pnc;
}

# This is the psionics lookup table
sub psionic_item {
    my $level = shift;
    my $item_table = get_table('psionic-item-type');
    return percentile_lookup($item_table,$level);
}

# Psionic weapons and armor are generated by the magic weapons and armor
# routines, but with the $psi parameter set to 1
sub psionic_armor {
    my $level = shift;
    return magic_armor($level,1);
}

sub psionic_weapon {
    my $level = shift;
    return magic_weapon($level,1);
}

# A cognizance crystal just holds power-points. Nothing special.
sub psionic_cognizance {
    my $level = shift;
    my $crystals = get_table('psionic-cognizance-crystals');
    my $crystal = percentile_lookup($crystals, $level);
    my $s = 's';
    $s = '' if $crystal->{points} == 1;
    my $name = "cognizance crystal ($crystal->{points} point$s)";
    return { %$crystal, type => 'cognizance crystal', name => $name };
}

# A dorje is essentially a psionic wand
sub psionic_dorje {
    my $level = shift;
    my $dorjes = get_table('psionic-dorje');
    my $dorje = percentile_lookup($dorjes,$level);
    my $name = psionic_power_name($dorje->{level});
    my $level_name = nth($dorje->{level});
    $name = "dorje: $name ($level_name level)";
    my $pnc = price_and_charges({ %$dorje, charges => 50, name => $name });
    return { %$pnc, type => 'dorje' };
}

# A power ston is the psionic equivalent of a scroll
sub psionic_power_stone {
    my $level = shift;
    my $type = percentile_lookup(get_table('psionic-power-type'),-1);
    my $count = ($level == 0?d3():($level == 1?d4():d6()));
    my $powers = get_table('psionic-power-stone');
    my @names;
    my $price = 0;
    foreach my $n (1..$count) {
	my $power = percentile_lookup($powers,$level);
	if ($power->{level} > 6 && $type eq 'psychic warrior') {
	    redo;
	}
        my $name = psionic_power_name($power->{level},$type);
	push @names, sprintf "%d. %s (%s level) (%s)", $n, $name, nth($power->{level}), as_gold($power->{price});
	$price += $power->{price};
    }
    return { name => "power stone ($type):\n\t".join("\n\t",@names), type => 'power stone', price => $price };
}

# dorjes, power stones and a few other things have a level and perhaps a
# manifester type, but no names. This routine takes the level and
# optional manifester type and returns an appropriate psionic power
# name. Valid manifester types are "psion/wilder" and "psychic warrior"
# No powers are returned that are specific to a psionic discipline
# such as nomad or shaper.
sub psionic_power_name {
    my $level = shift;
    my $type = shift;
    $type = percentile_lookup(get_table('psionic-power-type'),-1) unless $type;
    $type = 'psion/wilder' if $level > 6;
    my $powers = get_table('psionic-power-names');
    my $plist = $powers->{$type}[$level-1];
    return $plist->[int mktrand @$plist];
}

# Psicrowns are similar to staves or rods
sub psicrown {
    my $level = shift;
    die "There are no 'minor' psicrowns" unless $level;
    my $crowns = get_table('psicrown');
    my $crown = percentile_lookup($crowns,$level);
    my $crownlevel = $crown->{points}/50;
    my $name = "psicrown: $crown->{name}";
    my $pnc = price_and_charges({ %$crown, level => $crownlevel, name => $name });
    return { %$pnc, type => 'psicrown' };
}

# Presumably psionic tatoos found as "treasure" are on a fallen opponent, and
# likely used during battle, though if not, they can be transfered as a
# standard action.
sub psionic_tatoo {
    my $level = shift;
    my $tatoos = get_table('psionic-tatoo');
    my $tatoo = percentile_lookup($tatoos,$level);
    my $name = psionic_power_name($tatoo->{level});
    my $tlevel = nth($tatoo->{level});
    return { %$tatoo, name => "psionic tatoo: $name ($tlevel level)", type => 'psionic tatoo' };
}

# Like wondrous items, but psionic
sub psionic_universal_item {
    my $level = shift;
    my $items = get_table('psionic-universal');
    my $item = percentile_lookup($items->[$level],-1);
    my $name = $item->{name};
    my $plus = undef;
    $plus = $1 if $name !~ /^shard\b/ && $name =~ /\+(\d+)/;
    $item = roll_intelligence({ %$item, name => "psionic universal item: $name",
    				type => 'psionic universal', plus => $plus });
    $item = cursed_item($item,1) if $curses;
    return $item;
}

# Magic weapons can get quite complex. They always have an enhancement
# bonus and a weapon type. Then they can also have special abilities,
# special materials, intelligence, and curses. There is a chance that
# any random magic weapon might be a "specific weapon", in which case
# the generated type is thrown out and the specific weapon is returned.
sub magic_weapon {
    my $level = shift;
    my $psi = shift;
    my $size = rollsize();
    my $type = item_weapon_type();
    my @name = $size;
    push @name, "glowing" if percentile_lookup([30=>1,100=>0],-1);
    my $price = $type->{price};
    my $plus = 0; # Save number of pluses for ego of int weaps
    my $heads = ($type->{heads}?$type->{heads}:1);
    my $align = [];
    # Bonuses for each head
    for(my $head=1;$head <= $heads;$head++) {
	my $h = magic_weapon_head($level,$size,$type,$head,$psi,$align);
	# First head might override with specific weap
	return $h->{override} if $h->{override};
	push @name, "head $head:(" if $heads > 1;
	push @name, $h->{name};
	push @name, ")" if $heads > 1;
	$price += $h->{price};
	$plus += $h->{plus};
    }

    my $name = $type->{name};
    if ($type->{count}) {
	my $scale = mktrand(1);
	my $count = int($type->{count} * $scale)+1;
	$scale = $count/$type->{count};
	$price *= $scale;
	$name .= " ($count)";
    }
    my $weapon = roll_intelligence({%$type,name=>$name,plus=>$plus,price=>$price,type=>'weapon',
				    align => $align, subtype=>$type->{type}});
    push @name, $name;
    push @name, $weapon->{intdesc}."\n\t" if $weapon->{intelligent};
    if ($type->{frequency}) {
	$weapon->{subtype} .= ', '.$type->{frequency};
    }
    $weapon->{name} = join " ", @name;
    $weapon = cursed_item($weapon,$psi) if $curses;
    return $weapon;
}

# Each head of a magic weapon is enchanted separately. I've toyed with
# the idea of making 2-headed weapons always have related abilities, but
# that's not how it works in the SRD.
sub magic_weapon_head {
    my $level = shift;
    my $size = shift;
    my $type = shift;
    my $head = shift;
    my $psi = shift;
    my $align = shift;
    my $bonus_table = get_table('magic-weapon');
    my @attributes;
    while(my $bonus = percentile_lookup($bonus_table,$level)) {
	if ($bonus eq 'specific') {
	    dbg("Specific weapon");
	    if ($head > 1) {
		next;
	    } else {
		return { override => specific_weapon($level,$size,$psi) };
	    }
	}
	if ($bonus eq 'special') {
	    #dbg("Weapn special ability");
	    push @attributes, weapon_special_ability($level,$type,$psi);
	} else {
	    #dbg("Bonus: $bonus");
	    push @attributes, $bonus;
	    last;
	}
    }
    my $plus = pop @attributes;
    my $costs = get_table('weapon-plus-costs');
    my $cost_cash = 0;
    my $cost_plus = $plus;
    my %done_name;
    my %done_unique;
    my @anames;
    foreach my $attr (sort {$a->{name} cmp $b->{name}} @attributes) {
	next if $done_name{$attr->{name}}++;
	if ($attr->{upgrade}) {
	    @anames = grep {$_ ne $attr->{upgrade}} @anames;
	} 
	if ($attr->{align}) {
	    if (($attr->{align} eq 'chaotic' && (grep {$_ eq 'lawful'}  @$align)) ||
		($attr->{align} eq 'lawful'  && (grep {$_ eq 'chaotic'} @$align)) ||
	        ($attr->{align} eq 'good'    && (grep {$_ eq 'evil'}    @$align)) ||
		($attr->{align} eq 'evil'    && (grep {$_ eq 'good'}    @$align))) {
		$attr = weapon_special_ability($level,$type,$psi);
		redo;
	    } else {
		push @$align, $attr->{align};
	    }
	}
	if (($attr->{type} && $attr->{type} ne $type->{type}) ||
	    ($attr->{unique} && $done_unique{$attr->{unique}}++) ||
	    ($attr->{excludes} && (grep {$_ eq $attr->{excludes}} @anames))) {
	    $attr = weapon_special_ability($level,$type,$psi);
	    redo;
	}
	
	if ($attr->{plus}) {
	    $cost_plus += $attr->{plus};
	}
	if ($attr->{price}) {
	    $cost_cash += $attr->{price};
	}
	push @anames, $attr->{name};
    }
    my @name;
    push @name, "[".join(", ", @anames)."]" if @anames;
    if ($cost_plus > 10) {
	return magic_weapon_head($level,$size,$type,$head,$psi);
    }
    push @name, "+$plus";
    my $weaptype = $type->{type};
    my $wood = $type->{wood};
    my $metal = (exists($type->{metal})?$type->{metal}:!$wood);
    if ($metal and my $material = percentile_lookup(get_table('special-metal-material'),-1)) {
	my $cost = item_material_cost($material,$type);
	if (defined $cost) {
	    push @name, $material;
	    $cost_cash += $cost;
	}
    }
    if ($wood and my $material = percentile_lookup(get_table('special-wood-material'),-1)) {
	my $cost = item_material_cost($material,$type);
	if (defined $cost) {
	    push @name, $material;
	    $cost_cash+=$cost;
	}
    }
    my $price = $cost_cash+$costs->[$cost_plus];
    return { name => join(" ",@name), price => $price,
	     plus => $cost_plus };
}

# Given a special material name and an item, return the cost of making
# that item out of that material.
sub item_material_cost {
    my $material = shift;
    my $item = shift;
    my $type = $item->{type};
    my $count = $item->{count} || 1;
    if ($material eq 'adamantine') {
	if ($type eq 'ammo') {
	    return 60;
	} else {
	    return 3_000;
	}
    } elsif ($material eq 'darkwood') {
	return 10*$item->{weight};
    } elsif ($material eq 'dragonhide') {
	return $item->{price}; # XXX I think this is wrong, but see dmg p. 284
	# Question posted to http://boards1.wizards.com/showthread.php?t=547319
        # Followup... seems it's correct. Sigh.
    } elsif ($material eq 'cold iron') {
	return $item->{price}; # See above. For cold iron, this probably makes sense, though.
    } elsif ($material eq 'mithral') {
	my $type = $item->{type};
	if ($type eq 'light') {
	    return 1000;
	} elsif ($type eq 'medium') {
	    return 4000;
	} elsif ($type eq 'heavy') {
	    return 9000;
	} elsif ($type eq 'shield') {
	    return 1000;
	} else {
	    return $item->{weight}*500;
	}
    } elsif ($material eq 'alchemical silver') {
	if ($item->{count}) {
	    return 2*$item->{count};
	} elsif ($item->{heads} && $item->{heads}>1) {
	    return 90;
	} else {
	    # This is NOT what the SRD or DMG say, but screw 'em I'm
	    # sick of these funky rules for each material
	    # This multiplier for weight gets very close to the
	    # values listed in dmg p. 285, but avoids having to
	    # look at weapons a 4th way to assess special material
	    # cost.
	    return $item->{weight} * 14;
	}
    }
}

# Takes an item hash and returns a new item hash which will be modified
# if intelligence was rolled. The name will be modified, and the
# descriptive text added to it will also be in "intdesc". Also, the
# "intelligent" value will be set to true.
sub roll_intelligence {
    my $item = shift;
    my $plus = $item->{plus};
    my $name = $item->{name};
    my $price = $item->{price};
    if (! $item->{charges} && ! $item->{points} && $item->{type} ne 'potion' &&
    	  $item->{type} ne 'scroll' && $item->{type} ne 'tatoo' &&
	  (!$item->{subtype} || $item->{subtype} ne 'ammo') && !$item->{dumb}) {
	# Generate all intelligent items based on "pluses", but for items
	# that don't have plusses, fake it based on price
    	unless ($plus) {
	    if ($name =~ /\+(\d+)/) {
		$plus = $1;
	    } elsif ($item->{price} >= 100_000) {
		$plus = 5;
	    } elsif ($item->{price} >= 50_000) {
		$plus = 4;
	    } elsif ($item->{price} >= 30_000) {
		$plus = 3;
	    } elsif ($item->{price} >= 15_000) {
		$plus = 2;
	    } else {
		$plus = 1;
	    }
	}
        # Intelligence
        if ($forceint || percentile_lookup([99=>0,100=>1],-1)) {
	    my @name = $name;
	    my $int = intelligent_item($plus,$item->{align});
	    $price += $int->{price};
	    my $intdesc = "(intelligent:\n\t\t".join("\n\t\t",@{$int->{details}}).")";
	    $name = join ' ', @name, $intdesc;
    	    return { %$item, name => $name, intdesc => $intdesc,
		     price => $price, intelligent => 1 };
        } else {
    	    return $item;
    	}
    } else {
        return $item;
    }
}

# Takes an enhancement bonus and returns an intelligence structure (hash ref)
# which contains the fields: "details" (array of strings), and "price"
# (which is the additional price for the intelligence).
sub intelligent_item {
    my $plus = shift;
    my $align = shift;
    $align = [] unless $align;
    # Intelligent
    my $alignments = get_table('int-alignment');
    my $alignment;
    ALIGN_CHECK: while(1) {
	$alignment = percentile_lookup($alignments,-1);
	foreach my $a (@$align) {
	    if (($a eq 'lawful'  && $alignment =~ /chaotic/) ||
		($a eq 'chaotic' && $alignment =~ /lawful/ ) ||
	        ($a eq 'good'    && $alignment =~ /evil/   ) ||
		($a eq 'evil'    && $alignment =~ /good/   )) {
		redo ALIGN_CHECK;
	    }
	}
	last;
    }
    my $abilities_table = get_table('int-abilities');
    my $abilities = percentile_lookup($abilities_table,-1);
    my $price = $abilities->{price};
    if ($abilities->{greater_power} &&
	percentile_lookup([50=>1,100=>0],-1)) {
	my $purposes = get_table('int-purposes');
	$abilities->{purpose} = percentile_lookup($purposes,-1);
	$abilities->{greater_power}--;
	my $dedicated = get_table('int-dedicated');
	my $ded = percentile_lookup($dedicated,-1);
	$abilities->{dedicated_power} = $ded->{name};
	$price += $ded->{price};
    }
    my $lesser = get_table('int-lesser');
    my $greater = get_table('int-greater');
    my($int,$wis,$cha) = shuffle(10,(($abilities->{ability}) x 2));
    my $ego = $plus + ($int-10)/2 + ($wis-10)/2 + ($cha-10)/2 +
	$abilities->{lesser_power} + $abilities->{greater_power}*2 +
	($abilities->{dedicated_power}?4:0) +
	(($abilities->{communication}=~/telepathy/)?1:0) +
	(($abilities->{communication}=~/read/)?1:0) +
	(($abilities->{communication}=~/read magic/)?1:0);
    $ego = int($ego);
    my @powers;
    for(my $i=0;$i<$abilities->{lesser_power};$i++) {
	push @powers, percentile_lookup($lesser,-1);
	$price += $powers[-1]{price};
    }
    for(my $i=0;$i<$abilities->{greater_power};$i++) {
	push @powers, percentile_lookup($greater,-1);
	$price += $powers[-1]{price};
    }
    return { details =>
		 [ "int: $int, wis: $wis, cha: $cha, ego: $ego",
		   "Alignment: $alignment",
		   "Communication: $abilities->{communication}",
		   "Powers:", (map {"  $_->{name}"} @powers),
		   ($abilities->{purpose}?("Purpose: $abilities->{purpose}",
					   "Dedicated power: $abilities->{dedicated_power}"):
		    ()) ],
		 price => $price };
		 
}

# Given a level, weapon type (subtype of the final item) and optional
# psinic boolean, return an ability structure containing "name",
# one of "plus" or "price" indicating the cost, and the optional fields:
# "excludes" (array, indicates what abilities cannot go with this ability),
# "type" (string, indicates what weapon type can have this ability),
# and unique (string, no other ability with this uniqueness string can
# be generated for this item).
# Bug: should handle type exclusions here, or not require the type param
sub weapon_special_ability {
    my $level = shift;
    my $type = shift;
    my $psi = shift;
    my @abilities;
    if ($psi) {
	if ($type->{type} eq 'ranged') {
	    @abilities = psi_ranged_weapon_special_ability($level,$type);
	} else {
	    @abilities = psi_weapon_special_ability($level,$type);
	}
    } else {
	my $abilities = get_table('weapon-special');
	@abilities = percentile_lookup($abilities, $level, \&weapon_special_ability, $type, $psi);
    }
    if (wantarray) {
	return @abilities;
    } else {
	return shift @abilities;
    }
}

# Psionic item special abilities are keyed to ranged vs. melee weapons,
# but this is otherwise identical in behavior to weapon_special_ability.
sub psi_ranged_weapon_special_ability {
    my $level = shift;
    my $type = shift;
    my $abilities = get_table('psionic-ranged-weapon-special');
    return percentile_lookup($abilities, $level, \&psi_ranged_weapon_special_ability, $type, 1);
}

sub psi_weapon_special_ability {
    my $level = shift;
    my $type = shift;
    my $abilities = get_table('psionic-weapon-special');
    return percentile_lookup($abilities,$level, \&psi_weapon_special_ability, $type, 1);
}

# Specific magic weapon type. Takes level, size and optional psi parameter.
# Returns the completed magic weapon item structure.
# Bug: The SRD provides no psionic specific weapons, which kind of sucks.
# For now, we just return a specific magic weapon in that case, but in
# future, we should find or write up some OGL psionic weapons.
sub specific_weapon {
    my $level = shift;
    my $size = shift;
    my $psi = shift; # There are no specific psi weapons, but cursed_item needs this
    my $weapons = get_table('specific-weapons');
    my $weap = percentile_lookup($weapons, $level);
    my $name = $weap->{name};
    $weap = roll_intelligence({ %$weap, type => 'weapon', subtype => 'specific', dumb => !$weap->{plus} });
    $weap->{name} = join(" ", $size, ($weap->{intelligent}?$weap->{intdesc}."\n\t":()), $name);
    $weap = cursed_item($weap,$psi) if $curses;
    return $weap;
}

# Return a weapon item structure with "name", "price", "weight" (lbs.), "type",
# and optional "frequency" and "count" fields. "type" will eventually be the
# "subtype" of the final item. "frequency" is just a string indicating
# common vs uncommon melee. "count" is an item count for ammo subtypes.
sub item_weapon_type {
    my $weapons = get_table('weapon-types');
    return percentile_lookup($weapons,-1);
}

# Takes a level and optional psi boolean. Returns a magic armor structure.
# The final item can be made of a special material, and might be intelligent
# or cursed. All magic armor has an enhancement bonus.
sub magic_armor {
    my $level = shift;
    my $psi = shift;
    my $size = rollsize();
    my $armors = get_table('magic-armor');
    my @attributes;
    # Most of the complexity below is because the SRD sucks when
    # it comes to magic armor. There is a table that determines
    # what bonuses armor gets AND what type of armor (shield or
    # body armor) it is. Sadly, some bonus abilities need to know
    # what type of armor they are applying to, and must be re-
    # rolled if they don't fit. Plus, psionic armor has completely
    # different sub-tables for special abilityes for shields vs.
    # armor. So, there's a bootstrapping problem. We delay work
    # as long as possible and repeat some work when it later becomes
    # obvious that we need to.
    while(my @bonuses = percentile_lookup($armors,$level)) {
	if (@bonuses > 1) {
	    push @attributes, map {
		armor_special_ability($level);
	    } @bonuses;
	    next;
	}
	my $bonus = shift @bonuses;
	if (ref($bonus) && ref($bonus) eq 'HASH') {
	    push @attributes, $bonus;
	    last;
	} elsif ($bonus eq 'specific armor') {
	    return specific_armor($level,$size);
	} elsif ($bonus eq 'specific shield') {
	    return specific_shield($level,$size);
	} elsif ($bonus eq 'special ability') {
	    push @attributes, armor_special_ability($level);
	}
    }
    my $plus = pop @attributes;
    my $type = $plus->{type};
    $plus = $plus->{plus};
    my $base = item_armor_type($type);
    if ($psi) {
	my @tmpattr;
	if ($type eq 'armor') {
	    push @tmpattr, psionic_armor_special_ability($level) foreach @attributes;
	} else {
	    push @tmpattr, psionic_shield_special_ability($level) foreach @attributes;
	}
	@attributes = @tmpattr;
    }
    my $costs = get_table('armor-plus-costs');
    my $cost_cash = $base->{price};
    my $cost_plus = $plus;
    my @name = $size;
    my %done_name;
    my %done_unique;
    my @anames;
    my $align=[];
    my $special = sub {
	my($type,$level) = @_;
	if ($psi) {
	    if ($type eq 'armor') {
		psionic_armor_special_ability($level);
	    } else {
		psionic_shield_special_ability($level);
	    }
	} else {
	    armor_special_ability($level);
	}
    };
    foreach my $attr (sort {$a->{name} cmp $b->{name}} @attributes) {
	next if $done_name{$attr->{name}}++;
	if ($attr->{upgrade}) {
	    @anames = grep {$_ ne $attr->{upgrade}} @anames;
	} 
	if ($attr->{align}) {
	    if (($attr->{align} eq 'chaotic' && (grep {$_ eq 'lawful'}  @$align)) ||
		($attr->{align} eq 'lawful'  && (grep {$_ eq 'chaotic'} @$align)) ||
	        ($attr->{align} eq 'good'    && (grep {$_ eq 'evil'}    @$align)) ||
		($attr->{align} eq 'evil'    && (grep {$_ eq 'good'}    @$align))) {
		$attr = $special->($type,$level);
		redo;
	    } else {
		push @$align, $attr->{align};
	    }
	}
	if (($attr->{type} && $attr->{type} ne $type->{type}) ||
	    ($attr->{unique} && $done_unique{$attr->{unique}}++) ||
	    ($attr->{excludes} && (grep {$_ eq $attr->{excludes}} @anames))) {
	    $attr = $special->($type,$level);
	    redo;
	}

	if ($attr->{name} =~ /^(.*?) \((greater|heavy)\)/) {
	    my $base = $1;
	    @anames = grep {$_ !~ /^\Q$base\E\b/} @anames;
	} elsif ($attr->{name} =~ /^(.*?) \((improved|moderate)\)/) {
	    my $base = $1;
	    next if grep {$_ =~ /^\Q$base\E \((greater|heavy)\)/} @anames;
	    @anames = grep {$_ !~ /^\Q$base\E\b/} @anames;
	}
	if ($attr->{name} =~ /^(.*?) \((\d+)\)/) {
	    my $base = $1;
	    my $res = $2;
	    next if grep {$_ =~ /^\Q$base\E \((\d+)\)/ && $1 >= $res} @anames;
	    @anames = grep {$_ !~ /^\Q$base\E\b/} @anames;
	}
	if ($attr->{plus}) {
	    $cost_plus += $attr->{plus};
	}
	if ($attr->{price}) {
	    $cost_cash += $attr->{price};
	}
	push @anames, $attr->{name};
    }
    push @name, "[".join(", ", @anames)."]" if @anames;
    if ($cost_plus > 10) {
	if ($psi) {
	    return psionic_armor($level);
	} else {
	    return magic_armor($level);
	}
    }
    push @name, "+$plus";
    my $dummy = { %$base, align => [ @$align ], plus => $cost_plus, price => 0 };
    $dummy = roll_intelligence($dummy);
    my $armtype = $base->{type};
    my $wood = $base->{wood};
    my $metal = $base->{metal};
    my $skin = $base->{skin};
    my $name = $base->{name};
    my @materials;
    push @materials, ('adamantine','mithral') if $metal;
    push @materials, ('darkwood') if $wood;
    push @materials, ('dragonhide') if $base->{type} eq 'shield' || ($name =~ /hide|plate|banded/);
    my $mi = 0;
    if (my $material = percentile_lookup([95=>undef,
					  100 => [ map { int(++$mi * (100/@materials)) => $_ } @materials ]],-1)) {
	my $cost = item_material_cost($material,$base);
	if (defined $cost) {
	    push @name, $material;
	    $name =~ s/,\s+(wooden|steel)$//;
	    $cost_cash += $cost;
	}
    }
    push @name, $name;
    push @name, 'armor' if $type eq 'armor';
    if ($dummy->{intelligent}) {
	$cost_cash += $dummy->{price};
	push @name, $dummy->{intdesc}."\n\t";
    }
    my $price = $cost_cash+$costs->[$cost_plus]+$base->{price};
    my $armor = { name => join(' ', @name), type => 'armor', price => $price,
		  intelligent => $dummy->{intelligent}};
    $armor = cursed_item($armor,$psi) if $curses;
    return $armor;
}    

# Takes a type ("armor" or "shield") and returns a specific armor
# type structure containing "name", "type" (light, medium, heavy,
# shield), "weight" (lbs.), and "price". May also contain the
# optional fields: "skin", "metal", and "wood" which indicate what
# kind(s) of special material the item can be made of.
sub item_armor_type {
    my $type = shift;
    my $armors = get_table('armor-types');
    my $shields = get_table('shield-types');
    return percentile_lookup(($type eq 'armor'?$armors:$shields),-1);
}

# Take a level and return an armor special ability structure containing
# the fields, "name" and either "plus" or "price" indicating the cost
# of the ability.
sub armor_special_ability {
    my $level = shift;
    my $abilities = get_table('armor-special-ability');
    return percentile_lookup($abilities, $level);
}

# Same as armor_special_ability, but for psi armor (not shields)
sub psionic_armor_special_ability {
    my $level = shift;
    my $abilities = get_table('psionic-armor-special-ability');
    return percentile_lookup($abilities, $level, \&psionic_armor_special_ability, 'armor', 1);
}

# Same as armor_special_ability, but for psi shields
sub psionic_shield_special_ability {
    my $level = shift;
    my $abilities = get_table('psionic-shield-special-ability');
    return percentile_lookup($abilities, $level, \&psionic_shield_special_ability, 'shield', 1);
}

# Specific armors. See specific_weapon for comments on the need
# for psi equiv.
sub specific_armor {
    my $level = shift;
    my $size = shift;
    my $armors = get_table('specific-armor');
    my $armor = percentile_lookup($armors,$level);
    return { name => "$size $armor->{name}", type => 'armor', subtype => 'armor, specific',
	     price => $armor->{price} };
}

# Specific shields. See above.
sub specific_shield {
    my $level = shift;
    my $size = shift;
    my $shields = get_table('specific-shields');
    my $armor = percentile_lookup($shields,$level);
    return { name => "$size $armor->{name}", type => 'armor', subtype => 'shield, specific',
	     price => $armor->{price} };
}

# Take a level and return a specific magic potion or oil.
sub magic_potion {
    my $level = shift;
    my $potions = get_table('potions');
    my $potion = percentile_lookup($potions,$level);
    my $name = $potion->{name};
    my $subtype = ($name =~ /\((potion|oil)\)/);
    $name = expand_magic_name($name);
    return { %$potion, name => $name, type => 'potion', subtype => $subtype };
}

# Take a level and return a specific magic ring.
sub magic_ring {
    my $level = shift;
    my $rings = get_table('rings');
    my $ring = percentile_lookup($rings,$level);
    my $name = $ring->{name};
    $name = expand_magic_name($name) unless $name =~ /spell storing/;
    return
	cursed_item(
	    price_and_charges(
		roll_intelligence({ %$ring, name => "ring of $name", type => 'ring' })
	    ),0
	);
}

# Take a level and return a magic rod.
sub magic_rod {
    my $level = shift;
    die "There are no 'minor' magic rods" unless $level;
    my $rods = get_table('rods');
    my $rod = percentile_lookup($rods,$level);
    my $name = $rod->{name};
    $name = "the $name" if $rod->{the};
    return
	cursed_item(
	    price_and_charges(
		roll_intelligence({ %$rod, name => "rod of $name", type => 'rod' })
	    ), 0
	);
}

# A magic scroll is just a collection of magic spells,
# and its only value is in the spells themselves (though
# presumably, the scroll paper/velum/etc. is worth something)
sub magic_scroll {
    my $level = shift;
    my $count = shift;
    my $costmult = shift;
    $costmult = 1 unless defined $costmult;
    my $number;
    if ($count) {
	$number = $count;
    } elsif ($level == 0) {
	$number = d3();
    } elsif ($level == 1) {
	$number = d4();
    } else {
	$number = d6();
    }
    my @scroll_contents;
    my $price = 0;
    my $scroll_types = get_table('scroll-type'); # arcane or divine
    my $type = percentile_lookup($scroll_types, -1);
    foreach my $n (1..$number) {
	my $levels = magic_spell_level($level);
	my $spell = magic_spell($levels->{spell},$type);
	$spell->{price} *= $costmult;
	my $name = $spell->{name};
	push @scroll_contents, "$name ".
	    "(lvl $levels->{spell}, cast $levels->{caster}) ".
	    "(".as_gold($spell->{price}).")";
	$price += $spell->{price};
    }
    my $n = 1;
    return { name => "$type scroll containing:\n".join("\n",map {"\t".$n++.". $_"} @scroll_contents),
	     price => $price, type => 'scroll' };
}

# Take an item level (0,1,2) and return two values as
# named fields in a hash: the "spell" level and the
# "caster" level for a scroll.
sub magic_spell_level {
    my $level = shift;
    my $levels = get_table('spell-level');
    return percentile_lookup($levels, $level);
}

# Take a spell level and type (divine, arcane) and return a
# structure that indicates the "name" of the spell and "price".
sub magic_spell {
    my $level = shift; # spell level, not magic item level
    my $type = shift;
    my @divine;
    my @arcane;
    my $spell_list = get_table('spell-list');
    my $spell = percentile_lookup($spell_list->{$type}[$level],-1);
    my $name = expand_magic_name($spell->{name});
    return { %$spell, name => $name };
}

# Take a level and return a magic staff.
# Note that the level cannot be 0, as there is no lookup
# table for "minor" staves.
sub magic_staff {
    my $level = shift;
    die "There are no 'minor' staves" unless $level;
    my $staves = get_table('staves');
    my $staff = percentile_lookup($staves,$level);
    my $pnc = price_and_charges({ %$staff, name=>"staff of $staff->{name}", charges=>50 });
    return { type => 'staff',  %$pnc };
}

# Take a level and return a magic wand. A wand is just like a scroll,
# but contains only one spell, and can cast it up to 50 times,
# expending a "charge" for each cast. The wand is generated with
# a random number of "remaining charges" and the price is pro-rated
# based on that value (charging between 1/50th and 100% of full price).
sub magic_wand {
    my $level = shift;
    my $wands = get_table('wands');
    my $wand = percentile_lookup($wands, $level);
    my $name = $wand->{name};
    my $pnc = price_and_charges({ %$wand, name => "wand of $name", charges => 50});
    return { type => 'wand', %$pnc };
}

# Wondrous items are anything that does not fit into the above categories.
# Wondrous items that do not have charges or doses can be intelligent
# or cursed.
sub wondrous_item {
    my $level = shift;
    my $item;
    if ($level == 0) {
	$item = minor_wondrous_item();
    } elsif ($level == 1) {
	$item = medium_wondrous_item();
    } else {
	$item = major_wondrous_item();
    }
    return cursed_item(roll_intelligence({ %$item }),0);
}

# These three functions could be comnined into one, with a
# single level-based lookup table, but there is no point, since they
# do not overlap. Just returns the base wondrous item.
sub minor_wondrous_item {
    my $items = get_table('minor-wondrous');
    my $wonder = percentile_lookup($items,-1);
    my $name = expand_magic_name($wonder->{name});
    my $price = $wonder->{price};
    return { %$wonder, name => $name, price => $price, type => 'wondrous item' };
}

sub medium_wondrous_item {
    my $items = get_table('medium-wondrous');
    my $wonder = percentile_lookup($items,-1);
    my $name = expand_magic_name($wonder->{name});
    my $pnc = price_and_charges({%$wonder, name => $name});
    return { %$pnc, type => 'wondrous item' };
}

sub major_wondrous_item {
    my $items = get_table('major-wondrous');
    my $wonder = percentile_lookup($items,-1);
    my $name = expand_magic_name($wonder->{name});
    if ($name eq 'chaos diamond') {
	$name .= " with powers:";
	foreach my $power ('confusion, lesser', 'magic circle against law',
			   'word of chaos', 'cloak of chaos') {
	    my $n = d4();
	    $name .= "\n\t$power ($n/day)";
	}
    }
    return { %$wonder, name => $name, type => 'wondrous item' };
}

# Takes an item and optional psi boolean. Returns the item structure, which
# may have been modified to add a curse (depending on the "curses" global
# which holds a percentage chance).
sub cursed_item {
    my $item = shift;
    my $psi = shift;
    return $item if d100() > $curses;
    my $curses = get_table('cursed-items');
    if ($psi) {
	my $psi_curses = get_table('psi-cursed-items');
	# SRD is not clear on how to mix the two, so I choose 50%/50%
	$curses = [ 50 => $curses, 100 => $psi_curses ];
    }
    my $curse = percentile_lookup($curses,-1,$psi);
    return $item unless $curse;
    if (ref($curse)) {
	if ($curse->{price}) {
	    return $curse;
	} elsif ($curse->{type}) {
	    return cursed_item($item,$psi) unless $item->{type} eq $curse->{type};
	}
    }
    return { %$item, name => $item->{name}."\n\tCURSED: $curse" };
}

# Item generation utilities

# Takes an item and manipulates its name and price
# based on the number of charages or power points
# that it contains.
# XXX - This should become a special_* that is added to
# any time that has a fixed set of 2 or more charges.
sub price_and_charges {
    my $item = shift;
    my $charges = $item->{charges};
    my $points = $item->{points};
    my $price = $item->{price};
    my $text = '';
    if ($charges && $charges > 0) {
	my $tmp = int(mktrand(1)*$charges)+1;
	my $scale = $tmp/$charges;
	$price *= $scale;
	$text .= " (charges $tmp)";
    } elsif ($points && $points > 0) {
	my $level = $item->{level};
	if ($level) {
	    my $tmp = int(mktrand(1)*50)+1;
	    my $scale = $tmp/50;
	    $points *= $scale;
	    $price *= $scale;
	    $text .= " (points/level $points/$level)";
	} else {
	    my $tmp = int(mktrand(1)*$points)+1;
	    my $scale = $tmp/$points;
	    $price *= $scale;
	    $text .= " (points $tmp)";
	}
    }
    return { %$item, name => "$item->{name}$text", price => $price };
}

# Some spells and item names have multiple-choice or
# fill-in-the-blank portions. This routine expands or
# resolves those portions.
# XXX - should become a special_
#       Actually, it should become three specials:
#       * Energy type ala random_energy_type
#       * Alignment ala random_alignment
#       * Blindness/deafness ala random_blind_deaf
sub expand_magic_name {
    my $name = shift;
    $name =~ s/^energy\b(?! drain)|\benergy \(type\)/random_energy_type()/e;
    $name =~ s/\(alignment\)|chaos\/evil\/good\/law/random_alignment()/e;
    $name =~ s/blindness\/deafness/random_blind_deaf()/e;
    return $name;
}

# Choose blindness or deafness for items which can be either
sub random_blind_deaf {
    my @choice = ( 50 => 'blindness', 100 => 'deafness' );
    return percentile_lookup(\@choice,-1);
}

# Choose one of the 5 energy types.
sub random_energy_type {
    my $energies = get_table('energy-type');
    return percentile_lookup($energies,-1);
}

# Choose one of the four alignments
sub random_alignment {
    my $alignments = get_table('alignment');
    return percentile_lookup($alignments,-1);
}
	   
# Generate a size for armor and swords
sub rollsize {
    if ($large_items) {
	return percentile_lookup(get_table('size-large'), -1);
    } else {
	return percentile_lookup(get_table('size'), -1);
    }
}

# Take a name, count, and price and return an item structure
# with the given name concatenated with a parenthetical count,
# and the price multiplied by the count.
sub n_of {
    my $name = shift;
    my $count = shift;
    my $each = shift;
    my $price = $each * $count;
    return { name => "$name ($count)", price => $price };
}

# Take a table and level (-1 indicates no level). Roll a d100 and index
# the table. Tables can contain more tables, and if the final value
# is a code ref, execute the closure and return its return value.
# Structure of a table is:
# [ item, item, ... ]
# where item is:
# [ [ a1, b1, c1 ] => result1,
#   [ a2, b2, c2 ] => result2, ... ]
# Where the a, b anc c values are the max percentile result that
# will generate the given result, and the result is either a
# hash representing the item or a sub-table. As a special case,
# a subroutine can be given as a result, which will be invoked
# with a single argument: the level of item to be returned,,, and
# the subroutines return value will be assumed to be the result
# hashref.
# item can also be:
# [ p1 => result1, p2 => result2, ... ]
# where p1, p2 and so on are the percentages. In this case where
# only one "level" can be selected, the level parameter to
# percentile_loop should be set to -1
# The most common usage looks like this:
# percentile_lookup([[[ 50,  10,  -1] => { name => "stuff", type => "ring" },
#                     [ 75,  50,  10] => { name => "junk", type => "potion" },
#                     [ 100, 75,  50] => { name => "toy", type => "weapon" },
#                     [ -1,  100, 75] => { name => "bit", type => "wonder" },
#                     [ -1,  -1, 100] => { name => "bucket", type => "armor" } ]],
#                   -1);
# Notice that the ourter array ref theoretically contains a list of
# cumulative results, but this is only rarely used, so there is a typically
# redundant set of enclosing arrays.
sub percentile_lookup {
    my ($table, $level, @rest) = @_;
    my $choices;
    if ($level >= 0) {
	my $n = $level;
	$n = $#{$table} if $n >= @$table;
	$choices = $table->[$n];
    } else {
	$choices = $table;
    }
    my $dp = d100();
    for(my $i=0;$i<@$choices;$i+=2) {
	my $max = $choices->[$i];
	$max = $max->[$level] if ref $max;
	next unless $dp <= $max;
	if (my $result = $choices->[$i+1]) {
	    if (my $r = ref($result)) {
		if ($r eq 'HASH') {
		    if ($result->{special}) {
			return resolve_special($result,$level,@rest);
		    }
		    if ($result->{reroll}) {
		    	return (percentile_lookup($table, $level, @rest),
		    		percentile_lookup($table, $level, @rest));
		    }
		    return $result; # Structure result
		} elsif ($r eq 'ARRAY') {
		    return percentile_lookup($result, $level,@rest);
		} elsif ($r eq 'CODE') {
		    return $result->($level);
		} else {
		    die "Don't know how to cope with result type '$r'";
		}
	    } else {
		return $result;
	    }
	} else {
	    return(); # empty list for undef table entries
	}
    }
}

sub resolve_special {
    my $thing = shift;
    my $level = shift;
    my $special = $thing->{special};
    return $thing unless $special;
    if (!ref $special) {
	$special = [$special];
    }
    my @things;
    foreach my $sp (@$special) {
	unless(exists $specials{$sp}) {
	    die "Special not handled: $sp";
	}
	#dbg("Invoking special_$sp");
	push @things, $specials{$sp}->($thing,$level,@_);
    }
    if (wantarray) {
	return @things;
    } else {
	return shift @things;
    }
}

# Return a number of gold pieces (fractions allowed) as a
# string of the form "xgp ysp zcp" where only non-zero values
# are listed. So the number 1.2 would become "1gp 2sp"
sub as_gold {
    my $price = shift;
    $price += 0.005;
    my @d;

    # Gold
    my $n = int($price);
    push @d, commas($n)."gp" if $n;

    # Silver
    $price = ($price-$n)*10;
    $n=int($price);
    push @d, commas($n)."sp" if $n;
    
    #Copper
    $price = ($price-$n)*10;
    $n=int($price);
    push @d, commas($n)."cp" if $n;

    # And return the resulting string
    return join " ", @d;
}

# Take a string representation of dice rolling and return
# a randomly generated number.
# Strings are of the format: adb[+c][*e]
# Where a is the number of dice, d is the literal
# string "d", b is the number of sides on the dice,
# c is an optional value to be added to the result, and
# e is an optional value to multiply the final result
# by (including any added by c)
# Examples: 3d6, d20, 2d8+7, d12*2000
sub parse_die {
	local $_ = shift @_;
	if (/^\d+$/) {
		return $_+0;
	} elsif (/^(\d+)?d(\d+)(?:\+(\d+))?(?:\*(\d+))?/) {
		my($n,$d,$add,$mult) = (($1||1),$2,$3,$4);
		#dbg("Parsing die '$_': ($n,$d,$mult,$add)");
		my $t = d($d,$n);
		$t += $add if $add;
		$t *= $mult if $mult;
		dbg("Die roll: $_: $t");
		return $t;
	}
	die "Cannot parse die roll: '$_'";
}

# Generic utilities

# Roll a die. Parameters: sides and count
sub d {
    my($sides,$count) = @_;
    if (!$count || $count == 1) {
	return int(mktrand($sides)) +1;
    } else {
	my $total = 0;
	$total += int(mktrand($sides)) +1 foreach 1..$count;
	return $total;
    }
}

sub d2   { return d(  2,@_) }
sub d3   { return d(  3,@_) }
sub d4   { return d(  4,@_) }
sub d6   { return d(  6,@_) }
sub d8   { return d(  8,@_) }
sub d10  { return d( 10,@_) }
sub d12  { return d( 12,@_) }
sub d20  { return d( 20,@_) }
sub d100 { return d(100,@_) }

# A simple helper for printing out progress in verbose mode
sub v {
    local $\ = "\n";
    print STDERR "$_[0]" if $verbose;
}
sub dbg { v(@_) if $debug }

# Take a number like "5" and return a string like "5th"
sub nth {
    my $n = shift;
    if ($n =~ /11$/) {
	return $n."th";
    } elsif ($n =~ /1$/) {
	return $n."st";
    } elsif ($n =~ /12$/) {
	return $n."th";
    } elsif ($n =~ /2$/) {
	return $n."nd";
    } else {
	return $n."th";
    }
}

# Add commas to a number per U.S. convention
sub commas {
    my $n = shift;
    return $n unless $n >= 1000;
    my $new = substr($n,-3,3);
    for(my $i = -4;abs($i)<=length($n);$i-=3) {
	$new = substr($n,$i-2,3) . ",$new";
    }
    return $new;
    #return join(',',reverse map {''.reverse $_} grep {$_} split /(\d{1,3})/, ''.reverse $n);
}

# Return the smallest numeric value from a list
sub min {
    my $min = undef;
    foreach my $x (@_) {
	$min = $x if !defined($min) || $x < $min;
    }
    return $min;
}

# seed rand() with a value gathered from the best
# source available that will not block.
sub init_rand {
    local *R;

    unless(defined($random_seed)) {
        if (open(R,"</dev/urandom")) {
            sysread(R,my $buf,4);
            close R;
            $random_seed = unpack("I",$buf);
        } else {
            $random_seed = (time()^($$<<4)^(++$rand_fudge<<12));
        }
    }
    srand($random_seed);
}

# This used to call into a truly random number generator, but
# there's no real point. If you feel strongly about cryptographically
# random treasure, then replace this function body ith the
# appropriate library call.
sub mktrand($) {
    return rand($_[0]);
}

# Shuffle a list
sub shuffle {
    my @items = @_;
    for(my $i=0;$i<@items;$i++) {
	my $r = int mktrand @items;
	next if $r == $i;
	@items[$i,$r] = @items[$r,$i];
    }
    @items;
}

# All YAML table loading is done here. We take a table name,
# attach ".yaml" and then try to locate it. We search the
# current directory and the path in @tablepath (global).
# The resulting data is cached, so the return value from
# this function should be treated as READ ONLY data!
# If you want to make changes, use dclone to get a deep
# copy.
sub get_table {
    my $name = shift;
    return $table_map{$name} if $table_map{$name};
    my $tname = $name;
    $tname .= ".pathfinder" if $pathfinder;
    my $file = "$name.yaml";
    if (-f $file) {
	;
    } elsif (@tablepath) {
	foreach my $path (@tablepath) {
	    if (-f "$path/$file") {
		$file = "$path/$file";
		last;
	    }
	}
	die "Cannot find table data for '$name'\n" unless -f $file;
    } else {
	die "Cannot find table data for '$name'\n";
    }
    my $data = LoadFile($file);
    if ($data) {
	v("YAML data for '$name' loaded");
    } else {
	die "Could not load YAML data for '$name': $!\n";
    }
    return $table_map{$name} = $data;
}

# All special_* functions are called when the external
# data is resolved for an item, if and when a "special:"
# field is encountered in the data. This is done automatically,
# and the item structure (if any) and level of the item (if any)
# are passed in to the target function. So, this YAML data:
#
# -
#  -
#   -
#    - 100
#    - 100
#    - 100
#   - special: foo
#     name: bar
#
# would result in special_foo({special=>'foo',name=>'bar'},},$n)
# where $n is the level that was passed to percentile_lookup.
#
# Any extra parameters passed to percentile_lookup are also
# passed to the special_* function, and the return value becomes
# the return value of the percentile_lookup function.

# Resolve dice-string coin amounts into randomly rolled values
sub special_coin {
    my $item = shift;
    my $level = shift;
    my %ctypes = ( plat => 0, gold => 1, silver => 2, copper => 3);
    foreach my $ctype (keys %ctypes) {
	if ($item->{$ctype}) {
	    return coin(parse_die($item->{$ctype}),$ctypes{$ctype});
	}
    }
    die "Cannot understand what I'm supposed to do with special coins: ".Dumper($item);
}

# Parse the dice-string in the 'gems' field
sub special_gems {
    my $item = shift;
    my $level = shift;
    return gems(parse_die($item->{gems}));
}

# Parse the dice-string in the 'art' field
sub special_art {
    my $item = shift;
    return art(parse_die($item->{art}));
}

# Given a count, generate and return a number of art objects.
sub special_art_name {
    my $item = shift;
    my $art_names = get_table('art-names');
    if ($nonstandard) {
	$art_names = dclone($art_names);
	my @materials = qw(wooden brass bone porcelain marble crystal
			   jade-inlaid silver electrum gold gem-encrusted
			   platinum);
	my @objects = qw(candelabra wine-cup dinnerware plate brooch
			 figurine paperweight sword-stand pipe
			 shoe-rack bracelet sculpture clasp door-knocker
			 scepter pommel ring music-box hilt);
	my @descriptors = qw(fine tiny ornate old intricate delicate
			     decorated baroque etched smooth faceted);
	for(my $i = 0;$i < @materials;$i++) {
	    my $material = $materials[$i];
	    push @{$art_names->[$i]}, map {"$_ with $material stand"} @{$art_names->[$i]};
	    foreach my $object (@objects) {
		next if $object eq 'ring' && $material eq 'wooden';
		foreach my $descriptor (@descriptors) {
		    push @{$art_names->[$i]}, "$descriptor $material $object";
		}
	    }
	    push @{$art_names->[$i]}, "$material idol";
	}
    }
    return art_value(parse_die($item->{price}), $art_names->[$item->{art_level}]);
}

# Parse the dice-string in the 'mundane' field
sub special_mundane {
    my $item = shift;
    return mundane(parse_die($item->{mundane}));
}

# Handle sub-table with specific add-on default fields
sub special_mundane_armor {
    my $size = rollsize();
    my $armor = get_table('mundane-armor');
    my $ma = percentile_lookup($armor,-1);
    return { name => "$size $ma->{name}", price => $ma->{price}, subtype => 'armor' };
}

# Just a wrapper for mwk_weapon
sub special_masterwork_weapon {
    return mwk_weapon();
}

# Parse dice and pass off to minor/meduim/major
sub special_minor  { my $item = shift; minor( parse_die($item->{minor} )) }
sub special_medium { my $item = shift; medium(parse_die($item->{medium})) }
sub special_major  { my $item = shift; major( parse_die($item->{major} )) }

# Wrapper functions for the various item types
sub special_magic_armor { shift @_; goto &magic_armor }
sub special_magic_weapon { shift @_; goto &magic_weapon }
sub special_magic_potion { shift @_; goto &magic_potion }
sub special_magic_scroll { shift @_; goto &magic_scroll }
sub special_magic_ring { shift @_; goto &magic_ring }
sub special_magic_rod { shift @_; goto &magic_rod }
sub special_magic_staff { shift @_; goto &magic_staff }
sub special_magic_wand { shift @_; goto &magic_wand }
sub special_wondrous_item { shift @_; goto &wondrous_item }
sub special_psionic_armor { shift @_; goto &psionic_armor }
sub special_psionic_weapon { shift @_; goto &psionic_weapon }
sub special_psionic_cognizance { shift @_; goto &psionic_cognizance }
sub special_psionic_dorje { shift @_; goto &psionic_dorje }
sub special_psionic_power_stone { shift @_; goto &psionic_power_stone }
sub special_psicrown { shift @_; goto &psicrown }
sub special_psionic_tatoo { shift @_; goto &psionic_tatoo }
sub special_psionic_universal_item { shift @_; goto &psionic_universal_item }


# Item needs a knowledge skill tacked on to the end of the name
sub special_knowledge {
    my $item = shift;
    my $name = $item->{name};
    my @knowledges = ('arcana', 'architecture and engineering', 'dungeoneering',
		      'geography', 'history', 'local', 'nature', 'nobility and royalty',
		      'religion', 'the planes');
    $name .= ' ('.$knowledges[int mktrand @knowledges].')';
    return { %$item, name => $name };
}

# Add a parenthesized instrument name
sub special_instrument {
    my $item = shift;
    my $name = $item->{name};
    # XXX - should add price of instrument
    my @instruments = qw(harpsichord piano triangle tambourine bells chime
			 bongos conga gong fiddle harp lute mandolin flute
			 pan pipes recorder shawm trumpet);
    my $inst = $instruments[int mktrand @instruments];
    $name .= " ($inst)";
    return { %$item, name => $name };
}

# Add a parenthesized element name to an item name
sub special_element {
    my $item = shift;
    my $name = $item->{name};
    my $type = percentile_lookup([25=>'air',
    				  50=>'earth',
				  75=>'fire',
				  100=>'water'],-1);
    $name = "$name ($type)";
    return { %$item, name => $name };
}

# Spellworms are like scrolls, but only one-per and twice the price
sub special_spellworm {
    my $item = shift;
    my $level = shift;
    $item = { %$item, %{magic_scroll($level,1,2)}, type => 'wonder' };
    my $name = $item->{name};
    $name =~ s/scroll/spellworm/;
    return { %$item, name => $name };
}

# Generate special types of books where appropriate
sub special_book {
    my $book = shift;
    my $level = shift;
    my $name = $book->{name} || "unknown tome";
    my $price = $book->{price} || 0;
    # Dragon #341 introduces "floating" as a sort of special material for books
    if ($dragon && d100() <= 10 ) {
	$name .= " (floating - see Dragon 341)";
	$price += 500;
    }
    return { %$book, name => $name, price => $price };
}

# Armor or weapon has rolled a table entry that calls for two
# abilities. percentile_lookup MUST be called with extra args:
# subroutine ref to call, type of item, psi (boolean)
sub special_two_abilities {
    my $item = shift;
    my $level = shift;
    my $ability_sub = shift;
    my $type = shift;
    my $psi = shift;
    return $ability_sub->($level,$type,$psi),
	   $ability_sub->($level,$type,$psi);
}

# Bane abilities (including bane and slaying) need a target opponent type
# Takes an ability name and returns the name with target type added.
sub special_bane {
    my $item = shift;
    my $name = $item->{name};
    my $banes = get_table('bane-types');
    my $bane = percentile_lookup($banes,-1);
    $name = "$name ($bane)";
    return { %$item, name => $name };
}

# Like a scroll, but in ring form, and re-usable
sub special_spell_storing {
    my $ring = shift;
    my $level = shift;
    my $max_levels = $ring->{spells_stored};
    my @spells;
    while($max_levels) {
	my $levels = magic_spell_level($level);
	if ($levels->{spell} > $max_levels) {
	    last;
	}
	$max_levels -= $levels->{spell};
	my $spell = magic_spell($levels->{spell},'arcane');
	push @spells, "$spell->{name}(cl=$levels->{caster})";
    }
    my $name = $ring->{name};
    if (@spells) {
	$name .= " (spells: ".join("; ",@spells).")";
    } else {
	$name .= " (empty)";
    }
    return { %$ring, name => $name };
}

# Absorption rods have special random generation rules
# for spell levels stored and available.
sub special_absorption {
    my $levels_left = int(d100()/2)+1;
    my $levels_stored = 0;
    if (d100() >= 71) {
	$levels_stored = int($levels_left/2);
    }
    my $price = 50_000;
    $price = ($levels_left+$levels_stored)/100*$price;
    return { name => "absorption (potential $levels_left, stored $levels_stored)" ,
	     charges => -1, price => $price };
}

# A robe of useful items needs to have the useful items listed
sub special_useful_items {
    my $item = shift;
    my $level = shift;
    my $name = $item->{name};
    my $price = $item->{price};
    my $n = d4(4);
    my @items;
    my $things = get_table('useful-items');
    $name .= " with:";
    foreach my $i (1..$n) {
        my $thing = percentile_lookup($things, -1);
	my $thing_name = $thing->{name};
	my $thing_price = $thing->{price};
        if ($thing_name eq 'scroll') {
	    my $scroll = magic_scroll(0,1);
	    $thing_name = $scroll->{name};
	    $thing_name =~ s/\n\t/\n\t\t/g;
	    $price += $scroll->{price};
        } elsif ($thing_price) {
	    $price += $thing_price;
        }
        $name .= "\n\t$thing_name";
    }
    return { %$item, name => $name, price => $price };
}

# efreeti_bottles contain an efreeti. Determine its temperment
sub special_efreeti_bottle {
    my $item = shift;
    my $name = $item->{name};
    my $etypes = get_table('efreeti-bottle');
    my $etype = percentile_lookup($etypes,-1);
    $name .= " (disposition: $etype)";
    return { %$item, name => $name };
}

# Select a horn type
sub special_horn_of_valhalla {
    my $item = shift;
    my $name = $item->{name};
    my $htypes = get_table('horn-of-valhalla');
    my $htype = percentile_lookup($htypes,-1);
    $name .= ", $htype";
    return { %$item, name => $name };
}

# Select contents of iron flask
sub special_iron_flask {
    my $item = shift;
    my $name = $item->{name};
    my $price = $item->{price};
    my $contents_table = get_table('iron-flask');
    my $contents = percentile_lookup($contents_table,-1);
    if ($contents ne 'empty') {
	$price = int($price * 1.1); # 10% is arbitrary
    }
    $name .= " ($contents)";
    return { %$item, name => $name, price => $price };
}

# Select a robe color (alignment)
sub special_robe_of_the_archmagi {
    my $item = shift;
    my $name = $item->{name};
    my $rtypes = get_table('robe-of-the-archmagi');
    my $rtype = percentile_lookup($rtypes,-1);
    $name .= ", $rtype";
    return { %$item, name => $name };
}

# For two-spell pearls of power, select the levels
sub special_pearl_of_power {
    my $item = shift;
    my $l1 = d6();
    my $l2 = d6();
    my $name = $item->{name} . " (levels $l1, $l2)";
    return { %$item, name => $name };
}

# Deck of illusions can be missing cards, and if so, is pro-rated
# like a wand.
sub special_deck_of_illusions {
    my $item = shift;
    my $level = shift;
    my $name = 'deck of illusions';
    my $price = 8_100;
    if (d100() > 10) {
	$name .= " (complete)";
    } else {
	my $missing = d20();
	my $scale = (34-$missing)/34;
	$price *= $scale;
	my $cards = get_table('deck-of-illusions');
	my @missing;
	my %seen;
	for(my $c=0;$c<$missing;$c++) {
	    my $card = percentile_lookup($cards,-1);
	    redo if !$card || $seen{$card}++;
	    push @missing, $card;
	}
	$name .= " - missing cards:\n\t".join("\n\t",@missing);
    }
    return { %$item, name => $name, charges => -1, price => $price };
}

# This is a special feature of the data-files, where a single
# value can contain sub-tables which are merged as strings.
# The passed in "item" structure must contain a "left"
# and "right" field.
sub special_concatenate {
    my $item = shift;
    my $level = shift;
    my $left = $item->{left};
    my $right = $item->{right};
    $left = percentile_lookup($left,$level) if ref $left;
    $right = percentile_lookup($right,$level) if ref $right;
    return $left.$right;
}

# Takes an item structure and optional psi boolean, and returns
# a specific cursed item to replace it.
sub special_specific_cursed_item {
    my $item = shift;
    my $level = shift;
    my $psi = shift;
    my $items = get_table('specific-cursed-items');
    if ($psi) {
	my $psi_items = get_table('specific-psionic-cursed-items');
	# Again, SRD doesn't say, so I guess at appropriate ratio
	$items = [ 10 => $psi_items, 100 => $items ];
    }
    $item = percentile_lookup($items,-1);
    return { %$item, name => "CURSED: $item->{name}" };
}


__END__

=head1 NAME

mktreasure - Treasure generator based on the d20 SRD role playing game system

=head1 SYNOPSIS

  mktreasure [options]

  Options:

	-h or --help		Brief help text
       --man			Print manual
	-v or --verbose		Turn on verbose output
	--count N		Print N sets of results
	-c or --cr or
	--challenge-rating N	Treasure for CR N (default=1)
	--cursed		Include cursed items (5%)
	--dragon		Include Dragon Magazine items
	--force TYPE		Print out a random TYPE item
	--intelligent		Force intelligence on all items
	--large-items		Include large items too
	-n or --non-standard	Include non-standard items
	--only-cursed		Do not include non-cursed magical items
	--only-psionics		Do not include normal magical items
        --pct-psionics N	Include N% psionic items
	--psionics		Include psionic items (10%)
	--save-random		Print the random number seed used
	--random-seed N		Use N as the seed for random numbers
	--table-path PATH	Use PATH to find the data tables

=head1 DESCRIPTION

The d20 System is a role playing system introduced by Wizards of the Coast
and distributed under the Open Gaming License (OGL). This program
generates random treasure hordes according to the d20 System Reference
Document (SRD) version 3.5 with only minor variations from the core rules
where the default rules would not provide useful programatic results or
would be impossible for a program to reasonably generate (e.g. some of
the tables list a "select an item" entry).

While I am not a lawyer, and this is a free program, you may wish to
consult the Open Game License and the d20 System Trademark License
which may or may not limit the use and modification of this software.

This software is B<not meant to be used on its own>. d20 core
reference materials are required for actual game play.

=head1 OPTIONS

=over 5

=item B<-h> or B<--help>

Produce a short options summary and exit.

=item B<--man>

Produce this manual and exit.

=item B<-v> or B<--verbose>

Turn on verbose output (this is only intended for debugging).

=item B<--count>

Provide a repeat count for items to output.

=item B<-c>, B<--cr> or B<--challenge-rating>

Provide a challenge rating. This challenge rating can be between
1 and 25, inclusive. The treasure generated will be appropriate for
a creature of the given challenge rating.

Default is 1.

=item B<--cursed>

Include cursed items in results 5% of the time.

=item B<--dragon>

Include Dragon magazine items in the output. Only the name, issue
number and price are included. For further information, you must
have access to the Dragon magazine issue referenced.

=item B<--force>

This option changes the output of the program radically. Instead of
generating a treasure horde, a single item type is output. The following
are valid values to pass to the B<--force> option:

=over 5

coin, gem, art, mundane, armor, weapon, potion, ring, rod, scroll, staff, wand, rod, wonder

=back

Each of these values can be preceded by "minor-", "major-" or
"medium-" to request the given "level" of item.

If the B<--psionics> option is given, the following items are
also available:

=over 5

cognizance, dorje, power-stone, psicrown, tatoo, universal

=back

=item B<-I> or B<--intelligence>

Force all items which I<can> be intelligent to be generated that way. This
is most useful when combined with C<--force> to ensure that the generated
items are of a type that can be intelligent in the first place.

=item B<-l> or B<--large-items>

By default items that have a sizing are generated 10% small and
80% medium. This option changes that ratio to 10% small, 10%
large and 80% medium.

=item B<-n> or <--non-standard>

Include non-standard items in gems and art results. These items
just add more variety, but do not change the gold piece value of
the treasure.

This also changes the odds of gems, art and minor items at CR 5 in
a way that appears to have been intended. This is done on the assumption
that the values given for CR5 in the SRD are a (minor) mistake.

=item B<--only-cursed>

Curse all magical items that are generated (this does not include
magic items with charges or doses).

=item B<--only-psionics>

Use only the random item table from the psionics section. The only
time magic loot will be generated is if a weapon or armor item
gets the "specific item" result (for which there are no psionic
equivalents.

=item B<--pct-psionics>

Given a percentage, generate that percentage psionic items and the
rest magical. Example:

  mktreasure --pct-psionics 50

would generate a psionic item half of the time a magical item
would be called for.

=item B<--psionics>

Include psionic items in treasure.

The B<--psionics> option reduces the chance of normal magical
items by 10%, and instead produces a random psionic item.

Thus, there is a fairly small chance that psionic items will be
generated, but this tends to be in-line with the ratio of magic to
psionics in most campaigns. If you run a campaign with a more
even mix of psionics and magic, consider generating some of your
treasure hordes with the B<--only-psionics> option instead.

=item B<--table-path>

Also C<-P>

Search in the given path for the data files.

=back

=head1 AUTHOR

This program was written by Aaron Sherman. It is (c) 2005 by Aaron Sherman
E<lt>ajs@ajs.comE<gt>. This program is distributed under the terms of the
Open Gaming License version 1.0a
(see L<http://www.wizards.com/default.asp?x=d20/article/20040121a>).

All item names, spells, abilities, descriptions and powers are the copyrighted
work of Wizards of the Coast, and derive from the d20 SRD version 3.5.

It's not at all clear to the author of this program how to procede
with respect to the d20 license vs. the OGL. What I can say is this:
I'll submit to whatever Wizards thinks is best, but this tool is
meant to meet the spirit of this item from their FAQ:

=over 5

Q: Why can't I use those things in my program?

A: No d20 System Product can include rules for character creation or
applying experience. In exchange for using the d20 logo you are
prohibited from making a product that replaces the core rulebooks.
Covered Products supplement the core rulebooks; they may not replace
them. That is why all Covered Products must state that they require
the use of the core rules. 

=back

This program does not attempt to replace core rules in any way, and
in fact acts only as an electronic index without descriptions,
explanations or the expanded text provided even in the OGL sources.

One exception is that the items added by the B<--dragon> command-line flag
are from Paizo Publishing's Dragon Magazine, but the copyright for Dragon
is owned by Wizards of the Coast, as well. These items are NOT OGL content,
and are used here without permission in the hopes that Wizards and Paizo
recognize the spirit in which they are referenced, again as an index
and without the required material which would make them useful in
a gaming context without the original source material.

=cut
