set log [open /tmp/xsct.log w]
connect -url TCP:127.0.0.1:3121
after 2000
puts $log "Connected"
set targets [targets]
puts $log "Targets: $targets"
close $log
exit
