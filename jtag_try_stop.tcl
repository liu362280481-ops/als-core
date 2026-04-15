set log [open /tmp/xsdb_try.log w]
connect
after 2000
puts $log "Targets:"
puts $log [targets]

puts $log "Try to stop A53 #0 (target 10)..."
targets -set 10
stop
after 500
puts $log "Stop succeeded!"

set pc [rrd pc]
puts $log "PC: $pc"

con

close $log
exit
