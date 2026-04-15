set logfile [open /tmp/rst_help.log w]
connect
after 500
puts $logfile "Testing rst commands..."
rst -help
close $logfile
exit
