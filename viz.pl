#!/usr/bin/perl

# viz.pl - grab a viz top tip!
#
#[20:45:08] <Flash_> !viz
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
    name        => 'viz',
    description => 'Return a viz top tip!',
    license     => 'GNU General Public License 3.0' );

# We have to do this a little weirdly, since viz loads a massive array and picks one at random. That is horrible so we load that into memory and just pick one instead.

my @tips;

sub query_viz { # use google instead!
	my ($server,$msg,$nick,$address,$target) = @_;
	my @words = split(/ /,$msg);
	my $newnick;
	if (defined $words[1]) { $newnick = $words[1]; } else { $newnick = $nick; }
	if (lc($words[0]) eq '!viz') {
		if (scalar (@tips) > 2) { # We already have an array, just pick one at random
			showtip($target,$server);
			return;
			}
		# else grab the full list and stuff it in the array. (Behavior for first run)
		my $ua = LWP::UserAgent->new;
		$ua->agent("aFlashbot/001 ");
		my $request = HTTP::Request->new(GET => "http://www.viz.co.uk/scripts/tips.js");
		my $result = $ua->request($request);
		my $content = $result->content;
		#
		# </p><h1>Matthew Garrett is capable of hibernating, but just doesn't want to.</h1>
		my @lines = split(/\n/,$content);
		print scalar(@lines) . " lines returned from tips.js";
		foreach(@lines) {
			chomp;
			$_ =~ s/\'\,\'/ \- /g;
			$_ =~ s/\\'/\'/g;
			$_ =~ s/^\'//g;
			$_ =~ s/\'$//g;
			$_ =~ s/\'\,$//g;
			push(@tips,$_);
			}
		showtip($target,$server);
	} # End, message wasn't for me.
}

sub showtip {
	my $chan = shift;
	my $server = shift;
	$server->command("/msg $chan ".$tips[rand(scalar(@tips))]);
	}

Irssi::signal_add('message public','query_viz');
Irssi::signal_add('message own_public','query_viz');


