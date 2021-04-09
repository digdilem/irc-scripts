#!/usr/bin/perl
###############
# PM-Minder. Responds to PM's with a message.
#
use strict;
# Config
#########
#
my $respond_message = "(Auto) PM Received. If I don't know you, don't expect an answer unless you explain what you want...";
#
# End config.
###############
# Don't edit stuff below here
#
my @nicklist;
Xchat::register( "Flashy's PM-Minder", "v.001", "pmMinder", "" );
Xchat::hook_print( "Private Message to Dialog", "pm_watch"); # Watch for private messages

sub pm_watch { # Called on private messages (PM - NOT CTCP/DCC CHAT)#
	my $nick = $_[0][0];
	if ($nick eq '') { return Xchat::EAT_NONE; }

	my $seenbefore=0;
	foreach(@nicklist) {
		if ($_ eq $nick) { $seenbefore=1; }
		}
	if ($seenbefore == 0) {
		Xchat::command("msg $nick $respond_message");
		push (@nicklist,$nick);
		} else { 
#		Xchat::print("Had PM from $nick before, not showing message"); 
		}
	return Xchat::EAT_NONE;
	}

Xchat::print ("Flash's Pm-Minder loaded");
