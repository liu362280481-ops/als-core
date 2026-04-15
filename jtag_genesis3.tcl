set logfile [open /tmp/xsdb_genesis3.log w]

connect
after 1000

puts $logfile "0. Targets:"
puts $logfile [targets]

puts $logfile "1. Loading bitstream to PL first..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000
puts $logfile "BITSTREAM LOADED - Check DONE LED"

puts $logfile "2. Select Cortex-A53 #0..."
targets -set 9

puts $logfile "3. Download ELF to DDR..."
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000

puts $logfile "4. Start cores..."
con

puts $logfile "======================================"
puts $logfile "Genesis complete!"
puts $logfile "======================================"
close $logfile
exit
