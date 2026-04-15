set logfile [open /tmp/xsdb_genesis.log w]

puts $logfile "0. Connecting to hw_server..."
flush $logfile
connect
after 1000

puts $logfile "1. Suspending ARM core"
flush $logfile
targets -set 9
stop
after 500

puts $logfile "2. Loading bitstream to PL"
flush $logfile
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 1000
puts $logfile "BITSTREAM LOADED"
flush $logfile

puts $logfile "3. Downloading ELF to DDR"
flush $logfile
targets -set 9
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000

puts $logfile "4. Releasing cores"
flush $logfile
con

puts $logfile "======================================"
puts $logfile "Genesis complete. Check UART."
puts $logfile "======================================"
flush $logfile
close $logfile
exit
