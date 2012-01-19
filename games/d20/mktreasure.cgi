#!/usr/bin/perl

use CGI qw(:html :html4 escapeHTML);
use CGI::Carp qw(fatalsToBrowser);

my $cgi = new CGI;
my $oldcgi = new CGI $cgi;

my $force = $cgi->param("force");
my $cr = $cgi->param("cr");
my $oldseed = $cgi->param("oldseed");
if ($oldseed) {
	$oldseed =~ /^(\d+)$/ or die "Invalid seed value\n";
	$oldseed = $1;
}
$cgi->delete('force');

$|=1;
$home = '/home/ajs';
$mkt = "$home/bin/mktreasure -P $home/public_html/cgi-bin/d20-treasure";
#$mkt = "$home/bin/mktreasure";
if ($oldseed) {
	$mkt .= " --random-seed $oldseed";
}
print $cgi->header(), $cgi->start_html(-title => "d20 Treasure Generator",  -meta=>{'keywords'=>'d20 treasure srd d&d dungeons & dragons magic item ring wand staff scroll pp gp sp cp', 'copyright'=>'copyright 2006 by Aaron Sherman, distributed under the OGL 1.0a'});
print qq{<div style="width: 30%; border: thin black solid; float: right; margin: 1em; padding: 1em; font-size: smaller;">\n};
print "<p>Specific items:<ul>\n";
foreach my $forcer (qw(coin gem art mundane item armor potion rod ring scroll staff wand weapon wonder psionic-item psionic-armor psionic-weapon psionic-cognizance psionic-dorje psionic-power-stone psionic-psicrown psionic-tatoo psionic-universal Dragon intelligent-item)) {
	my @forcers;
	foreach my $level (qw(minor medium major)) {
		next if $level eq 'minor' && ($forcer eq 'rod' || $forcer eq 'staff' || $forcer eq 'psionic-psicrown');
		next if ($level eq 'medium' || $level eq 'major') &&
			grep {$_ eq $forcer} qw(gem art mundane);
		$cgi2 = new CGI("");
		$cgi2->delete_all();
		$cgi2->param(force=>"$level-$forcer");
		push @forcers, $cgi2->a({rel=>"nofollow",href=>$cgi2->self_url()}, "$level");
	}
	print li(b($forcer).": ". join(", ", @forcers));
}
print "\n</ul></div>";
#print qq{<div style="margin: 1em; padding: 1em;">\n};
print qx{cat /home/ajs/public_html/genblurb.html}, hr();
print $cgi->start_form(-action=>$cgi->url(-query=>0,
					  -relative=>1)),
	p("CR: ".$cgi->popup_menu(-name => 'cr',
				  -values => [1..30]).
	" " . $cgi->checkbox(-name=>'nonstandard',-checked=>0,
		 -label=>"Non-standard items").
        " " . $cgi->checkbox(-name=>'large',-checked=>0,
		 -label=>"Large items").
        " " . $cgi->checkbox(-name=>'cursed',-checked=>0,
		 -label=>"Cursed items").
        " " . $cgi->checkbox(-name=>'dragon',-checked=>0,
		 -label=>"Dragon Magazine").
	br(). "Psionics: ". $cgi->radio_group(-name=>'psi',
				-values=>['None','Mixed','Only'],
				-default=>'None').
	br(). "Multiplier: ". $cgi->radio_group(-name=>'mult',
				-values=>[1,2,3,4],
				-default=>1).
	br(). $cgi->submit()), $cgi->end_form();
#print qq{</div>\n};
#print qq{<br clear="both" />\n};
if ($cr || $force) {
	local *P;
	print hr();
	my $ns = ($cgi->param("nonstandard")?"--non-standard":"");
	if ($force) {
		my $psi = '';
		if ($force =~ /^((major|medium|minor)-(coin|gem|art|mundane|item|armor|potion|ring|rod|scroll|staff|wand|weapon|wonder|Dragon|intelligent-item|(psionic)-(item|armor|weapon|cognizance|dorje|power-stone|psicrown|tatoo|universal)))$/) {
			if ($4) {
				$psi = '--only-psi';
				$force = "$2-$5";
			} else {
				$force = $1;
				if ($3 eq 'intelligent-item') {
					$force = 'item';
					$psi = '--intelligent';
				}
			}
			if ($3 eq 'Dragon') {
				$psi .= ' --dragon';
			}
		} else {
			die "Cannot parse forcer: '$force'\n";
		}
		print h2("Random items: $force");
		open(P,"$mkt $psi --force '${force}x10' --save-random 2>&1 |") or die "Cannot run $mkt";
	} else {
		$cr = $1 if $cr =~ /^(\d{1,2})$/;
		my $extra_args = '';
		my $psi = $cgi->param('psi');
		if ($psi eq 'Mixed') {
			$extra_args .= '--psi';
		} elsif ($psi eq 'Only') {
			$extra_args .= '--only-psi';
		}
		if ($cgi->param('large')) {
			$extra_args .= ' --large';
		}
		if ($cgi->param('cursed')) {
			$extra_args .= ' --cursed';
		}
		if ($cgi->param('dragon')) {
			$extra_args .= ' --dragon';
		}
		if ($cgi->param('mult') > 1) {
			$extra_args .= " --multiplier ".$cgi->param('mult');
		}
		print h2("CR $cr Random Treasure");
		open(P,"$mkt $ns $extra_args --cr $cr --save-random 2>&1 |") or die "Cannot run $mkt";
		# print "<pre>$mkt $ns $extra_args --cr $cr --save-random</pre>\n";
	}
	print "<pre>";
	my $any = 0;
	while(<P>) {
		next if /^Total value: 0gp$/;
		if (/^Re-run with '--random-seed (\d+)'/) {
			$seed = $1;
			next;
		}
		print qq{<hr width="40%" align="left" />} if /^Total value:/;
		$any = 1;
		print escapeHTML($_);
	}
	print "</pre>";
	print p(b("No treasure")) unless $any;
	if ($seed) {
		$oldcgi->param('oldseed',$seed);
		print qq{<div style="text-align: right;font-size: smaller;">},
			$oldcgi->a({rel=>"nofollow",href=>$oldcgi->self_url()},
				"link to this result"),
			qq{</span>\n};
	}
	die $! if $!;
	close P or die $!;
}
print $cgi->end_html();
