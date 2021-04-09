#!/usr/bin/perl
#
# Quote script. "!addquote CONTENT" and "!delquote CONTENT" and !sendquote from control channel. !quote from any channel to respond with a randomly chosen line. 
#
# 0.3 - Fixed case sensitivity to the !Quote command, Search quotes !quote searchstring
# 0.4 - Fix problems handling colours, remove multiple spaces. Add !quote support for admin chan too
#
use strict;

my $qver="0.4";
my $quotefile="irc_quotes.txt"; # Text file, one quote per line
my $control_chan = "#privchan"; #Where  !addquote and !delquote work from
my $response_chan = "#pubchan"; #where !quote works from (Can't hav eit global)

my $trigger = "!quote";  # Rename if clashes. this is the public trigger

Xchat::register( "Flashy's Quote Script", "$qver", "Quotes", "" );
Xchat::hook_print('Channel Message', "quoter");
Xchat::command("msg $control_chan Loaded Flashy's Quoter Script v.$qver (!quote, !addquote and !sendquote");

sub quoter {
	my $nick = $_[0][0];             
	my @word = split(/ /,$_[0][1]);
	my $curchan = lc(Xchat::get_info( 'channel' ));	
	if ($curchan eq $control_chan) { # Look for commands
		if (lc($word[0]) eq '!addquote') { # Add a new quote
			my $qt = join ' ', @word[1 .. @word];
				chop($qt);				
				if ($qt eq undef) {Xchat::command("say No quote given!"); return Xchat::EAT_NONE; }
				Xchat::strip_code ($qt); # remove colours and bolds
				$qt =~ s/\s+/ /g; # Remove multiple spaces				
				open(QF,">>$quotefile") or Xchat::command("say ERROR! Can't append to quotefile $quotefile"); 
				print(QF "$qt\n");
				close(QF);
				Xchat::command("say Added quote \"$qt\".");
				} # End addquote
			if (lc($word[0]) eq '!delquote') {
			my $qt = join ' ', @word[1 ..  @word];
			chop($qt);
			my $found=0;
			my @tmparr;			
			open(QF,"<$quotefile") or Xchat::command("say ERROR! Cannot open $quotefile for read");
			while (<QF>) { 
				chomp;
				if ($_ eq $qt) {
					$found = 1;
				} else { push(@tmparr,$_); }
			}
			close (QF);
			if ($found eq 1) {
				open (QT,">$quotefile");
				foreach(@tmparr) {
					print(QT "$_\n");
					}
				close(QT);
				Xchat::command("say Deleted quote \"$qt\" ". scalar @tmparr . " Quotes remaining in file.");
				return Xchat::EAT_NONE;
			} else {
				Xchat::command("say Can't find quote \"$qt\".");
				return Xchat::EAT_NONE;
				}	
			} # End delquote
		if (lc($word[0]) eq '!sendquote') { # send quote via dcc
			Xchat::command("say Sending quotefile to $nick");
			Xchat::command("send $nick $quotefile");
			return Xchat::EAT_NONE;
			} # End sendquote
		} # End control-chan stuff

	if (($curchan eq $response_chan) or ($curchan eq $control_chan)) { # Look for !quote
		if (lc($word[0]) eq $trigger) {
			my $response;
			open (IN, "<$quotefile") or ( $response .= "I appear to be broken, I can't find any scripts!");
			if ($word[1] ne undef) { # Pick specific match				
				my $trigger = join ' ', @word[1 ..  @word-1];
				my $fnd=0;
				while (<IN>) {
#					Xchat::print("1:$trigger-2:$_");
					if ($_ =~ /$trigger/i)  {
						$response = $_;
						$fnd=1;
						}
					}
				if ($fnd == 0) { $response = "Can't find a quote containing \"$trigger\""; }
				} else { # Pick random
				rand($.) < 1 && ($response = $_) while <IN>; # Pick random line
				}
			close(IN);
			chomp($response);
			Xchat::strip_code ($response); # remove colours and bolds
			$response =~ s/\s+/ /g; # Remove multiple spaces				
			my @output = split(/:: /,$response);
			foreach(@output) { Xchat::command("say $_"); }
			}
		}
	# All-channel stuff from here on
	return Xchat::EAT_NONE;
	}