#!/usr/bin/perl
#
# Public translation tool. Gates text to google translations
# Versatile way: "!translate de|en String to translate"  - Convert German to English.
# Easy way: "!german string" to convert German to English. (Apologies for English-centric scripting)
# Also supported: !german !french, !dutch, !chinese, !japanese, !korean, !russian, !portugese, !arabic, !italian and !spanish
#
# Freeware by Flash  - http://digdilem.org
#
# v.002 - Small change to reflect a change in google's html
# v.003 - Added polish
# v.004 - Google changed site, added workaround
#
my $trigger='!translate';
# End user config
my $translate_url = "http://translate.google.com/translate_t";
my $ver = 'i003';
my $title="Flash's Translate";
use LWP::UserAgent;
use URI::Escape;
use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
$VERSION = $ver;
%IRSSI = (
    authors     => 'Flash',
    contact     => 'flash@digdilem.org',
    name        => 'Translate',
    description => 'A useful irc translation tool',
    license     => 'Do what thou wilt, and it harm none',
);
Irssi::signal_add("message public", \&translate);
Irssi::signal_add("message own_public", \&translate);
print("\002Loaded $title $ver\002 !translate fromlang tolang string");
#

sub translate {
    my ($server, $data, $hunter, $mask, $chan) = @_;  #my ($server, $data, $channel) = @_;
	if (!defined $chan) { $chan = $hunter; }
	my @rowr = split(/ /,$data);
	my $itsforme=0;
	my $langs;
	my $text;
	my $trans;
	if ($rowr[0] eq $trigger) {
		$langs = $rowr[1]; # Get calling command
		$trans = join ' ', @rowr[2 .. @rowr];
		$itsforme=1;
		}
	if (lc($rowr[0]) eq '!german') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="de|en";
		}
	if (lc($rowr[0]) eq '!french') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="fr|en";
		}
	if (lc($rowr[0]) eq '!dutch') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="nl|en";
		}
	if (lc($rowr[0]) eq '!chinese') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="zh|en";
		}
	if (lc($rowr[0]) eq '!arabic') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="ar|en";
		}
			if (lc($rowr[0]) eq '!greek') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="el|en";
		}
	if (lc($rowr[0]) eq '!italian') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="it|en";
		}
	if (lc($rowr[0]) eq '!polish') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="pl|en";
		}
	if (lc($rowr[0]) eq '!spanish') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="es|en";
		}
	if (lc($rowr[0]) eq '!russian') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="ru|en";
		}
	if (lc($rowr[0]) eq '!japanese') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="ja|en";
		}
	if (lc($rowr[0]) eq '!portugese') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="pt|en";
		}
	if (lc($rowr[0]) eq '!korean') {
		$trans = join ' ', @rowr[1 .. @rowr];
		$itsforme=1;
		$langs="ko|en";
		}
	if ($itsforme == 0) { return; } # I don't recognise any of this.

	chop($trans); # remove trailing space
	if (($langs eq '') or ($trans eq '')) {
		$server->command("msg $chan Usage: $trigger FromLanguage ToLanguage Word or Phrase to translate");
		return;
		}

		my $ua = new LWP::UserAgent;
		my $req = new HTTP::Request POST => 'http://translate.google.com/translate_t';
		$ua->agent("Translate/1.0");

		$req->content_type('application/x-www-form-urlencoded');
		my $text = "text=" . uri_escape($trans);
		my $options = "hl=en&ie=UTF8";

#http://translate.google.co.uk/translate_t?hl=&ie=UTF-8&text=porko+dio+mamma+mia&sl=it&tl=en#

#		$req->content($text . "&langpair=" . uri_escape($langs) . "&" . $options);
		# Google 2010 workround - now requiresd sl=en tl=fr source/to
		my ($sl,$tl) = split(/\|/,$langs);
		$req->content($text . "&sl=$sl&tl=$tl" . "&" . $options);

#print "Sent: ".$text . "&sl=$sl&tl=$tl" . "&" . $options;

		my $rv;
		my $res = $ua->request($req);
#		my $page = $res->content;
#print "Result: $res->content\n";
		if ($res->is_success) {
#			if( $res->content =~ /result_box dir="ltr">(.*?)<\/div>/ ) {
			if( $res->content =~ /input type=hidden name=gtrans value="(.*?)"/ ) {
				# <input type=hidden name=gtrans value="Bonjour Monsieur ou Madame">
			$rv = $1;
			$rv =~ s/\\ /\\\n/g
			}
		} else { $server->command("msg $chan  Translation failed"); return; }

		$rv =~ s/&amp;/&/g;
		$rv =~ s/&#39;/'/g;
		$rv =~ s/&quot;/"/g;


		$server->command("msg $chan  Translation ($langs): ". $rv);
		return;
}
