package require Tk
package require Ttk

set script_dir "C:/Users/Admin/Desktop/vlsi_integrity_checker/scripts"
set log_dir "C:/Users/Admin/Desktop/vlsi_integrity_checker/logs"
set checks {Linting CDC DRC STA PPA LEC RTL_Integrity}
set selected_check "Linting"
set selected_files ""

file mkdir $log_dir

# ---------------- GUI ----------------
wm title . "VLSI Design Integrity & Automation Suite"
wm geometry . 900x500

ttk::notebook .tabs
pack .tabs -expand 1 -fill both

# ---------------- Run Check Tab ----------------
frame .checktab
.tabs add .checktab -text "Run Checks"

label .checktab.l1 -text "Select Check Type:"
ttk::combobox .checktab.combo -values $checks -textvariable selected_check -state readonly

button .checktab.filebtn -text "Select Files" -command {
    set selected_files [tk_getOpenFile -multiple 1 -filetypes {{"Verilog Files" {.v .sv}} {"All Files" {*}}}]
    if {$selected_files ne ""} {
        .checktab.files configure -text "Selected Files: $selected_files"
    } else {
        .checktab.files configure -text "No files selected."
    }
}

label .checktab.files -text "No files selected." -wraplength 800 -justify left
button .checktab.runbtn -text "Run Check" -command run_check

# Pack widgets
pack .checktab.l1 -anchor w -padx 10 -pady 5
pack .checktab.combo -anchor w -padx 10
pack .checktab.filebtn -padx 10 -pady 5
pack .checktab.files -anchor w -padx 10
pack .checktab.runbtn -padx 10 -pady 10

# ---------------- Log Viewer Tab ----------------
frame .logtab
.tabs add .logtab -text "View Logs"

listbox .logtab.list -width 100 -height 20
scrollbar .logtab.sb -orient vertical -command ".logtab.list yview"
.logtab.list configure -yscrollcommand ".logtab.sb set"

text .logtab.viewer -width 100 -height 15 -wrap word

pack .logtab.sb -side right -fill y
pack .logtab.list -side top -fill both -expand 1
pack .logtab.viewer -side bottom -fill both -expand 1

proc load_logs {} {
    .logtab.list delete 0 end
    foreach f [lsort [glob -nocomplain "$::log_dir/*.log"]] {
        .logtab.list insert end [file tail $f]
    }
}
load_logs

bind .logtab.list <<ListboxSelect>> {
    set sel [.logtab.list curselection]
    if {[llength $sel]} {
        set fname [lindex [.logtab.list get $sel] 0]
        set fpath "$::log_dir/$fname"
        set fh [open $fpath r]
        set content [read $fh]
        close $fh
        .logtab.viewer delete 1.0 end
        .logtab.viewer insert end $content
    }
}

# ---------------- About Tab ----------------
frame .abouttab
.tabs add .abouttab -text "About"
label .abouttab.l -text "VLSI Design Integrity & Automation Suite\nBy Kartik Aggarwal\n© 2025" -justify center
pack .abouttab.l -padx 20 -pady 50

# ---------------- Output Handling ----------------
proc read_output_popup {pipe text_widget logfile} {
    if {[eof $pipe]} {
        close $pipe
        close $logfile
        return
    }
    set line [read $pipe]
    puts $logfile $line
    if {[regexp -nocase {error|fail|fatal} $line]} {
        $text_widget insert end $line "error"
    } else {
        $text_widget insert end $line
    }
    $text_widget see end
}

# ---------------- Run Check Logic ----------------
proc run_check {} {
    global selected_check selected_files script_dir log_dir

    if {$selected_check eq "" || $selected_files eq ""} {
        tk_messageBox -message "Please select a check type and files first!" -icon warning
        return
    }

    set script_map {
        Linting         linting.pl
        CDC             cdc_checker.pl
        DRC             drc_checker.pl
        STA             sta_checker.pl
        PPA             ppa_checker.pl
        LEC             lec_checker.pl
        RTL_Integrity   rtl_integrity.pl
    }

    if {[catch {dict get $script_map $selected_check} script_name]} {
        tk_messageBox -message "Script not found for $selected_check!" -icon error
        return
    }

    set timestamp [clock format [clock seconds] -format "%Y-%m-%d_%H-%M-%S"]
    set log_file "$log_dir/${selected_check}_$timestamp.log"
    set log [open $log_file w]

    set script_path "$script_dir/$script_name"
    set cmd [list perl $script_path]
    foreach f $selected_files {
        lappend cmd $f
    }

    catch {close $::pipe}
    set ::pipe [open "|$cmd" r]
    fconfigure $::pipe -blocking 0

    # Create a separate output popup window
    set win .output$timestamp
    toplevel $win
    wm title $win "$selected_check Output - $timestamp"

    text $win.txt -width 100 -height 25 -wrap word -yscrollcommand "$win.scroll set"
    scrollbar $win.scroll -orient vertical -command "$win.txt yview"
    $win.txt tag configure error -foreground red

    pack $win.scroll -side right -fill y
    pack $win.txt -side left -fill both -expand 1

    fileevent $::pipe readable [list read_output_popup $::pipe $win.txt $log]

    after 2000 load_logs
}

vwait forever
