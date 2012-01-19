#!/usr/bin/perl
use strict;

use Pod::Usage;
use POSIX;
use DBI;
use URI;
use CGI qw(:standard :html3 *table escapeHTML);
use CGI::Carp qw(fatalsToBrowser);
use IO::Handle;
use List::Util qw(sum);
use Date::Parse qw(str2time);
use File::Copy;
use File::Temp qw(tempfile);
use GD;
use Sys::Hostname qw(hostname);

$|=1;

my $imgdir = "/var/www/html/wowimages";
my $imgage = 1; # Store cached images for 1 day
my $cgi = CGI->new();

my $google = q{
<!-- Google analytics -->
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-2739280-1";
urchinTracker();
</script>
};
my $host = $cgi->virtual_host() || $cgi->server_name() || hostname();
my $google_ad;
if ( $host =~ /wowstreet/i ) {
	$google =~ s/-1/-3/;
	$google_ad = q{
	<script type="text/javascript"><!--
	google_ad_client = "pub-1518182262871008";
	//120x600, created 11/28/07
	google_ad_slot = "5123321365";
	google_ad_width = 120;
	google_ad_height = 600;
	//--></script>
	<script type="text/javascript"
	src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
	</script>
	};
} else {
	$google_ad = q{
	<script type="text/javascript"><!--
	google_ad_client = "pub-1518182262871008";
	//Warcraft Utility Skyscraper
	google_ad_slot = "1259497162";
	google_ad_width = 120;
	google_ad_height = 600;
	//--></script>
	<script type="text/javascript"
	src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
	</script>
	};
}
$google_ad =~ s/^\s+//mg;

my $database = 'wowitems';
my $driver = 'mysql';
my $host = 'localhost';
my $user = 'root';
my $pass = undef;
my %sql_statement_handle_cache;
my $dsn = "DBI:$driver:database=$database;host=$host";
my $dbh = DBI->connect($dsn,$user,$pass) or die "$0:$dsn: Failed: $DBI::errstr";

my $sth;
my $row;

my $itemid = $cgi->param('i');
my $plot = $cgi->param('plot');
my $realm = $cgi->param('realm');
my $faction = $cgi->param('faction');
our $itemcache;
unless($plot) {
    my $homeurl = $cgi->url();
    print $cgi->header(-type => 'text/html',
		       -charset => 'utf-8',
		       -expires => '+10h');
    my $context="";
    if ($cgi->param('i')) {
	my $item = fetch_item($dbh,$cgi,$cgi->param('i'));
	$context = escapeHTML(": $item->{name}");
    } elsif ($cgi->param('report') eq 'search') {
	$context = escapeHTML(": ".$cgi->param('q'));
    }
    print $cgi->start_html(-title=>"World of Warcraft Item Database Search".
				   $context,
			   -style=>{'src'=>'main.css'});
    print qq{\n<div class="logo"><a href="$homeurl"><img border=0 src="/images/wowstreetlogo.png" alt="Wowstreet at AJS.COM"/></a></div>\n};
    print qq{<div class="search">\n};
    print $cgi->start_form();
    print qq{Search: };
    print $cgi->hidden(-name=>"report",-value=>"search");
    print $cgi->textfield(-name=>"q");
    print $cgi->end_form();
    print qq{</div>\n};

    $sth = call_sql($dbh,"count1","select count(*) from item_generic");
    (my $count) = $sth->fetchrow_array();
    print "<tt><b>In the database:</b> $count items<br/>\n";
    $sth = call_sql($dbh,"count2","select `count` from auction_metadata");
    ($count) = $sth->fetchrow_array();
    print "<b>Auctions scanned:</b> $count</tt><br/>\n";

    $sth = call_sql($dbh,"realm info", "select realm, faction, auction_count, date(last_scanned) as 'last_scanned' from realm_faction_summary order by auction_count desc");
    print qq{<div class="headsummary">\n};
    print qq{<div class="google_ad">$google_ad</div>\n};
    print qq{<tt>\n};
    my $tmp = $cgi->new();
    $tmp->delete('realm');
    $tmp->delete('faction');
    my $alluri = $tmp->self_url;
    print qq{[<a href="$alluri">All realms</a>] };
    $tmp->param('faction'=>'Horde');
    my $factionuri = $tmp->self_url;
    print qq{[<a href="$factionuri">Horde</a>] };
    $tmp->param('faction'=>'Alliance');
    my $factionuri = $tmp->self_url;
    print qq{[<a href="$factionuri">Alliance</a>]<br/><br/>\n};
    while((my $realm = $sth->fetchrow_hashref)) {
	$tmp->param('faction'=>$realm->{faction});
	$tmp->param('realm'=>$realm->{realm});
	my $realmuri = $tmp->self_url;
	my $where = qq{<a href="$realmuri">$realm->{realm}/}.
	    qq{$realm->{faction}</a>};
	print( $where,
	       qq{ $realm->{auction_count} auctions last scanned $realm->{last_scanned}<br/>\n});
    }
    print qq{</tt></div>\n};
}

my $report = $cgi->param('report');
$report = "common" unless $report;
if ($itemid) {
    by_item($cgi,$dbh,$itemid,$plot);
} elsif ($report eq 'search') {
    my $query = $cgi->param('q');
    my $search_s = escapeHTML($query);
    my $search_q = "\%$query\%";
    report_header($dbh,$cgi,"Search results for \"$search_s\"");
    my($table,$where,$args) = table_info($cgi);
    if (@$where) {
	$where = "and " . join(" and ", @$where);
    } else {
	$where = "";
    }
    my $sth = call_sql($dbh, "item search",
       "select t.*, q.color from item_generic_by$table t inner join item_quality q on t.quality = q.id where t.name like ? $where order by `count` desc limit 50",$search_q, @$args);
    display_item($cgi,$sth);
} else {
    report_header($dbh,$cgi,qq{Most $report items});
    report($cgi,$dbh,$report);
}

unless ($plot) {
    print qq{<p class="footnote"><sup>*</sup> - Volatility is measured over the most recent one-week period and measures the ratio of standard deviation to median.</p><br/>\n};
    print qq{<br style="clear: both;"/><hr/>\n};
    print qq{<div class="footer">};
    print qq{The World of Warcraft item database search is a service of <a href="http://www.ajs.com/ajswiki/World_of_Warcraft:_Raiding_the_Metagame">Raiding the Metagame</a>.\n};
    print qq{<br/>"The most valuable commodity I know of is information." -Gordon Gekko, <i>Wall Street</i> (1987)\n};
    print qq{</div>\n};
    print $google, $cgi->end_html();
}
exit 0;

sub table_info {
    my $cgi = shift;
    # For itemid searches, don't use quality
    my $quality = $cgi->param('quality');
    $quality=undef if $cgi->param('i');
    my $realm = $cgi->param('realm');
    my $faction = $cgi->param('faction');
    my @where;
    my @args;
    if (defined $quality) {
	push @where, 'q.id = ?';
	push @args, $quality;
    }
    my ($faction,$realm) = ($cgi->param('faction'), $cgi->param('realm'));
    my $table;
    if ($realm) {
	die "faction parameter not set with realm\n" unless $faction;
	push @where, 'faction = ?', 'realm = ?';
	push @args, $faction, $realm;
	$table = "server";
    } elsif ($cgi->param('faction')) {
	push @where, 'faction = ?';
	push @args, $faction;
	$table = "faction";
    } else {
	$table = "item";
    }
    return($table,\@where,\@args);
}

sub report_header {
    my($dbh,$cgi,$title) = @_;

    my $realm = $cgi->param('realm');
    my $faction = $cgi->param('faction');
    my $for = "";
    if ($realm) {
	$for = "$realm/$faction";
    } elsif ($faction) {
	$for = $faction;
    }
    $for = escapeHTML(" for $for") if $for;

    my $quality_sth = call_sql($dbh,"quality info", "select * from item_quality order by id");
    my @q;
    while((my $qr = $quality_sth->fetchrow_hashref())) {
	$q[$qr->{id}] = $qr;
    }
    my $qname = "";
    my $quality = $cgi->param('quality');
    $qname = " of quality $q[$quality]{name} " if $quality;
    print "<h1>$title$qname$for</h1>\n";
    my $tmp = $cgi->new();
    $tmp->delete('quality');
    my $myuri = $tmp->self_url;
    print "<p>";
    print qq{[<a href="$myuri">ALL</a>]};
    print "*" unless defined $quality;
    for(my $i=0;$i<@q;$i++) {
	my $qr = $q[$i];
	$tmp->param('quality' => $qr->{id});
	$myuri = $tmp->self_url;
	my $s = "";
	$s = "*" if defined($quality) && $quality == $qr->{id};
	print qq{ [<a href="$myuri"><span style="color:$qr->{color};">$qr->{name}</span></a>]$s};
    }
    print "</p>\n";
    print "<p>";
    my $tmp = $cgi->new();
    $tmp->delete('q');
    $tmp->delete('report');
    my $reporturi = $tmp->self_url;
    print qq{Available reports:<br/>\n[<a href="$reporturi">most common</a>] };
    $tmp->param('report'=>'recent');
    $reporturi = $tmp->self_url;
    print qq{[<a href="$reporturi">most recent</a>] };
    $tmp->param('report'=>'volatile');
    $reporturi = $tmp->self_url;
    print qq{[<a href="$reporturi">most volatile</a>] };
    $tmp->param('report'=>'stable');
    $reporturi = $tmp->self_url;
    print qq{[<a href="$reporturi">most stable</a>]</p>\n};
}

sub report {
    my $cgi = shift;
    my $dbh = shift;
    my $report = shift;

    my $quality = $cgi->param('quality');
    my($table,$where,$args) = table_info($cgi);
    $table = "item_generic_by$table";
    my $where_clause = "";
    my $order_clause = "order by ";
    if ($report eq "recent") {
	$order_clause .= "first_seen desc";
    } elsif ($report eq 'volatile') {
	# XXX This is dangerous. We're allowing for calculating volatility
	# on VERY small numbers of data points. This is statistically
	# unsound, but we have little choice, as there isn't much
	# data for some types of items. Require more data when we look
	# at whole factions, and even more when looking at all factions/servers.
	my $volatility_count = ($faction ? (
	    $realm ? 5 : 20 ) : 50);
	$order_clause .= "volatility desc";
	push @$where, "`count` > $volatility_count";
    } elsif ($report eq 'stable') {
	my $volatility_count = ($faction ? (
	    $realm ? 5 : 20 ) : 50);
	$order_clause .= "volatility";
	push @$where, "`count` > $volatility_count";
    } elsif ($report eq 'common') {
	$order_clause .= "`count` desc";
    } else {
	die "Invalid report type requested: $report\n";
    }
    $where_clause = "where ".join(" and ", @$where) if @$where;
    $sth = call_sql($dbh,"big select", qq{select f.itemid, f.name, date(f.first_seen) as "first_seen", f.ilevel, f.volatility, `count`, q.color from $table f inner join item_quality q on f.quality = q.id $where_clause $order_clause limit 50},@$args);
    display_item($cgi,$sth);
}

sub display_item {
    my $cgi = shift;
    my $sth = shift;
    print qq{<table border=1 cellspacing=0>\n};
    print qq{<tr><th>Item name</th><th>Item Level</th><th>First Seen</th><th>Count</th><th>% Volatility<sup>*</sup></tr>\n};
    my $myuri = URI->new($cgi->self_url);
    while((my $item = $sth->fetchrow_hashref())) {
	if (defined $item) {
	    my $color = $item->{color};
	    $myuri->query_form((map {$_ => $cgi->param($_)} $cgi->param()),i=>$item->{itemid});
	    my $ilevel = sprintf "%3d", $item->{ilevel};
	    my $volatility = sprintf "%7.2f", $item->{volatility}*100;
	    $ilevel =~ s/ /&nbsp;/g;
	    $volatility =~ s/ /&nbsp;/g;
	    print 
		qq{<tr>},
		qq{<td class="namedata"><a href="$myuri"><span style="color: $color;">},
		escapeHTML($item->{name}), qq{</span></a></td>},
		qq{<td class="data">$ilevel</td>},
		qq{<td class="data">$item->{first_seen}</td>},
		qq{<td class="data">$item->{count}</td>},
		qq{<td class="data">$volatility</td>},
		qq{</tr>\n};
	} else {
	    print qq{<tr><td colspan=4>Empty record</td></tr>\n};
	}
    }
    print "</table>\n";
}

sub fetch_item {
    return $itemcache if $itemcache;
    my($dbh,$cgi,$itemid) = @_;
    my $tmp = $cgi->new();
    $tmp->delete('quality');
    my($table,$where,$args) = table_info($tmp);
    my $sth = call_sql($dbh, "item info",
	"select * from item_generic_by$table where itemid = ?",$itemid);
    $itemcache = $sth->fetchrow_hashref();
    unless($itemcache) {
	print "<strong>ERROR: Unknown itemid=$itemid</strong>\n";
	return undef;
    }
    return $itemcache;
}

sub by_item {
    my $cgi = shift;
    my $dbh = shift;
    my $itemid = shift;
    my $plot = shift;
    if ($itemid !~ /^\d+$/) {
	print "<strong>ERROR: Itemid (",escapeHTML($itemid),") is not numeric!</strong>\n";
	return;
    }
    my $item = fetch_item($dbh,$cgi,$itemid);
    if ($plot) {
	plot_item($dbh,$cgi,$itemid,$item);
    } else {
	my $realm = $cgi->param('realm');
	my $faction = $cgi->param('faction');
	my $tmp = $cgi->new();
	$tmp->param(plot=>1);
	my $ploturl = $tmp->self_url;
	$tmp->delete('plot','i');
	my $mainurl = $tmp->self_url;
	my $hname = escapeHTML($item->{name});
	print qq{[<a href="$mainurl">Back</a>]\n};
	print "<h1>$hname",($realm?" on ".escapeHTML($realm):""),
	    ($faction?"/".escapeHTML($faction):""),"</h1>\n";
	my %urls = (
	 Wowhead => "http://www.wowhead.com/?item=".$itemid,
	 Thottbot => "http://thottbot.com/i".$itemid,
	 Armory => "http://www.wowarmory.com/item-info.xml?i=".$itemid);
	print qq{<p>Get details for $hname on: },
	    join(" ", map {qq{<a href="$urls{$_}">$_</a>}}
		qw(Armory Wowhead Thottbot) ),
	    qq{</p>\n};
	print qq{<div class="chartimage"><img src="$ploturl" alt="Plot: $hname"/></div>\n};
    }
}

# We've been called as a sub-request via an img element. This means that
# we have to produce the chart data only.
sub plot_item {
    my ($dbh,$cgi,$itemid,$item) = @_;
    my($table,$where,$args) = table_info($cgi);
    my $realm = $cgi->param('realm');
    my $faction = $cgi->param('faction');
    # We're locked into displaying an image, so even errors must
    # be turned into image data.
    print $cgi->header(-type => 'image/png',
	    -expires => '+10h');
    my $imgfile = "$imgdir/wowitem.$itemid.$realm.$faction.png";
    if ( !-f($imgfile) || -M($imgfile) > $imgage ) {
	# First, get the data
	my $tablename = "price_history_by_$table";
	my $restriction = join " and ", @$where;
	$restriction = "and $restriction" if $restriction;
	$sth=call_sql($dbh,"item history",
		qq{select * from $tablename where itemid = ? $restriction }.
		    qq{order by `day`},
		$itemid,@$args);
	my @results;
	my @histresults;
	my $lastavg;
	my $total = 0;
	my $range_min;
	my $range_max;
	my $start_date;
	my $end_date;
	while ((my $row=$sth->fetchrow_hashref())) {
	    $total += $row->{rolling_50};
	    my $avg = $row->{average};
	    my $max =  $row->{rolling_75}*2;
	    $avg = $max if $avg > $max;
	    $lastavg = $avg;
	    foreach my $pt ($row->{rolling_75},$row->{rolling_50},
			    $row->{rolling_25},$avg) {
		$range_min = $pt if !defined($range_min) || $pt<$range_min;
		$range_max = $pt if !defined($range_max) || $pt>$range_max;
	    }
	    $end_date = $row->{day};
	    $start_date = $end_date unless defined $start_date;
	    push @results,
		 [$row->{day},$row->{rolling_75},$row->{rolling_50},
		 $row->{rolling_25},$avg];
	    push @histresults, [$row->{day}, $row->{auction_count}];
	}
	# Now determine units (gold, silver or copper)
	my $avg = $total/(@results||1);
	my $units;
	my $units_mul;
	if ($avg >= 1) {
	    $units = 'Gold';
	    $units_mul = 1;
	} elsif ($avg >= 0.01) {
	    $units = 'Silver';
	    $units_mul = 100;
	} else {
	    $units = 'Copper';
	    $units_mul = 10_000;
	}
	# Gnuplot input and SVG output go into temp files
	my($fh,$path) = tempfile("wowitemXXXXXX", DIR=>"/tmp");
	my($fh2,$path2) = tempfile("wowitemsvgXXXXXX", DIR=>"/tmp");
	# With bezier smoothing of the weekly rolling percentiles and
	# a daily average scatter plot you get the best visual sense
	# of the shape of the pricing trend.
	my $gpopt = "smooth bezier with lines";
	print $fh
	    qq{set terminal svg\n},
	    qq{set output "$path2"\n},
	    qq{set size 1,1\n},
	    qq{set origin 0,0\n},
	    qq{set multiplot\n},
	    qq{set size 1,0.8\n},
	    qq{set origin 0,0.2\n},
	    qq{set xdata time\n},
	    qq{set timefmt "%Y-%m-%d"\n},
	    qq{set format x "%m/%d"\n},
	    qq{set xrange ["$start_date":"$end_date"]\n},
	    qq{set format y "%4g"\n},
	    qq{set grid\n},
	    qq{set xlabel "Date"\n},
	    qq{set ylabel "$units"\n},
	    qq{set title "$item->{name}\\nWeekly rolling stats"\n};
	if (($range_max - $range_min) * $units_mul < 2) {
	    my $high = int((($range_max * $units_mul) + 10) / 10) * 10;
	    my $low = int(($range_max * $units_mul) / 10) * 10;
	    print $fh qq{set yrange [$low:$high]\n};
	}
	$range_min *= $units_mul;
	$range_max *= $units_mul;
	print $fh
	    qq{plot "-" using 1:2 title "75th percentile" $gpopt lw 2,},
	    qq{ "-" using 1:3 title "50th percentile" $gpopt lw 4,},
	    qq{ "-" using 1:4 title "25th percentile" $gpopt lw 2,},
	    qq{ "-" using 1:5 title "daily average" with points lw 2\n};
	# Use GD to produce simple error images
	if (@results < 3) {
	    my $count = @results;
	    unlink $path;
	    unlink $path2;
	    my $image = GD::Image->new(600,100);
	    my $white = $image->colorAllocate(255,255,255); #background color
		my $black = $image->colorAllocate(  0,  0,  0);
	    my $warning;
	    if ($count == 0) {
		$warning = "No data points in $tablename for this item!";
	    } else {
		$lastavg = gold($lastavg*10000);
		$warning = "Only saw on $count day".($count>1?"s":"").". Average gold=$lastavg";
	    }
	    $image->string(gdMediumBoldFont,20,20,$warning,$black);
	    print $image->png();
	    return;
	}
	for(1..4) {
	    foreach my $result (@results) {
		print $fh " " . join(" ", $result->[0],
			map { $_ * $units_mul} @{$result}[1..$#{$result}]),
		      "\n";
	    }
	    print $fh "e\n";
	}
	print $fh
	    qq{set size 1,0.2\n},
	    qq{set origin 0,0\n},
	    qq{set yrange [0:]\n},
	    qq{set format y "%4g"\n},
	    qq{set xdata time\n},
	    qq{set timefmt "%Y-%m-%d"\n},
	    qq{set format x "%m/%d"\n},
	    qq{set xrange ["$start_date":"$end_date"]\n},
	    qq{unset grid\n},
	    qq{unset xlabel\n},
	    qq{unset title\n},
	    qq{set ylabel "Count"\n},
	    qq{set noxtics\n},
	    qq{plot "-" using 1:2 notitle with imp\n};
	foreach my $result (@histresults) {
	    print $fh " ".join(" ", @$result)."\n";
	}
	print $fh "e\n";
	print $fh "unset multiplot\n";
	close($fh);
	system("gnuplot",$path);
	system("rsvg",$path2,$imgfile);
	unlink $path2;
	#unlink $path;
    }
    copy($imgfile,\*STDOUT);
}

# Turn an amount of copper like 520821 into a string like "52g 8s 21c"
sub gold {
	my $copper = shift;
	my $str = "";
	my $gold = int($copper/10000);
	$str .= $gold . "g " if $gold;
	$copper -= $gold * 10000;
	my $silver = int($copper/100);
	$str .= $silver . "s " if $silver;
	$copper -= $silver * 100;
	if ($copper) {
		$str .= $copper . "c" if $copper;
	} else {
		$str =~ s/ $//;
	}
	return $str;
}

sub call_sql {
  my $dbh = shift;
  my $name = shift;
  my $sql = shift;
  my $sth;
  if (exists $sql_statement_handle_cache{$sql}) {
    $sth = $sql_statement_handle_cache{$sql};
  } else {
    $sth = $sql_statement_handle_cache{$sql} =
      $dbh->prepare($sql);
    die "$0: Cannot parse SQL for $name: $DBI::errstr\n" unless $sth;
  }
  $sth->execute(@_) or
        die "$0: Failed to execute $name: $DBI::errstr\n";
  return $sth;
}

__END__
