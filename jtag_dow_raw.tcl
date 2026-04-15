set log [open /tmp/xsdb_dow.log w]
connect
after 2000

puts $log "Check targets:"
puts $log [targets]

puts $log "Load bitstream..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

puts $log "Targets after fpga:"
puts $log [targets]

puts $log "Try dow on target 9..."
targets -set 9
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000
puts $log "dow succeeded!"

puts $log "Go..."
con

close $log
exit
