#
# A Perl module for fetching Amazon Web Service private keys from a
# secure location (e.g. /etc/)

package aws_s3;

use Exporter;
use base qw(Exporter);

our $config = '/etc/aws_s3.info';

sub fetch {
	my($path) = @_;
	$path = $config unless defined $path;
	open(my $f, "<$path") or die "$path: $!";
	my %data;
	while(<$f>) {
		if (/^\s*(\w+)\s*=\s*(\S+)/) {
			$data{$1} = $2;
		}
	}
	close $f;
	return \%data;
}

1;

__END__

=head1 NAME

aws_s3 - A module for fetching Amazon Web Service keys from a secure location

=head1 SYNOPSIS

	use Net::Amazon::S3;
	use aws_s3;
	my $aws = aws_s3::fetch();
	#use Data::Dumper;
	#die Dumper($aws);
	my $s3 = Net::Amazon::S3->new(
	    {
		aws_access_key_id     => $aws->{aws_access_key_id},
		aws_secret_access_key => $aws->{aws_secret_access_key},
		retry                 => 1,
	    }
	) or die "Cannot connect to S3: $!";

=head1 DESCRIPTION

Provides a single function (C<fetch>) which fetches security key data
from F</etc/aws_s3.info> by default (a parameter can be passed to C<fetch>
to specify a new location).

=head1 AUTHOR

Written in 2008 by Aaron Sherman

(c) 2008 Aaron Sherman, distributed under the same License as Perl
itelsef.

=cut

