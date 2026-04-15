set logfile [open /tmp/xsdb_genesis5.log w]

connect
after 1000

puts $logfile "0. Targets:"
puts $logfile [targets]

puts $logfile "1. Loading bitstream to PL..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000
puts $logfile "BITSTREAM LOADED"

puts $logfile "2. Release PL reset..."
targets -set 3
rst -pl -clear
after 500

puts $logfile "3. Select A53 #0..."
targets -set 9

puts $logfile "4. Download ELF..."
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000

puts $logfile "5. Start..."
con

puts $logfile "======================================"
puts $logfile "Genesis complete!"
puts $logfile "======================================"
close $logfile
exit
