toplevel .replace

wm minsize .replace 400 250

pack [frame .replace.f] -fill both -expand 1
	
	place [frame .replace.f.opt -borderwidth 1 -relief sunken -padx 2 -pady 2] -x 20 -y 100
		pack [checkbutton .replace.f.opt.nocase -text "Case Insensitive" -variable opt_ci]   -side top -anchor sw
		pack [checkbutton .replace.f.opt.regexp -text "Regular Expression" -variable opt_rx] -side top -anchor sw
	
	place [label  .replace.f.lfind -text "Find: "]\
		-x 10 -y 20
	
	place [entry  .replace.f.efind]\
		-x 50 -y 20
	
	place [label  .replace.f.lreplace -text "Replace with: "]\
		-x 185 -y 20
	
	place [entry  .replace.f.ereplace]\
		-x 270 -y 20
	
	place [button .replace.f.breplace -text "Replace" -command {
		#if {$opt_ci == 1} {set ci "(?i)"} else {set ci ""}
		#if {$opt_rx == 0} {set rx "(?q)"} else {set rx ""}
		
		if $opt_rx {
			set s [.f.t search -count n -regexp -- [.replace.f.efind get] 1.0 end]
		} elseif $opt_ci {
			set s [.f.t search -count n -nocase -- [.replace.f.efind get] 1.0 end]
		} else {
			set s [.f.t search -count n -- [.replace.f.efind get] 1.0 end]
		}
		
		catch {.f.t replace $s $s+${n}c [.replace.f.ereplace get]}
		#.f.t tag add f_search $s $s+${n}c
	}] -x 30 -y 50
	
	place [button .replace.f.breplaceall -text "Replace all" -command {
		if $opt_rx {
			set s [.f.t search -all -count n -regexp -backward -- [.replace.f.efind get] 1.0]
		} elseif $opt_ci {
			set s [.f.t search -all -count n -nocase -backward -- [.replace.f.efind get] 1.0]
		} else {
			set s [.f.t search -all -count n -backward -- [.replace.f.efind get] 1.0]
		}
		
		foreach b $s l $n {
			catch {.f.t replace $b $b+${l}c [.replace.f.ereplace get]}
		}
	}] -x 90 -y 50



pack [button .replace.bclose -text Close -command {
	destroy .replace
}] -side bottom

