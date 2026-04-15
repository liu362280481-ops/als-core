set logfile [open /tmp/xsdb_genesis2.log w]

connect
after 1000

puts $logfile "0. Targets visible:"
puts $logfile [targets]

puts $logfile "1. Release APU L2 Cache reset..."
rst -set
after 500

puts $logfile "2. Select and stop Cortex-A53 #0..."
targets -set 9
stop
after 500

puts $logfile "3. Loading bitstream to PL..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 1000
puts $logfile "BITSTREAM LOADED"

puts $logfile "4. Downloading ELF..."
targets -set 9
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000

puts $logfile "5. Starting..."
con

puts $logfile "======================================"
puts $logfile "Genesis complete!"
puts $logfile "======================================"
close $logfile
exit
