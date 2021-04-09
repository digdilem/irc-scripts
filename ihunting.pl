#!/usr/bin/perl
#
# Flashy's bloodsports. http://digdilem.org/ - "Because thems trouts ain't gonna catch themselves!"
# (Credit to the original Eggdrop TCL script by Nerfbendr)
# (Credit to my own Xchat version, from which this irssi one is converted)
#
# Adds silly !hunt, !fish and !trophy public triggers  (!trophy takes optional number to show - eg !trophy 10, defaults to 5 i none set)
# Also !newmonth will clean out the trophy cupboard. (Only if you do it, or the nick in $owner_nick)
#
# v.003 - Store nicks of winners and give some stats
# v.002 - Added random "MEGAKILL" type thing.
#	Removed /msg support (spammy)
#	Added automatic reset ($automatic_reset=VAL)
#	Added some colour
#	Added some new hunts
# v.001i - Rewritten for irssi
# v.001 - First write for Xchat
#
# Optional Configuration (Will work fine without changing these, but you can if you like)
my $owner_nick='Flash_'; # Your nick - you can only reset the scores remotely if you use this nick.
my $scale = 'kg'; # Say here whether you want to measure weights in lb or kg.
my $catch_percent=90; # How often you catch or shoot something.
my $megakill_chance = 5; # What percentage should "Megakill" happen, AFTER they've already caught something? 0 to disable. Megakill gives an extra 10 to a catch, making it more likely to win.
my $megakill_bonus = 30; # How many extra SCORE should I give for a megakill?
my $automatic_reset = 150; # When one weight reaches this, reset everything. Set unfeasibly high to disable
my $trophy_cabinet = "trophies.txt"; # File to keep the trophies in.
my @winners; # Store the nicks of previous winners
# End user configuration
#use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
$VERSION = '005';
%IRSSI = (
    authors     => 'Flash',
    contact     => 'flash@digdilem.org',
    name        => 'Huntin and fishin',
    description => 'An amusing if bloodthirsty game',
    license     => 'Do what thou wilt, and it harm none',
);
Irssi::signal_add("message public", \&hunting);
Irssi::signal_add("message private", \&hunting);
Irssi::signal_add("message own_public", \&own_message);
Irssi::signal_add("message own_private", \&own_message);

my $bigfish=1,my $fishman='Nobody',my $bighunt=0,my $huntman='Nobody';
my $fishtype='Trout',my $fishplace='pool';  # Initial records.
my $hunttype='bear', my $huntplace='some bushes';
my $last_hunter;
my $last_fisher;

my @hunts = ( 'bear','gopher','rabbit','hunter','deer','fox','duck','moose','pokemon named Pikachu','park ranger','Yogi Bear','Boo Boo Bear',
	'dog named Benji','cow','raccoon','koala bear','camper','channel lamer','haggis','Big Mac','sheep','baby lamb','lion','tiger','jaguar',
	'scrap car','elephant','mouse','ferret','polecat','bush','tree','side of a barn','house','passing car','nudist camper','polar bear','jerboa',
	'gerbil','blonde','brunette','redhead','goth','emo','punk','policeman','traffic warden','shopkeeper','naturist','puppy with appealing eyes',
	'baby kitten','squirrel','roadsign','No-Shooting sign','politician','lawyer','duck','goose','swan','airship','low flying plane',
	'tree','riverbank','tarzan','cheetah','chimpanzee','lion','tiger','gorilla','tree surgeon','logger','cow pat');
my @fish = ( 'salmon','herring','yellowfin tuna','pink salmon','chub','barbel','perch','northern pike','brown trout','arctic char','roach',
	'brayling','bleak','cat fish','sun fish','old tire','rusty tin can','genie lamp','love message in a bottle','old log','rubber boot','dead body',
	'loch ness monster','old fishing lure','piece of the Titanic','chunk of atlantis','squid','whale','dolphin','porpoise','stingray','submarine',
	'seal','seahorse','jellyfish','starfish','electric eel','great white shark','scuba diver','lag monster','virus','soggy pack of smokes',
	'pile of weed','boat anchor','pair of floaties','mermaid','merman','halibut','tiddler','sock','trout','penguin','road sign','scrap car',
	'shopping trolley','walrus','old boot');
my @huntplaces = ('in some bushes','in a hunting blind','in a hole','up in a tree','in a hiding place','out in the open','in the middle of a field',
	'downtown','on a street corner','at the local mall');
my @fishplaces = ('stream','lake','river','pond','ocean','bathtub','kiddies swimming pool','toilet','pile of vomit','pool of urine','kitchen sink',
	'bathroom sink','mud puddle','pail of water','bowl of jell-o (tm)','wash basin','rain barrel','aquarium','snowbank','waterfall','cup of coffee',
	'glass of milk','bottle of beer','cup of coffee','an upturned hat','fish tank at the local restaurant');

if (open (DH,"<$trophy_cabinet")) {
	($bigfish,$fishman,$fishtype,$fishplace) = split(/\|/,<DH>);
	chomp($fishplace);
	($bighunt,$huntman,$hunttype,$huntplace) = split(/\|/,<DH>);
	chomp($huntplace);
	my $blankline = <DH>; # Just grab the filler line, everything after this is player scores.
	@winners;
	while (<DH>)
	{
		chomp;
		if (length $_ > 1) { push(@winners,$_); }
	}
	close (DH);
	print("Peered in the trophy cabinet: ($bigfish$scale $fishtype by $fishman) ($bighunt$scale $hunttype by $huntman) - we have ".scalar(@winners)." previous winners!");
	} else {
	print("\002Woo, looks like we've not gone hunting before. Let's make a trophy cabinet...");
	save_trophy();
	}

print("\002Loaded Flash's Huntin' 'n Fishin' v.$VERSION\002 (!hunt, !fish !trophy - Current records are $bigfish$scale and $bighunt$scale)");

sub hunting {
    my ($server, $data, $hunter, $mask, $channel) = @_;
	my @pubwords = split(/ /,$data);
	if (lc($pubwords[0]) eq '!hunt') {
		if ($hunter eq $last_hunter) {
			$server->command("msg $channel Stop hogging all the best pitches $hunter, let someone else try first!");
			return;
			} else {
			$last_hunter = $hunter;
			}
		my $newhuntplace = @huntplaces[rand(scalar @huntplaces)];
		my $hunt = @hunts[rand(scalar @hunts)];
		my $weight = 1+int(rand($bighunt+10));
		if (rand(100)<$catch_percent) {
			if (rand(100)<$megakill_chance) {
				$weight+=$megakill_bonus;
				$server->command("msg $channel ".coloursay("=-=-=-=-==-=-=-=-==-=-=-=-==-=-=-=-==-=-=-=-==-=-=-=-="));
				$server->command("msg $channel $hunter found an RPG and nuked the whole area! The biggest catch was a $weight$scale $hunt");
				} else {
				$server->command("msg $channel $hunter just bagged a $weight$scale $hunt from $newhuntplace.");
				}
			if ($weight > $bighunt) {
				$server->command("msg $channel Wow! That breaks the old record of a $bighunt$scale $hunttype! $hunter is amazing!");
				$bighunt=$weight;
				$huntman=$hunter;
				$hunttype=$hunt;
				$huntplace=$newhuntplace;
				save_trophy();
				}
		} else {
			$server->command("msg $channel $hunter is useless, they missed by a mile!");
			}
		}
	if (lc($pubwords[0]) eq '!fish') {
		my $newfishplace = @fishplaces[rand(scalar @fishplaces)];
		my $fishy = @fish[rand(scalar @fish)];
		my $weight = 1+int(rand($bigfish+10));
		if ($hunter eq $last_fisher) {
			$server->command("msg $channel Stop hogging all the best pitches $hunter, let someone else try first!");
			return;
			} else {
			$last_fisher = $hunter;
			}
		if (rand(100)<$catch_percent) {
			if (rand(100)<$megakill_chance) {
				$weight+=$megakill_bonus;
				$server->command("msg $channel ".coloursay("=-=-=-=-==-=-=-=-==-=-=-=-==-=-=-=-==-=-=-=-==-=-=-=-="));
				$server->command("msg $channel $hunter found some dynamite and took out the whole $newfishplace! The biggest catch was a $weight$scale $fishy");
				} else {
				$server->command("msg $channel $hunter just caught a $weight$scale $fishy from the $newfishplace");
				}
			if ($weight > $bigfish) {
				$server->command("msg $channel Brilliant! That breaks the old record of a $bigfish$scale $fishtype! $hunter is the world's best!");
				$fishman=$hunter;
				$bigfish=$weight;
				$fishtype=$fishy;
				$fishplace=$newfishplace;
				save_trophy();
				}
		} else {
			$server->command("msg $channel $hunter is useless, they failed to catch anything!");
			}
		}
	if (($bigfish > $automatic_reset) or ($bighunt > $automatic_reset)) {
		$server->command("msg $channel ".coloursay("\\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/ \\o/"));
		$server->command("msg $channel $fishman holds the fishing record when they caught a $bigfish$scale $fishtype from the $fishplace");
		$server->command("msg $channel $huntman holds the hunting record when they bagged a $bighunt$scale $hunttype from $huntplace");
		$server->command("msg $channel That's it! This months quota has been reached! Clearing the trophy cabinet...");
		reset_scores();
		}
	if (lc($pubwords[0]) eq '!trophy') {
		if (!defined $channel) { $channel = $hunter; } # It's a pm, msg person instead.
		$server->command("msg $channel $fishman holds the fishing record when they caught a $bigfish$scale $fishtype from the $fishplace");
		$server->command("msg $channel $huntman holds the hunting record when they bagged a $bighunt$scale $hunttype from $huntplace");
		my $cnt=1;
		my $shownum = 5;
		if (defined $pubwords[1]) { $shownum = $pubwords[1]; }
		my $top5;
		my %count;
	    map { $count{$_}++ } @winners;

		foreach $value (reverse sort {$count{$a} cmp $count{$b} }  keys %count) {
			if ($cnt <= $shownum) { $top5 .= "\002#$cnt\002 $value (${count{$value}}) "; }
			$cnt++;
			}

			if (defined $top5) {
				$server->command("msg $channel Top $shownum winners: $top5");
			}


		}
	if (lc($pubwords[0]) eq '!newmonth') {
		if (lc($hunter) eq lc($owner_nick)) {
			reset_scores();
			$server->command("msg $channel It's a new month, all existing huntin' 'n fishin' records are reset!");
			} else { $server->command("msg $channel Who are you, $hunter to tell me to change the month?"); }
		}
}

sub reset_scores {
	if ($bigfish > $bighunt)
	{		push(@winners,$fishman); 	}
	else
	{		push(@winners,$huntman);	}
	$bigfish=0; $fishman='Nobody'; $fishtype='Tiddler'; $fishplace='Toilet';
	$bighunt=0; $huntman='Nobody'; $hunttype='Haggis'; $huntplace='Bush';
	save_trophy();
	}

sub coloursay {# say something in pretty colours
	my $thing = shift;
	my $i=0;
	$thing =~ s{(.)}{"\cC" . (($i++%14)+2) . "$1"}eg;
	return "\002$thing";
	}

sub save_trophy {
	open (DH, ">$trophy_cabinet") or die("Bah! Can't open the trophy cabinet to push this 'ere trophy in! ($!) ($trophy_cabinet)");
	$fishman =~ s/\|/_/g;
	$huntman =~ s/\|/_/g;
	print (DH "$bigfish|$fishman|$fishtype|$fishplace\n");
	print (DH "$bighunt|$huntman|$hunttype|$huntplace\n");
	print DH "--Begin Winners--\n";
	foreach(@winners)
	{
		print DH "$_\n";
	}
	close (DH);
	}

sub own_message {
    my ($server, $data, $channel) = @_;
	my @pubwords = split(/ /,$data);
	if (lc($pubwords[0]) eq '!newmonth') {
			$bigfish=0; $fishman='Nobody'; $fishtype='Tiddler'; $fishplace='Toilet';
			$bighunt=0; $huntman='Nobody'; $hunttype='Haggis'; $huntplace='Bush';
			save_trophy();
			$server->command("msg $channel It's a new month, all existing huntin' 'n fishin' records are reset!");
		}
	}

