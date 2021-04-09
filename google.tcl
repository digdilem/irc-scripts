#
# google.tcl - X-Chat TCL script that implements a public !google command
# 
#	prerequisites:
#		You need to have
#
#		+	TCL 8.5 (http://www.tcl.tk/) and
#		+	TCLLib 1.15 (http://tcllib.sourceforge.net/)
#
#		installed.
#		You also need a Google API key and a Google Search Id.
#
# installation:
#		Put google.tcl into startup scripts folder
#
#		+	on Windows the folder usually is	"C:\Users\[Your User Name]\AppData\Roaming\X-Chat 2"
#		+	on Linux the folder usually is		"~/.xchat2/"
#
#		and setup the configuration below.
#
#	usage:
#		If someone (including you) types
#
#			!google My Search Terms
#
#		into a channel or a private message
#		this script will respond with the first
#		search results found.
#		By default only the first 3 results are shown
#		but this can be configured.
#

#################
# configuration #
#################

set API_KEY		"YOUR_GOOGLE_API_KEY"
set SEARCH_ID	"YOUR_GOOGLE_SEARCH_ID"
set MAX_RESULTS 3

###################
# !google command #
###################

package require http
package require tls
package require json

# need https for google rest api
::http::register https 443 ::tls::socket

# search request queue
set google_queue {}

# say to user or channel
proc google_say { target data } {
	command "msg $target $data"
}

# enqueue cmd to be executed
proc google_enqueue { cmd } {
	global google_queue
	lappend google_queue $cmd
}

# called every second to handle enqueued commands
proc google_hook { } {
	global google_queue
	if { [ llength $google_queue ] > 0 } {
		set cmd [ lindex $google_queue 0 ]
		set google_queue [ lrange $google_queue 1 end ]
		eval $cmd
	}
}

# send the result to dest if it is a channel. otherwise send it to src
proc google_result { target data } {
	google_say $target "Search Results:"
	global MAX_RESULTS
	for { set i 0 } { $i < $MAX_RESULTS } { incr i } {
		set title [ dict get [ lindex [ dict get $data items ] $i ] title ]
		set link  [ dict get [ lindex [ dict get $data items ] $i ] link ]
		set index [ expr $i + 1 ]
		google_say $target "\[$index\] $title"
		google_say $target "\[$index\] $link"
	}
}

# perform google search request
proc google_request { target query } {
	global API_KEY SEARCH_ID
	set token [ ::http::geturl "https://www.googleapis.com/customsearch/v1?[::http::formatQuery alt json key $API_KEY cx $SEARCH_ID q $query]" ]
	set body [ ::http::data $token ]
	::http::cleanup $token
	set json [ ::json::json2dict $body ]
	google_result $target $json
}

# schedule a google search query
proc google_query { target query } {
	google_enqueue [ list google_request $target $query ]
}

# create !google command
on !google omega {
	splitsrc
	if { [ string index $_dest 0 ] eq "#" } {
		google_query $_dest $_rest
	} else {
		google_query $_nick $_rest
	}
	complete EAT_NONE
}

# also handle your commands
on XC_UCHANMSG omega {
	set target [ channel ]
	set data [ lindex $_raw 2 ]
	set first [ lindex $data 0 ]
	if { ( $first eq "!google" ) && ( [ llength $data ] > 1 ) } {
		google_query $target [ lrange $data 1 end ]
	}
	complete EAT_NONE
}

# start hook
timer -repeat 1 google_hook
print "!google command version 1.1 started."
