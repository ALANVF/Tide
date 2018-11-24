package require Tk
package require ctext

font configure TkDefaultFont -family Arial -size 9

proc rgb {r g b} {
	return [format "#%02x%02x%02x" r g b]
}

set path [pwd]

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

if {[ftos "$::path/config.tide-config"] eq ""} {
	set newConfig [open "$::path/config.tide-config" w]
	puts -nonewline $newConfig [ftos "$::path/CONFIG-BACKUP"]
	close $newConfig
}

set configFile [ftos "$path/config.tide-config"]
set config [regsub -all {\n} $configFile { }]

set c [dict create\
	theme [ftod "$path/themes/[dict get $config theme].tide-theme"]\
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

proc Multiline-comment {win color cmt} {
	if {[catch {$win tag cget _cComment -foreground}]} {return}
	#puts "[lindex $cmt 1]"
	set startIndex 1.0
	set commentRE "\\\\\\\\|\\\"|\\\\\"|\\\\'|'|[lindex $cmt 0]|[lindex $cmt 1]"
	#{\\\\|\"|\\\"|\\'|'|/\*|\*/}
	set commentStart 0
	set isQuote 0
	set isSingleQuote 0
	set isComment 0
	$win tag remove _cComment 1.0 end
	
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
		} elseif {[expr [string equal $str [lindex $cmt 0]] || [string equal $str "[lindex $cmt 0]"]] && $isQuote == 0 && $isSingleQuote == 0} {if {$isComment} {break} else {set isComment 1; set commentStart $index}
		} elseif {[expr [string equal $str [lindex $cmt 1]] || [string equal $str "[lindex $cmt 1]"]] && $isQuote == 0 && $isSingleQuote == 0} {if {$isComment} {set isComment 0; $win tag add _cComment $commentStart $endIndex; $win tag raise multi-line-comment} else {break}
		}
	}
	
	$win tag configure _cComment -foreground $color
}

#######

proc ctext::enableComments {win color} {
	$win tag configure _cComment -foreground $color
	#$win tag configure multi-line-comment -foreground $color
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
	} elseif {[expr {$str eq [subst $bc]} || {$str eq $bc}] && $isQuote == 0 && $isSingleQuote == 0} {
		if {$isComment} {
		#comment in comment
		break
		} else {
		set isComment 1
		set commentStart $index
		}
	} elseif {[expr {$str eq [subst $ec]} || {$str eq $ec}] && $isQuote == 0 && $isSingleQuote == 0} {
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
					ctext::addHighlightClassForRegexp .f.t $k $col [regsub -all -expanded {[\n\r\t\s]+} [lindex [get $n $k] 0] ""]
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
	set ::c [dict replace $::c theme [ftod "$::path/themes/$theme.tide-theme"]]
	
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

proc readFile {win f} {
	set _f [open $f r]
	
	while {[gets $_f data] >= 0} {
		$win fastinsert end $data\n	
	}
	close $_f
}

proc saveFile win {
	set currentFile [open $::fileName w]
	puts -nonewline $currentFile [$win get 1.0 end]
	close $currentFile
}

proc highlightCurrent win {
	if {[string compare $::fileName Untitled] != 0} {
		set s [file size $::fileName]
		
		for {set i 1.0} {$i < "1.$s"} {set i [expr $i + 0.1]} {
			$win highlight $i end
		}
	} else {
		$win highlight 1.0 end
	}
}

proc getLine {} {
	return [regexp -inline -- {\d+(?=\.\d+)} [.f.t index "insert linestart"]]
}

set ::fileName Untitled
set ::fileTypes {{"All Files" *}}

foreach i [glob -directory $::path/languages *] {
	lappend ::fileTypes "\"[file tail $i] Files\" \{[dict get [ftod $i] extensions]\}"
}

#console show

wm title . "Tide - Untitled"

proc main {} {
	menu .toolbar
	. configure -menu .toolbar
	
	.toolbar add cascade -menu [menu .toolbar._file -tearoff 0]    -label File
		.toolbar._file add command -label "New File"     -command {}
		.toolbar._file add command -label "Open File"    -command {
			set _fileName [tk_getOpenFile -filetypes $::fileTypes]
			
			if {$_fileName ne ""} {
				set ::fileName $_fileName
				
				wm title . "Tide - $_fileName"
				
				.f.t fastdelete 1.0 end
				readFile .f.t $_fileName
				highlightCurrent .f.t
			}
		}
		.toolbar._file add command -label "Save File       (Ctrl+S)"    -command {
			if {$::fileName eq "Untitled"} {
				set _newFile [tk_getSaveFile -filetypes $::fileTypes]
				
				if {$_newFile ne ""} {
					set ::fileName $_newFile
					saveFile .f.t
				}
			} else {
				saveFile .f.t
			}
			
			wm title . "Tide - $::fileName"
		}
		.toolbar._file add command -label "Save File As  (Ctrl+S)" -command {
			set _newFile [tk_getSaveFile -filetypes $::fileTypes]
			
			if {$_newFile ne ""} {
				set ::fileName $_newFile
				saveFile .f.t
				
				wm title . "Tide - $_newFile"
			}
		}
		.toolbar._file add command -label "Close File"   -command {
			set ::fileName Untitled
			.f.t fastdelete 1.0 end
			
			wm title . "Tide - Untitled"
		}
		.toolbar._file add command -label "Exit"         -command {exit}
	
	.toolbar add cascade -menu [menu .toolbar._edit -tearoff 0]    -label Edit
		.toolbar._edit add command -label "Undo  (Ctrl+Z)"     -command {.f.t edit undo}
		.toolbar._edit add command -label "Redo   (Ctrl+Y)"    -command {.f.t edit redo}
		.toolbar._edit add command -label "Cut     (Ctrl+X)"   -command {.f.t cut}
		.toolbar._edit add command -label "Copy  (Ctrl+C)"     -command {.f.t copy}
		.toolbar._edit add command -label "Paste  (Ctrl+V)"    -command {.f.t paste}
	
	.toolbar add cascade -menu [menu .toolbar._view -tearoff 0]    -label View
	.toolbar add cascade -menu [menu .toolbar._search -tearoff 0]  -label Search
		.toolbar._search add command -label "Find..." -command {
			eval [ftos [file normalize ./Find-text.tcl]]
		}
		.toolbar._search add command -label "Replace..." -command {
			eval [ftos [file normalize ./Replace-text.tcl]]
		}
	.toolbar add cascade -menu [menu .toolbar._tools -tearoff 0]   -label Tools
		.toolbar._tools add command -label "Plugins (coming soon)" -command {}
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
					
					if {\[string compare \$::fileName Untitled\] != 0} {
						set _tempText \[.f.t get 1.0 end\]
						.f.t fastdelete 1.0 end
						readFile .f.t \$::fileName
					}
					highlightCurrent .f.t
					
					set ::config \[dict replace \$config language \$t\]
					
					set currentFile [open "$::path/config.tide-config" w]
					puts -nonewline \$currentFile \$config
					close \$currentFile
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
					
					if {\[string compare \$::fileName Untitled\] != 0} {
						set _tempText \[.f.t get 1.0 end\]
						.f.t fastdelete 1.0 end
						readFile .f.t \$::fileName
					}
					highlightCurrent .f.t
					
					set ::config \[dict replace \$config theme \$t\]
					
					set currentFile [open "$::path/config.tide-config" w]
					puts -nonewline \$currentFile \$config
					close \$currentFile
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
		.toolbar._help add command -label "Keybindings"           -command {
			toplevel .keys
			wm maxsize .keys 400 300
			
			pack [frame .keys.l] -side top -anchor nw
			pack [listbox .keys.l.kl -exportselection 0 -selectmode extended -width 400] -side top -anchor nw
			
			foreach i {
				{Ctrl+a : Move cursor to beginning of line.}
				{Ctrl+/ : Select all text.}
				{Ctrl+d : Delete character to the right of the cursor.}
				{Ctrl+k : Delete all text from the cursor to the end of the line.}
				{Ctrl+o : Insert a newline 1 line below the cursor without moving the cursor.}
				{Ctrl+t : Reverse 2 characters to the right of the cursor.}
			} {
				.keys.l.kl insert end $i
			}
			
			pack [button .keys.bclose -text Close -command {
				destroy .keys
			}] -side bottom
		}
		#.toolbar._help add command -label "How does this work..." -command {}
		.toolbar._help add command -label "About Tide"            -command {
			toplevel .about-tide
			wm minsize .about-tide 300 200
			wm maxsize .about-tide 300 200
			
			pack [frame .about-tide.about] -side top -anchor nw
			pack [message .about-tide.about.txt -text "Tide (Tcl IDE) is a code editor I'm making. (will add more stuff later)" -padx 10 -pady 10 -width 300] -side top -anchor nw
			
			pack [button .about-tide.bclose -text Close -command {
				destroy .about-tide
			}] -side bottom
		}
	
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
	.f.t highlight 1.0 end
	
	changeMode [dict get $::config language]
	
	.f.t conf* -undo 1
	
	bind .f.t <Control-s>  {
		#puts $::fileName
		if {$::fileName eq "Untitled"} {
			set _newFile [tk_getSaveFile -filetypes $::fileTypes]
			
			if {$_newFile ne ""} {
				set ::fileName $_newFile
				saveFile .f.t
			}
		} else {
			saveFile .f.t
		}
		
		wm title . "Tide - $::fileName"
	}
	
	bind .f.t <<Modified>> {
		wm title . "Tide - *$::fileName"
	}
	
	bind .f.t <KeyRelease-Return> {
		set l [getLine]
		set ln [regexp -inline\
					{^(\t*).*?([\(\[\{]?)\s*$}\
					[.f.t get [expr $l - 1].0 [expr $l - 1].end]\
				]
		
		if {[lindex $ln 2] ne ""} {
			.f.t fastinsert $l.end \t[lindex $ln 1]
		} else {
			.f.t fastinsert $l.end [lindex $ln 1]
		}
	}
}

main








