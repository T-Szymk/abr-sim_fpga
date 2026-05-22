# ------------------------------------------------------------------------------
# common.tcl
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 12-jan-2026
#
# Description: Common TCL procs to be used within other scripts
# ------------------------------------------------------------------------------

# get name of current file calling the procedure
proc get_current_filename {} {
  return [file tail [info script]]
}

# log message to be printed when entering a script 
proc log_script_entry {} {
  puts "\n---------------------------------------------------------"
  puts "[get_current_filename] - Starting..."
  puts "---------------------------------------------------------\n"
}

# log message to be printed when exiting a script
proc log_script_exit {} {
  puts "\n---------------------------------------------------------"
  puts "[get_current_filename] - Complete!"
  puts "---------------------------------------------------------\n"
}

if {[info exists ::env(CURR_DIR)]} {
    set CURR_DIR $::env(CURR_DIR)
} else {
    puts "CURR_DIR environment variable not set. Please set it to the /fpga directory."
    exit
}

