toplevel .find

wm minsize .find 400 250

pack [frame .find.f] -fill both -expand 1
	
	place [frame .find.f.opt -borderwidth 1 -relief sunken -padx 2 -pady 2] -x 20 -y 100
		pack [checkbutton .find.f.opt.nocase -text "Case Insensitive" -variable opt_ci]   -side top -anchor sw
		pack [checkbutton .find.f.opt.regexp -text "Regular Expression" -variable opt_rx] -side top -anchor sw
	
	place [label  .find.f.lfind -text "Find: "]\
		-x 10 -y 20
	
	place [entry  .find.f.efind]\
		-x 50 -y 20
	
	place [button .find.f.bfind -text "find" -command {
		#if {$opt_ci == 1} {set ci "(?i)"} else {set ci ""}
		#if {$opt_rx == 0} {set rx "(?q)"} else {set rx ""}
		
		if $opt_rx {
			set s [.f.t search -count n -regexp -- [.find.f.efind get] 1.0 end]
		} elseif $opt_ci {
			set s [.f.t search -count n -nocase -- [.find.f.efind get] 1.0 end]
		} else {
			set s [.f.t search -count n -- [.find.f.efind get] 1.0 end]
		}
		
		.f.t tag add f_search $s $s+${n}c
		.f.t tag configure f_search -background orange
		.f.t mark set insert $s
		focus -force .f.t
	}] -x 30 -y 50
	
	place [button .find.f.bfindall -text "find all" -command {
		if $opt_rx {
			set s [.f.t search -all -count n -regexp -- [.find.f.efind get] 1.0 end]
		} elseif $opt_ci {
			set s [.f.t search -all -count n -nocase -- [.find.f.efind get] 1.0 end]
		} else {
			set s [.f.t search -all -count n -- [.find.f.efind get] 1.0 end]
		}
		
		foreach b $s l $n {
			.f.t tag add f_search $b $b+${l}c
		}
		.f.t tag configure f_search -background orange
		
		.f.t mark set insert [lindex $s 0]
		focus -force .f.t
	}] -x 70 -y 50
	
	place [button .find.f.bclearfind -text "remove highlights" -command {
		.f.t tag remove f_search 1.0 end
	}] -x 125 -y 50



pack [button .find.bclose -text Close -command {
	.f.t tag remove f_search 1.0 end
	destroy .find
}] -side bottom