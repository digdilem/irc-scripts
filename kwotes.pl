#!/usr/bin/perl
#
# bash.org - except it uses kwotes. faster, better, same content (although numbers are different)
# Simply type "!bash" and it returns a random kwote from opendonor.org. "!bash NUMBER" returns kwote #NUMBER
use strict;
use LWP::UserAgent;

# Config stuff
my $max_lines=5; # Specified quotes longer than this are refused. Random ones get picked again.
my $opendoner_trigger = '!bash';
my $use_colour=0; # Whether to use bold or not. 

# Firmcoded, shouldn't need to change unless opendoner.org does
my $version='001';
Xchat::register( "Flashy's opendoner.org", $version, "opendoner.org", "" );
Xchat::hook_print('Channel Message', "opendoner_watch");
Xchat::hook_print('Your Message', "opendoner_watch"); 
Xchat::print "Started: Flash's opendoner.org fetcher $version.";
my @harry; # Global array containing quote.
my $number; # Number of quote.

sub opendoner_watch {
	$_[0][1] =~ s/\s+/ /g; # Remove multiple spaces	
	my @rowr = split(/ /,$_[0][1]);
	my $was_random=0;
	if (lc($rowr[0]) eq $opendoner_trigger) { 
		if (defined $rowr[1]) {
			if ($rowr[1] == 0) { 
				if ((lc($rowr[1]) eq 'info') or (lc($rowr[1]) eq 'help')) {
					fetch_info();
					return Xchat::EAT_NONE;
					} else { 
					Xchat::command("say '$rowr[1]' isn't a number!"); 
					return Xchat::EAT_NONE; 
				}
			}
			fetch_quote($rowr[1]);
			} else { fetch_quote('random'); $was_random=1; }		
		}
}

sub fetch_quote {
	$number = shift;	
	my $was_random=0;
	my $url;
	if ($number == 'random') { $url = "http://www.opendonor.org/kwotes.pl?action=list&o=random&mr=1"; $was_random=1;}
		else { $url="http://www.opendonor.org/kwotes.pl?action=show&id=$number"; }  # fixed
	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(GET => $url);
	my $output = $ua->request($req)->as_string;
	
	if ($number == 'random') { 
		$output =~ m/action=show&amp;id=(\d+)\"/; 
		$number=$1; 
		} 
	$output =~ s/[\n\r]+/ /g; # Remove \n\r
#	$output =~ m/<h1 id=\"title\">(.*)<\/h1>/;  # Grabs cute motto, but not doing anything with it yet
#	my $motto=$1;

	$output =~ m/<p>(.*?)\<\/p>/m; # works for single line quotes only
	my $result = $1;
	$result =~ s/\s+/ /g; # Remove multiple spaces
	$result =~ s/&lt;/</g; # Re-add quotes
	$result =~ s/&gt;/>/g;
	$result =~ s/&quot;/\"/g;
	$result =~ s/&nbsp;//g;
	$result =~ s/^\s+//; # Remove leading whitespace
	$result =~ s/\\'/'/g; # Change escaped ''s

	@harry = split (/<br \/>/,$result); #(/ /,$kos_line);
	my $lincnt = scalar(@harry);

	if ($lincnt > $max_lines) { 
		if ($was_random == 1) { fetch_quote('random'); return Xchat::EAT_NONE;  } else { Xchat::command("say Sorry, kwote $number contains $lincnt lines - too many!"); return Xchat::EAT_NONE; }
		}
	print_quote();
}

sub fetch_info { # Get some info about opendonor
	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(GET => 'http://www.opendonor.org/');
	my $output = $ua->request($req)->as_string;
	
	$output =~ m/(\d+) Live Kwotes/m;
	my $quotecount = $1;
	Xchat::command("say http://www.opendonor.org/ contains $quotecount Kwotes");
	}

sub print_quote { 	
	foreach(@harry) { 
		if (length > 3) {	
			if ($use_colour) { Xchat::command("say \002$number\002: $_"); } else { Xchat::command("say $number: $_"); }				
			}
		}
	}