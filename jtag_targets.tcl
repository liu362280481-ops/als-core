set log [open /tmp/targets.log w]
connect
after 2000
puts $log "Targets after FPGA load:"
puts $log [targets]
close $log
exit
