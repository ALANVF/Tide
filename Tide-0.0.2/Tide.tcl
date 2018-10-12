package require Tk
package require ctext

proc rgb {r g b} {
	return [format "#%02x%02x%02x" r g b]
}

set path [file dirname [info script]]

proc ftos name {
	set cf [open $name r]
	set cfs [read $cf]
	close $cf
	return $cfs
}

proc ftod name {
	set f [open $name r]
	set d [read $f]
	close $f
	return [regsub -all {\n} $d { }]
}

set configFile [ftos "$path/config.tcl-ide2-config"]
set config [regsub -all {\n} $configFile { }]

set c [dict create\
	theme [ftod "$path/themes/[dict get $config theme].tcl-ide2-theme"]\
	language [ftod "$path/languages/[dict get $config language]"]\
]

proc get {args} {
	#set c [uplevel set c]
	set s [dict get [dict get [dict get [dict get $::c language] syntax] [lindex $args 0]] [lindex $args 1]]
	
	return [list\
			$s\
			[dict get [dict get [dict get [dict get $::c language] colors] [lindex $args 0]] [lindex $args 1]]\
	]
}

##console show
##puts [dict get [dict get [dict get [dict get $c language] syntax] keywords] Keywords]
##puts [lindex [lindex [get keywords Keywords] 0] 2]


proc Multiline-comment {win color cmt} {
	if {[catch {$win tag cget multi-line-comment -foreground}]} {return}
	puts "[lindex $cmt 1]"
	set startIndex 1.0
	set commentRE "\\\\\\\\|\\\"|\\\\\"|\\\\'|'|[lindex $cmt 0]|[lindex $cmt 1]"
	#{\\\\|\"|\\\"|\\'|'|/\*|\*/}
	set commentStart 0
	set isQuote 0
	set isSingleQuote 0
	set isComment 0
	$win tag remove multi-line-comment 1.0 end
	
	while 1 {
		set index [$win search -count length -regexp $commentRE $startIndex end]
		if {$index == ""} {break}
		set endIndex [$win index "$index + $length chars"]
		set str [$win get $index $endIndex]
		set startIndex $endIndex
		
		if {$str eq "\\\\"} {continue
		} elseif {$str eq "\\\""} {continue
		} elseif {$str eq "\\'"} {continue
		} elseif {$str eq "\"" && $isComment == 0 && $isSingleQuote == 0} {if {$isQuote} {set isQuote 0} else {set isQuote 1}
		} elseif {$str eq "'" && $isComment == 0 && $isQuote == 0} {if {$isSingleQuote} {set isSingleQuote 0} else {set isSingleQuote 1}
		} elseif {$str eq [lindex $cmt 0] && $isQuote == 0 && $isSingleQuote == 0} {if {$isComment} {break} else {set isComment 1; set commentStart $index}
		} elseif {$str eq [lindex $cmt 1] && $isQuote == 0 && $isSingleQuote == 0} {if {$isComment} {set isComment 0; $win tag add multi-line-comment $commentStart $endIndex; $win tag raise multi-line-comment} else {break}
		}
	}
	
	$win tag configure multi-line-comment -foreground $color
}

#######

proc ctext::enableComments {win color} {
	$win tag configure _cComment -foreground $color
}

proc ctext::comments {win {afterTriggered 0}} {
	set cmt [dict get [dict get [dict get [dict get $::c] language] syntax] multi-line-comment]
	set bc [lindex $cmt 0]
	set ec [lindex $cmt 1]
	
	#:REDO ALL OF THIS
	
	if {$afterTriggered} {
		ctext::getAr $win config configAr
		set configAr(commentsAfterId) ""
	}
	
	set startIndex 1.0
	set commentRE "\\\\\\\\|\\\"|\\\\\"|\\\\'|'|$bc|$ec"
	set commentStart 0
	set isQuote 0
	set isSingleQuote 0
	set isComment 0
	$win tag remove _cComment 1.0 end
	while 1 {
	set index [$win search -count length -regexp $commentRE $startIndex end]
	
	if {$index == ""} {
		break
	}
	
	set endIndex [$win index "$index + $length chars"]
	set str [$win get $index $endIndex]
	set startIndex $endIndex
	
	if {$str == "\\\\"} {
		continue
	} elseif {$str eq "\\\""} {
		continue
	} elseif {$str eq "\\'"} {
		continue
	} elseif {$str eq "\"" && $isComment == 0 && $isSingleQuote == 0} {
		if {$isQuote} {
		set isQuote 0
		} else {
		set isQuote 1
		}
	} elseif {$str eq "'" && $isComment == 0 && $isQuote == 0} {
		if {$isSingleQuote} {
		set isSingleQuote 0
		} else {
		set isSingleQuote 1
		}
	} elseif {$str eq [subst $bc] && $isQuote == 0 && $isSingleQuote == 0} {
		if {$isComment} {
		#comment in comment
		break
		} else {
		set isComment 1
		set commentStart $index
		}
	} elseif {$str eq [subst $ec] && $isQuote == 0 && $isSingleQuote == 0} {
		if {$isComment} {
		set isComment 0
		$win tag add _cComment $commentStart $endIndex
		$win tag raise _cComment
		} else {
		#comment end without beginning
		break
		}
	}
	}
}

proc changeMode lang {
	set ::c [dict replace $::c language [ftod "$::path/languages/$lang"]]
	
	foreach n [dict keys [dict get [dict get $::c language] colors]] {
		if {$n ne "basic" && $n ne "multi-line-comment"} {
			foreach {k v} [dict get [dict get [dict get $::c language] colors] $n] {
				if {[regexp -- {^((Keyword|Constant|Function|Operator|Number|String|Comment)\d)|(Default(Text|Background|Cursor))$} $v]} {
					set col [dict get [dict get $::c theme] [lindex [get $n $k] 1]]
				} else {
					set col $v
				}
				#puts "$n $col $k $v"
				
				if {$n eq "keywords"} {
					ctext::addHighlightClass .f.t $k $col [lindex [get $n $k] 0]
				} elseif {$n eq "symbols"} {
					ctext::addHighlightClassForSpecialChars .f.t $k $col [lindex [get $n $k] 0]
				} elseif {$n eq "numbers" || $n eq "strings" || $n eq "regexes" || $n eq "comments"} {
					ctext::addHighlightClassForRegexp .f.t $k $col [lindex [get $n $k] 0]
				}
			}
		} elseif {$n eq "basic"} {
			foreach {k v} [dict get [dict get [dict get $::c language] colors] $n] {
				if {[regexp -- {^((Keyword|Constant|Function|Operator|Number|String|Comment)\d)|(Default(Text|Background|Cursor))$} $v]} {
					set col [dict get [dict get $::c theme] $v]
				} else {
					set col $v
				}
				
				switch -- $k {
					Default-Text       {.f.t configure -foreground $col}
					Default-Background {.f.t configure -background $col}
					Default-Cursor     {.f.t configure -insertbackground $col}
				}
			}
		} elseif {$n eq "multi-line-comment"} {
			if {[regexp -- {^(?:(?:Keyword|Constant|Function|Operator|String|Comment)\d)||(?:Default|Background|Cursor)$} [dict get [dict get [dict get $::c language] colors] $n]] != 0} {
				set col [dict get [dict get $::c theme] [dict get [dict get [dict get $::c language] colors] $n]]
			} else {
				set col [dict get [dict get [dict get $::c language] colors] $n]
			}
			#Multiline-comment .f.t $col [dict get [dict get [dict get $::c language] syntax] $n]
			
			ctext::enableComments .f.t $col
		}
	}
}

proc changeTheme theme {
	set ::c [dict replace $::c theme [ftod "$::path/themes/$theme.tcl-ide2-theme"]]
	
	foreach n [dict keys [dict get [dict get $::c language] colors]] {
		if {$n ne "basic" && $n ne "multi-line-comment"} {
			foreach {k v} [dict get [dict get [dict get $::c language] colors] $n] {
				if {[regexp -- {^((Keyword|Constant|Function|Operator|Number|String|Comment)\d)|(Default(Text|Background|Cursor))$} $v]} {
					set col [dict get [dict get $::c theme] [lindex [get $n $k] 1]]
				} else {
					set col $v
				}
				#puts "$n $col $k $v"
				
				if {$n eq "keywords"} {
					ctext::addHighlightClass .f.t $k $col [lindex [get $n $k] 0]
				} elseif {$n eq "symbols"} {
					ctext::addHighlightClassForSpecialChars .f.t $k $col [lindex [get $n $k] 0]
				} elseif {$n eq "numbers" || $n eq "strings" || $n eq "regexes" || $n eq "comments"} {
					ctext::addHighlightClassForRegexp .f.t $k $col [lindex [get $n $k] 0]
				}
			}
		} elseif {$n eq "basic"} {
			foreach {k v} [dict get [dict get [dict get $::c language] colors] $n] {
				if {[regexp -- {^((Keyword|Constant|Function|Operator|Number|String|Comment)\d)|(Default(Text|Background|Cursor))$} $v]} {
					set col [dict get [dict get $::c theme] $v]
				} else {
					set col $v
				}
				
				switch -- $k {
					Default-Text       {.f.t configure -foreground $col}
					Default-Background {.f.t configure -background $col}
					Default-Cursor     {.f.t configure -insertbackground $col}
				}
			}
		} elseif {$n eq "multi-line-comment"} {
			if {[regexp -- {^(?:(?:Keyword|Constant|Function|Operator|String|Comment)\d)||(?:Default|Background|Cursor)$} [dict get [dict get [dict get $::c language] colors] $n]] != 0} {
				set col [dict get [dict get $::c theme] [dict get [dict get [dict get $::c language] colors] $n]]
			} else {
				set col [dict get [dict get [dict get $::c language] colors] $n]
			}
			#Multiline-comment .f.t $col [dict get [dict get [dict get $::c language] syntax] $n]
			
			ctext::enableComments .f.t $col
		}
	}
}

set ::fileName Untitled

############
console show


proc main {} {
	menu .toolbar
	. configure -menu .toolbar
	
	.toolbar add cascade -menu [menu .toolbar._file -tearoff 0]    -label File
		.toolbar._file add command -label "New File"     -command {}
		.toolbar._file add command -label "Open File"    -command {
			#set _fileName [tk_getOpenFile -filetypes {{{Talk Files} {.sm}} {{Talk Extension Files} {.sme}} {{All Files} *}}]
			set _fileName [tk_getOpenFile -filetypes {
				{"All Files"          *}
				{"JavaScript Files" .js}
				{"Talk Files"       .sm}
				{"C Files"      {.c .h}}
				{"Tcl Files"       .tcl}
				{"JSON Files"     .json}
				{"Lua Files"       .lua}
			}]
	
			if {$_fileName ne ""} {
				set ::fileName $_fileName
				set mainFile [open $_fileName r]
				#.f.t fastinsert end [read $mainFile]
				.f.t fastdelete 1.0 end
				.f.t fastinsert end [read $mainFile]
				close $mainFile
			}
			
			#fileMode $_fileName
			
			.f.t highlight 1.0 end
		}
		.toolbar._file add command -label "Save File"    -command {
			set currentFile [open $::fileName w]
			puts $currentFile [.f.t get 1.0 end]
			close $currentFile
		}
		.toolbar._file add command -label "Save File As" -command {
			set _newFile [tk_getSaveFile -filetypes {
				{"All Files"          *}
				{"JavaScript Files" .js}
				{"Talk Files"       .sm}
				{"C Files"      {.c .h}}
				{"Tcl Files"       .tcl}
				{"JSON Files"     .json}
				{"Lua Files"       .lua}
			}]
			
			set ::fileName $_newFile
			set saveFile [open $_newFile w]
			puts $saveFile [.f.t get 1.0 end]
			close $saveFile
		}
		.toolbar._file add command -label "Close File"   -command {
			set ::fileName Untitled
			.f.t fastdelete 1.0 end
		}
		.toolbar._file add command -label "Exit"         -command {exit}
	
	.toolbar add cascade -menu [menu .toolbar._edit -tearoff 0]    -label Edit
	.toolbar add cascade -menu [menu .toolbar._view -tearoff 0]    -label View
	.toolbar add cascade -menu [menu .toolbar._search -tearoff 0]  -label Search
	.toolbar add cascade -menu [menu .toolbar._tools -tearoff 0]   -label Tools
	.toolbar add cascade -menu [menu .toolbar._options -tearoff 0] -label Options
		.toolbar._options add command -label "Change Language" -command {
			toplevel .setlang
			wm minsize .setlang 200 200
			
			pack [frame .setlang.langs] -side top -anchor nw
			foreach i [glob -directory $::path/languages *] {
				set t [file tail $i]
				
				pack [button .setlang.langs._$t -text $t -width 15 -command "
					set t $t
					
					ctext::clearHighlightClasses .f.t
					changeMode \$t
					
					set _tempText \[.f.t get 1.0 end\]
					.f.t fastdelete 1.0 end
					.f.t fastinsert end \$_tempText
					.f.t highlight 1.0 end
					
					puts \$t
					set ::config \[dict replace \$config language \$t\]
					
					set currentFile [open "$::path/config.tcl-ide2-config" w]
					puts \$currentFile \$config
					close \$currentFile
					
					puts \$config
					
				"] -side top -anchor nw
			}
			
			pack [button .setlang.bclose -text Close -command {
				destroy .setlang
			}] -side bottom
		}
		.toolbar._options add command -label "Change Theme"    -command {
			toplevel .settheme
			wm minsize .settheme 200 200
			
			pack [frame .settheme.themes] -side top -anchor nw
			foreach i [glob -directory $::path/themes *] {
				set t [file rootname [file tail $i]]
				
				pack [button .settheme.themes._[string tolower [regsub -all {\-} $t ""]] -text $t -width 15 -command "
					set t $t
					
					ctext::clearHighlightClasses .f.t
					changeTheme \$t
					
					set _tempText \[.f.t get 1.0 end\]
					.f.t fastdelete 1.0 end
					.f.t fastinsert end \$_tempText
					.f.t highlight 1.0 end
					
					puts \$t
					set ::config \[dict replace \$config theme \$t\]
					
					set currentFile [open "$::path/config.tcl-ide2-config" w]
					puts \$currentFile \$config
					close \$currentFile
					
					puts \$config
				"] -side top -anchor nw
			}
			
			pack [button .settheme.bclose -text Close -command {
				destroy .settheme
			}] -side bottom
		}
		.toolbar._options add command -label "Change Font"     -command {
			toplevel .setfont
			wm minsize .setfont 200 400
			
			pack [frame .setfont.fonts] -side top -anchor nw
			pack [label .setfont.fonts.notyet -text "Lol not finished yet"] -side top -anchor nw
			
			if 0 {
			foreach family [lsort -dictionary [font families]] {
				pack [button .setfont.fonts._[string tolower [regsub -all { } $family "_"]] -text $family -font [list $family 10]] -side top -anchor nw
				
				#.setfont.t tag configure f[incr count] -font [list $family 10]
				#.setfont.t insert end ${family}:\t {} \
				#	"This is a simple sampler\n" f$count
				#set w [font measure [.setfont.t cget -font] ${family}:]
				#if {$w+5 > $tabwidth} {
				#	set tabwidth [expr {$w+5}]
				#	.setfont.t configure -tabs $tabwidth
				#}
			}
			}
			
			pack [button .setfont.bclose -text Close -command {
				destroy .setfont
			}] -side bottom
		}
	
	.toolbar add cascade -menu [menu .toolbar._help -tearoff 0]    -label Help
	
	#menu .toolbar._file.sb -tearoff 0
	
	#.toolbar._file add cascade -label Import -menu .toolbar._file.sb
	
	pack [frame .f] -fill both -expand 1
	pack [scrollbar .f.s -command {.f.t yview}] -side right -fill y
	
	#-linemapbg white
	#-linemapfg brown
	
	## Add options for font (style, size). Add sidebar configuration options to themes.
	pack [ctext .f.t -font Consolas -bg white -fg black -insertbackground red -yscrollcommand {.f.s set} -tabs "[expr {4 * [font measure .text 0]}] left"] -fill both -expand 1
	
	
	
	set test {
		make a be 1
		make b be 2
		
		method add takes $a, $b
			return $a + $b
		end
		
		method minus takes $a-var, $another-var
			return $a-var - $another-var
		end
		
		say add(1, 2)
		
		$banana = 1
		$func takes stuff And does stuff then end
		
		#geg  gre "afasafs" sadfawsdfa "SDF ADS "
		"DSA #FSD  4#$ DF DF"
	}
	
	ctext::clearHighlightClasses .f.t
	
	foreach n [dict keys [dict get [dict get $::c language] colors]] {
		if {$n ne "basic" && $n ne "multi-line-comment"} {
			foreach {k v} [dict get [dict get [dict get $::c language] colors] $n] {
				if {[regexp -- {^((Keyword|Constant|Function|Operator|Number|String|Comment)\d)|(Default(Text|Background|Cursor))$} $v]} {
					set col [dict get [dict get $::c theme] [lindex [get $n $k] 1]]
				} else {
					set col $v
				}
				#puts "$n $col $k $v"
				
				if {$n eq "keywords"} {
					ctext::addHighlightClass .f.t $k $col [lindex [get $n $k] 0]
				} elseif {$n eq "symbols"} {
					ctext::addHighlightClassForSpecialChars .f.t $k $col [lindex [get $n $k] 0]
				} elseif {$n eq "numbers" || $n eq "strings" || $n eq "regexes" || $n eq "comments"} {
					ctext::addHighlightClassForRegexp .f.t $k $col [lindex [get $n $k] 0]
				}
			}
		} elseif {$n eq "basic"} {
			foreach {k v} [dict get [dict get [dict get $::c language] colors] $n] {
				if {[regexp -- {^((Keyword|Constant|Function|Operator|Number|String|Comment)\d)|(Default(Text|Background|Cursor))$} $v]} {
					set col [dict get [dict get $::c theme] $v]
				} else {
					set col $v
				}
				
				switch -- $k {
					Default-Text       {.f.t configure -foreground $col}
					Default-Background {.f.t configure -background $col}
					Default-Cursor     {.f.t configure -insertbackground $col}
				}
			}
		} elseif {$n eq "multi-line-comment"} {
			if {[regexp -- {^(?:(?:Keyword|Constant|Function|Operator|String|Comment)\d)||(?:Default|Background|Cursor)$} [dict get [dict get [dict get $::c language] colors] $n]] != 0} {
				set col [dict get [dict get $::c theme] [dict get [dict get [dict get $::c language] colors] $n]]
			} else {
				set col [dict get [dict get [dict get $::c language] colors] $n]
			}
			#Multiline-comment .f.t $col [dict get [dict get [dict get $::c language] syntax] $n]
			
			ctext::enableComments .f.t $col
		}
	}
	
	######ctext::addHighlightClassWithOnlyCharStart
	
	#.f.t fastinsert end [info body main]
	pack [frame .f1] -fill x
	.f.t highlight 1.0 end
	pack [button .f1.exit -text Exit -command exit] -side left
	
	bind . <Key-F5> {
		console show
		
		puts [.f.t get 1.0 end]
	}
}

main