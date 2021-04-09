#!/usr/bin/perl

# acgryfact.com.pl - Query fmylife.com and return a result
#
#[20:45:08] <Flash_> !fml
#
# For irssi

use strict;
use Irssi;
use LWP::UserAgent;
use vars qw($VERSION %IRSSI);

$VERSION = '001';
%IRSSI = (
    authors     => 'Flash',
    contact     => 'flash@digdilem.org',
    name        => 'angry',
    description => 'Return stuff from angryfact',
    license     => 'GNU General Public License 3.0' );

sub query_af { # use google instead!
	my ($server,$msg,$nick,$address,$target) = @_;
	my @words = split(/ /,$msg);
	my $newnick;
	if (defined $words[1]) { $newnick = $words[1]; } else { $newnick = $nick; }
	if (lc($words[0]) eq '!af') {
		my $ua = LWP::UserAgent->new;
		$ua->agent("aFlashbot/001 ");
		my $request = HTTP::Request->new(GET => "http://www.angryfacts.com/facts.cgi");
		my $result = $ua->request($request);
		my $content = $result->content;
		#
		# </p><h1>Matthew Garrett is capable of hibernating, but just doesn't want to.</h1>
		$content =~ /p><h1>(.*?)<\/h1>/;
		my $af = $1;
		# Some prep
		$af =~ s/&\#39;/'/g;
		$af =~ s/&quot;/\"/g;
		$af =~ s/&amp;/&/g;
		$af =~ s/<em>//g;
		$af =~ s/<\/em>//g;
		$af =~ s/\\//g;
		# Replace name with nick
		$af =~ s/Matthew Garrett/$newnick/;

		if (!defined $af) { $server->command("/msg $target af: Sorry - pattern match failed."); }
			else
			{ $server->command("/msg $target $af"); }
	} # End, message wasn't for me.
}

Irssi::signal_add('message public','query_af');
Irssi::signal_add('message own_public','query_af');


