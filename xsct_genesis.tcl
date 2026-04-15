set log [open /tmp/xsct_genesis.log w]

connect -url TCP:127.0.0.1:3121
after 2000

puts $log "1. Load bitstream..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000
puts $log "Bitstream loaded."

puts $log "2. Targets:"
puts $log [targets]

puts $log "3. Try dow on target 9..."
targets -set 9
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000
puts $log "ELF downloaded!"

puts $log "4. Go..."
con

puts $log "Done!"
close $log
exit
