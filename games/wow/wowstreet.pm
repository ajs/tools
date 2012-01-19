#!/usr/bin/perl

package wowstreet;

use POSIX;
use DBI;
use IO::File;
use IO::Handle;
use List::Util qw(sum);
use Date::Parse qw(str2time);
use File::Copy;
use File::Temp qw(tempfile);
use GD;
use Sys::Hostname qw(hostname);
use Apache2::Const qw(OK DECLINED FORBIDDEN REDIRECT SERVER_ERROR);
use Apache2::RequestUtil;
use Apache2::ServerUtil;
use Apache2::RequestRec;
use CGI qw(-compile escapeHTML);
use CGI::Carp qw(fatalsToBrowser);
use URI;
use URI::Escape;
use Template;

use strict;

# XXX temp
our $faction;
our $realm;

our $ttk_config = {
    #INTERPOLATE  => 1,               # expand "$var" in plain text
    #POST_CHOMP   => 1,               # cleanup whitespace
    INCLUDE_PATH => '/var/www/html/wowstreet/include',
};
our $imgdir = "/var/www/html/wowstreet/cached_images";
our $imgage = 1; # Store cached images for 1 day
# Google Analytics urchin tracker
our $google_uacct_wowstreet = "UA-2739280-3";
our $google_uacct_normal = "UA-2739280-1";
our $google_ad_client = "pub-1518182262871008";
our $google_ad_slot_wowstreet = "5123321365";
our $google_ad_slot_normal = "1259497162";
our $google_ad_width = 120;
our $google_ad_height = 600;
our %google_data = (
	google_ad_client => "pub-1518182262871008",
	google_ad_width => 120,
	google_ad_height => 600
	);

our $database = 'wowitems';
our $db_driver = 'mysql';
our $db_host = 'localhost';
our $db_user = 'root';
our $db_pass = undef;
our %sql_statement_handle_cache;
our $dsn = "DBI:$db_driver:database=$database;host=$db_host";

sub handler {
    my $r = shift; # Apache request record
    my $cgi = CGI->new();
    my $fail = sub { $r->log_error(join(" ",@_)); return SERVER_ERROR };
    my $host = $cgi->virtual_host() || $cgi->server_name() || hostname();
    return $fail->("Cannot find hostname") unless $host;
    my %vars = ( %google_data );
    if ( $host =~ /wowstreet/i ) {
	$vars{google_uacct} = $google_uacct_wowstreet;
	$vars{google_ad_slot} = $google_ad_slot_wowstreet;
    } else {
	$vars{google_uacct} = $google_uacct_normal;
	$vars{google_ad_slot} = $google_ad_slot_normal;
    }
    my $template = Template->new($ttk_config) or
	return $fail->($Template::ERROR);

    # Site down message. When it exists, we always return it.
    if (-f "/var/www/html/wowstreet/wowstreet.down") {
	my $dh = IO::File->new("/var/www/html/wowstreet/wowstreet.down");
	$dh->read($vars{downtime_message},1024*1024);
	undef $dh;
	$r->content_type("text/html");
	$template->process("wowstreet_down.tt2", \%vars, $r) or
	    return $fail->("processing ".$template->error);
	return OK;
    }
    my $status = eval {
	# put "PerlModule Apache::DBI" in the config to enforce conn pooling
	my $dbh = DBI->connect($dsn,$db_user,$db_pass) or
	    return $fail->("$0:$dsn: Failed: $DBI::errstr");

	my $plot = $cgi->param('plot');
	if ($plot) {
	    return plot_handler($r,$template,$cgi,$dbh);
	}

	$r->assbackwards();
	$r->print($cgi->header(-type => 'text/html',
		    -charset => 'utf-8',
		    -expires => '+10h'));

	my $sth;
	my $row;

	my $itemid = $vars{itemid} = $cgi->param('i');
	my $item;
	$item = $vars{item} = eval { fetch_item($dbh,$cgi,$itemid) } if $itemid;
	return generate_error($r,$cgi,"not found",$@) if $@;
	my $realm = $vars{realm} = $cgi->param('realm');
	my $faction = $vars{faction} = $cgi->param('faction');
	my $report = $cgi->param('report') || 'common';
	$vars{report} = $report;

	$vars{homeurl} = $cgi->url();

	if ($item) {
	    $vars{context} = escapeHTML(": $item->{name}");
	}
	if ($faction) {
	    my $context = escapeHTML($faction);
	    if ($realm) {
		$context = escapeHTML($realm) . "/$context";
	    }
	    $context = " for $context";
	    $vars{context} .= $context;
	}
	if (!$item && $cgi->param('report') eq 'search') {
	    $vars{context} = escapeHTML(": ".$cgi->param('q'));
	}
	my $tmp = $cgi->new();
	$tmp->delete('report');
	$vars{form_start} =
	    $tmp->start_form(-method => "GET",
			     -action => $tmp->url(-relative => 1));
	$vars{searchbox} = $tmp->hidden(-name=>"report",-value=>"search") .
	    $tmp->textfield(-name=>"q");
	$vars{form_end} = $tmp->end_form();

	$sth = call_sql($dbh,"count1","select count(*) from item_generic_byitem");
	($vars{item_count}) = $sth->fetchrow_array();
	$sth = call_sql($dbh,"count2","select `count` from auction_metadata");
	($vars{auction_count}) = $sth->fetchrow_array();

	$sth = call_sql($dbh,"realm info",
	    q{select realm, faction, auction_count,
		date(last_scanned) as 'last_scanned'
	      from realm_faction_summary order by realm, faction desc});
	$tmp = $cgi->new();
	$tmp->delete('realm');
	$tmp->delete('faction');
	$vars{all_url} = $tmp->self_url;
	$tmp->param('faction'=>'Horde');
	$vars{horde_url} = $tmp->self_url;
	$tmp->param('faction'=>'Alliance');
	$vars{alliance_url} = $tmp->self_url;
	while((my $serverrow = $sth->fetchrow_hashref)) {
	    $tmp->param('faction'=>$serverrow->{faction});
	    $tmp->param('realm'=>$serverrow->{realm});
	    $serverrow->{server_url} = $tmp->self_url;
	    push @{$vars{server_list}}, $serverrow;
	}    my $for = "";

	get_market_index($cgi,$dbh,\%vars);
	if ($itemid) {
	    my($table,$where,$args) = table_info($cgi);
	    if (@$where) {
		$where = "and " . join(" and ", @$where);
	    } else {
		$where = "";
	    }
	    my $sth = call_sql($dbh, "item search",qq{select * from item_generic_by$table where itemid = ? $where limit 1}, $itemid, @$args);
	    display_item($cgi,\%vars,$sth);
	    by_item($cgi,$dbh,\%vars,$itemid);
	    $template->process("wowstreet_item.tt2", \%vars, $r) or
		return $fail->("processing ".$template->error);
	} elsif ($report eq 'search') {
	    my $query = $cgi->param('q');
	    $vars{title} = "Search results";
	    my $search_q = "\%$query\%";
	    report_header($dbh,$cgi,\%vars);
	    my($table,$where,$args) = table_info($cgi);
	    if (@$where) {
		$where = "and " . join(" and ", @$where);
	    } else {
		$where = "";
	    }
	    my $sth = call_sql($dbh, "item search",
		    qq{select t.*, q.color from item_generic_by$table t inner join item_quality q on t.quality = q.id where t.name like ? $where order by `count` desc limit 50},$search_q, @$args);
	    display_item($cgi,\%vars,$sth);
	    $template->process("wowstreet_main.tt2", \%vars, $r) or
		return $fail->("processing ".$template->error);
	} elsif ($report eq 'badge') {
	    $template->process("wowstreet_badge.tt2", \%vars, $r) or
		return $fail->("processing ".$template->error);
	} else {
	    $vars{title} = "Most $report items";
	    report_header($dbh,$cgi,\%vars);
	    report($cgi,$dbh,\%vars,$report);
	    $template->process("wowstreet_main.tt2", \%vars, $r) or
		return $fail->("processing ".$template->error);
	}

	return OK;
    };
    if ($@) {
	$r->log_error($@);
	return SERVER_ERROR;
    }
    return $status;
}

sub get_market_index {
    my($cgi,$dbh,$vars) = @_;
    return;
    my($table,$where,$args) = table_info($cgi);
    my $whereclause = (@$where?" and ".join(" and ",@$where):"");
    my $sth =  call_sql($dbh,"get_market_index max day",
	qq{ select max(day) from market_index_components_by_$table
	    where day is not null $whereclause }, @$args );
    (my $day) = $sth->fetchrow_array();
    $sth = call_sql($dbh,"get_market_index",
	qq{select sum(value*shares) from market_index_components_by_$table
	where day = ? $whereclause },
	$day, @$args);
    ($vars->{market_index_current}) = $sth->fetchrow_array();
    $vars->{market_index_current} = sprintf "%.1f", $vars->{market_index_current};
    my $sth =  call_sql($dbh,"get_market_index max day",
	qq{ select max(day) from market_index_components_by_$table
	    where day < ? $whereclause }, $day, @$args );
    ($day) = $sth->fetchrow_array();
    $sth = call_sql($dbh,"get_market_index",
	qq{select sum(value*shares) from market_index_components_by_$table
	where day = ? $whereclause },
	$day, @$args);
    ($vars->{market_index_previous}) = $sth->fetchrow_array();
    $vars->{market_index_previous} = sprintf "%.1f", $vars->{market_index_previous};
}

sub generate_error {
    my $r = shift;
    my $cgi = shift;
    my $short = shift;
    my $msg = shift;
    my $rv = $cgi->param('rv');
    if ($cgi->param('plot')) {
	my ($w,$h) = get_width_height($cgi);
	my $image = GD::Image->new($w,$h);
	my @rgb_white = (255,255,255);
	my @rgb_black = (  0,  0,  0);
	(@rgb_white,@rgb_black) = (@rgb_black,@rgb_white) if $rv;
	my $white = $image->colorAllocate(@rgb_white); #background color
	my $black = $image->colorAllocate(@rgb_black);
	$image->string(gdMediumBoldFont,20,20,($w<300?$short:$msg),$black);
	$r->print($image->png());
	return OK;
    } else {
	# Just let mod CGI worry about it
	die $@;
    }
}

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
	#return $fail->("faction parameter not set with realm"); unless $faction;
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
    my($dbh,$cgi,$vars) = @_;

    my $realm = $vars->{realm};
    my $faction = $vars->{faction};

    my $quality_sth = call_sql($dbh,"quality info", "select * from item_quality order by id");
    my @q;
    while((my $qr = $quality_sth->fetchrow_hashref())) {
	$q[$qr->{id}] = $qr;
    }
    my $qname = "";
    my $quality = $cgi->param('quality');
    if ($quality) {
	$vars->{context} .= " of quality $q[$quality]{name}";
    }
    my $tmp = $cgi->new();
    $tmp->delete('quality');
    my $myuri = $tmp->self_url;
    my @qs;
    my $allstar = ($quality ? "" : "*");
    push @qs, { url=>$myuri, color=>"black", name=>"ALL", star=>$allstar };
    for(my $i=0;$i<@q;$i++) {
	my $qr = $q[$i];
	$tmp->param('quality' => $qr->{id});
	$myuri = $tmp->self_url;
	my $s = "";
	$s = "*" if defined($quality) && $quality == $qr->{id};
	push @qs, { url=>$myuri, %$qr, star=>$s };
    }
    $vars->{quality_links} = \@qs;
    $tmp = $cgi->new();
    $tmp->delete('q');
    $tmp->delete('report');
    my $reporturi = $tmp->self_url;
    my @rpt;
    push @rpt, { url=> $reporturi, name => "common" };
    $tmp->param('report'=>'recent');
    $reporturi = $tmp->self_url;
    push @rpt, { url => $reporturi, name => "recent" };
    $tmp->param('report'=>'expensive');
    $reporturi = $tmp->self_url;
    push @rpt, { url => $reporturi, name => "expensive" };
    $tmp->param('report'=>'volatile');
    $reporturi = $tmp->self_url;
    push @rpt, { url => $reporturi, name => "volatile" };
    $tmp->param('report'=>'stable');
    $reporturi = $tmp->self_url;
    push @rpt, { url => $reporturi, name => "stable" };
    $vars->{report_types} = \@rpt;
}

sub report {
    my $cgi = shift;
    my $dbh = shift;
    my $vars = shift;
    my $report = shift;

    my $quality = $cgi->param('quality');
    my($table,$where,$args) = table_info($cgi);
    $table = "item_generic_by$table";
    my $where_clause = "";
    my $order_clause = "order by ";
    if ($report eq "recent") {
	$order_clause .= "first_seen desc";
    } elsif ($report eq 'expensive') {
	$order_clause .= "price desc";
	push @$where, "`count` > 20";
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
    my $sth = call_sql($dbh,"big select",
	qq{
	    select f.itemid, f.name, date(f.first_seen) as "first_seen",
		f.ilevel, f.volatility, f.price, `count`, f.quality, q.color
	    from $table f
		inner join item_quality q on f.quality = q.id
	    $where_clause $order_clause limit 50},@$args);
    display_item($cgi,$vars,$sth);
}

sub display_item {
    my $cgi = shift;
    my $vars = shift;
    my $sth = shift;
    my $tmp = $cgi->new();
    $tmp->delete('q');
    my @item_list;
    while((my $item = $sth->fetchrow_hashref())) {
	if (defined $item) {
	    my $color = $item->{color};
	    $tmp->param('i',$item->{itemid});
	    my $myuri = $tmp->self_url;
	    my $ilevel = sprintf "%3d", $item->{ilevel};
	    my $volatility = sprintf "%7.2f", $item->{volatility} * 100;
	    my @price = gold($item->{price}*10_000,1);
	    $ilevel =~ s/ /&nbsp;/g;
	    $volatility =~ s/ /&nbsp;/g;
	    push @item_list, {
		%{$item}, url => $myuri, color=>$color, ilevel => $ilevel,
		volatility => $volatility, price=>[@price] };
	}
    }
    $vars->{item_list} = \@item_list;
}

sub fetch_item {
    my($dbh,$cgi,$itemid) = @_;
    my $tmp = $cgi->new();
    $tmp->delete('quality');
    my($table,$where,$args) = table_info($tmp);
    my $sth = call_sql($dbh, "item info",
	"select * from item_generic_by$table where itemid = ?",$itemid);
    my $item = $sth->fetchrow_hashref();
    unless($item) {
	die "ERROR: Unknown itemid=$itemid\n";
    }
    return $item;
}

sub by_item {
    my($cgi,$dbh,$vars,$itemid) = @_;

    if ($itemid !~ /^\d+$/) {
	die "Itemid (".escapeHTML($itemid).") is not numeric!\n";
	return;
    }
    my $item = $vars->{item};
    my $realm = $vars->{realm};
    my $faction = $vars->{faction};
    my $tmp = $cgi->new();
    $tmp->param(plot=>1);
    $vars->{imageurl} = $tmp->self_url;
    # Gnuplot defaults
    $vars->{imagewidth} = 640;
    $vars->{imageheight} = 480;
    $tmp->delete('plot','i');
    $vars->{backurl} = $tmp->self_url;
    $vars->{external_list} = [
	 { name=>"Armory", url=>"http://www.wowarmory.com/item-info.xml?i=".$itemid },
	 { name=>"Wowhead", url=>"http://www.wowhead.com/?item=".$itemid },
	 { name=>"Thottbot", url=>"http://thottbot.com/i".$itemid },
    ];
}

# We've been called as a sub-request via an img element. This means that
# we have to produce the chart data only.
sub plot_handler {
    my ($r,$template,$cgi,$dbh) = @_;
    my($table,$where,$args) = table_info($cgi);
    my $realm = $cgi->param('realm');
    my $faction = $cgi->param('faction');
    my $vars = {};
    my ($w,$h) = get_width_height($cgi);
    @{$vars}{qw(image_width image_height)} = ($w,$h);
    $vars->{reverse_video} = $cgi->param('rv');
    my $rv = ($vars->{reverse_video} ? 1 : 0);
    my $itemid = $vars->{itemid} = $cgi->param('i');
    my $item;
    $item = $vars->{item} = eval {fetch_item($dbh,$cgi,$itemid)} if $itemid;
    return generate_error($r,$cgi,"not found",$@) if $@;
    # We're locked into displaying an image, so even errors must
    # be turned into image data.
    $r->assbackwards();
    $r->print($cgi->header(-type => 'image/png',
		-expires => '+10h'));
    my $imgfile = "$imgdir/wowitem.$itemid.$realm.$faction.$w.$h.$rv.png";
    if ( !-f($imgfile) || -M($imgfile) > $imgage ) {
	# First, get the data
	my $tablename = "price_history_by_$table";
	my $restriction = join " and ", @$where;
	$restriction = "and $restriction" if $restriction;
	my $sth=call_sql($dbh,"item history",
		qq{select * from $tablename where itemid = ? $restriction }.
		    qq{order by `day`},
		$itemid,@$args);
	my @results;
	my @histresults;
	my @avgresults;
	my $lastavg;
	my $total = 0;
	my $range_min;
	my $range_max;
	my $start_date;
	my $end_date;
	my $current;
	while ((my $row=$sth->fetchrow_hashref())) {
	    $total += $row->{rolling_50};
	    my $avg = $row->{average};
	    my $max =  $row->{rolling_75}*2;
	    $avg = $max if $avg > $max;
	    $lastavg = $avg;
	    foreach my $pt ($row->{rolling_75},$row->{rolling_50},
			    $row->{rolling_25},$avg) {
		next unless $pt;
		$range_min = $pt if !defined($range_min) || $pt<$range_min;
		$range_max = $pt if !defined($range_max) || $pt>$range_max;
	    }
	    $end_date = $row->{day};
	    $start_date = $end_date unless defined $start_date;
	    #$vars->{debug} .= ".";
	    push @results,
		 [$row->{day},$row->{rolling_75},$row->{rolling_50},
		 $row->{rolling_25}];
	    push @avgresults, [$row->{day}, $avg] if $row->{auction_count};
	    push @histresults, [$row->{day}, $row->{auction_count}];
	    $current = $row;
	}
	$vars->{start_date} = $start_date;
	$vars->{end_date} = $end_date;
	$vars->{current_pricing} = $current;
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
	$vars->{units} = $units;
	# Gnuplot input and SVG output go into temp files
	my($fh,$path) = tempfile("wowitemXXXXXX", DIR=>"/tmp");
	my($fh2,$path2) = tempfile("wowitemsvgXXXXXX", DIR=>"/tmp");
	$vars->{svg_path} = $path2;
	if (($range_max - $range_min) * $units_mul < 2) {
	    my $high = int((($range_max * $units_mul) + 10) / 10) * 10;
	    my $low = int(($range_max * $units_mul) / 10) * 10;
	    push @{$vars->{gp_extra}}, qq{set yrange [$low:$high]};
	}
	$range_min *= $units_mul;
	$range_max *= $units_mul;
	# Use GD to produce simple error images
	if (@results < 3) {
	    my $count = @results;
	    unlink $path;
	    unlink $path2;
	    my $warning;
	    my $shortwarning;
	    if ($count == 0) {
		$shortwarning = "no data";
		$warning = "No data points in $tablename for this item!";
	    } else {
		my $lastavg_g = gold($lastavg*10000);
		$warning = "Only saw on $count day".($count>1?"s":"").". Average gold=$lastavg_g ($lastavg) $vars->{debug}";
		$shortwarning = $lastavg_g;
	    }
	    return generate_error($r,$cgi,$shortwarning,$warning);
	}
	foreach my $rset (((\@results) x 3)) {
	    push @{$vars->{prices_list}}, my $a = [];
	    foreach my $result (@$rset) {
		push @$a, [$result->[0],
		     map { $_ * $units_mul} @{$result}[1..$#{$result}]];
	    }
	}
	$vars->{count_list} = \@histresults;
	$template->process("item_gnuplot.tt2", $vars, $fh) or
	    die "Cannot process template for gnuplot: ".$template->error;
	system("gnuplot",$path);
	system("rsvg",$path2,$imgfile);
	unlink $path2;
	unlink $path;
    }
    $r->sendfile($imgfile);
}

sub get_width_height {
    my $cgi = shift;
    my $w = $cgi->param('w')+0;
    my $h = $cgi->param('h')+0;
    $h = int($w * 0.75) if $w && !$h;
    $w = int($h * 1.33) if $h && !$w;
    $w = 640 unless $w > 10 && $w <= 1024;
    $h = 480 unless $h > 10 && $w <= 768;
    return ($w,$h);
}

# Turn an amount of copper like 520821 into a string like "52g 8s 21c"
sub gold {
	my $copper = shift;
	my $list = shift;
	my @amt;
	$copper = int($copper + 0.5);
	my $gold = int($copper/10000);
	if ($gold) {
	    my $gold_s = $gold;
	    $gold_s =~ s/ /&nbsp;/g if $list;
	    push @amt, { ammount => $gold_s, type=> "gold" };
	}
	$copper -= $gold * 10000;
	my $silver = int($copper/100);
	if ($silver) {
	    my $silver_s = $silver;
	    $silver_s =~ s/ /&nbsp;/g if $list;
	    push @amt, { ammount => $silver_s, type=> "silver" };
	}
	$copper -= $silver * 100;
	if ($copper) {
	    my $copper_s = $copper;
	    $copper_s =~ s/ /&nbsp;/g if $list;
	    push @amt, { ammount => $copper_s, type=> "copper" };
	}
	return @amt if $list;
	return join " ", map { $_->{ammount} . substr($_->{type},0,1) } @amt;
}

sub call_sql {
  my $dbh = shift;
  my $name = shift;
  my $sql = shift;
  my $sth = $dbh->prepare($sql);
  die "$0: Cannot parse SQL for $name: $DBI::errstr\n" unless $sth;
  $sth->execute(@_) or
        die "$0: Failed to execute $name: $DBI::errstr\n";
  return $sth;
}

__END__
