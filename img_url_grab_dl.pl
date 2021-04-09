#!/usr/bin/perl

#Xchat Perl script
#Automatically save images that are linked in a channel to [xchat-dir]/imgsave
#You may need to create this directory first
#The bad_domains array may be used to exclude image URLs with domains matching any of a list of patterns. Set to an empty list to disable.
#Written by Jonathan Rennison (j.g.rennison@gmail.com)
#2012-02-18
#Loosely based on http://pastebin.com/QE24QJ8p by Derek Meister

use strict;
use warnings;
use threads;
require LWP::Simple;

my ($script_name, $script_version, $script_description) =
    ("Image URL Auto Grabber and Downloader", "0.1", "Automatically grabs and downloads image URLs");
Xchat::register($script_name, $script_version, $script_description);

#Xchat::print("Starting $script_name v$script_version\r\n");	#Uncomment this for a startup message

Xchat::hook_print($_, \&hookfn) foreach('Channel Message', 'Channel Msg Hilight', 'Channel Action', 'Channel Action Hilight');

my @bad_domains = ();	#array of regexs for domain name exclusion
#my @bad_domains = (qr/^(?:.*\.)?example\.com$/, qr/\bbannedword\b/, qr/^name\./);		#example, exclude: example.com and subdomains, domains containing the term bannedword, and domains starting with name.

sub hookfn {
	my ($nick, $text, $modechar) = @{$_[0]};
	my @words=split /\s+/,$text;
	foreach (@words) {
		if ($_ =~ m{^(?:https?://)?([a-zA-Z0-9.-]+\.[a-zA-Z]+)/(?:.*)\.(?:jpe?g|png|gif)$}i) {
			foreach my $re (@bad_domains) {
				if($1 =~ $re) {
					return Xchat::EAT_NONE;
				}
			}
			if ( $_ !~ m{^https?://} ) { $_="http://".$_;}
			my $fn = Xchat::get_info("xchatdir") . "/imgsave/" . s/[^\w!., -#]/_/gr;
			if($_ =~ m{^https://}) {
				my $rc = LWP::Simple::mirror($_, $fn);	#LWP SSL is not thread safe
			}
			else {
				my $th = threads->create(\&dlfunc, $_, $fn);
				$th->detach();
			}
			#Xchat::print("IMG DL\t".$_." -> ".$fn, Xchat::get_info("channel"), Xchat::get_info("server"));	#Uncomment this to be notified of image downloads
		}
	}
	return Xchat::EAT_NONE;
}

sub dlfunc {
	my $rc = LWP::Simple::mirror($_[0],$_[1]);
}
