set logfile [open /tmp/xsdb_log2.txt w]

connect
after 1000

puts $logfile "Targets:"
set t_out [targets]
puts $logfile $t_out

puts $logfile "Target 9 properties:"
set props [targets -set 9 -target-properties]
puts $logfile $props

close $logfile
exit
