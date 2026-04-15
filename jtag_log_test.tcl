set log [open /tmp/xsdb_targets.log w]
connect
after 2000
puts $log "Targets after restart:"
puts $log [targets]
close $log
exit
