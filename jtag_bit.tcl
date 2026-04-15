connect
after 2000

puts "Targets:"
puts [targets]

puts "1. Load bitstream to PL..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

puts "Bitstream load attempted."

puts "2. Check if PL is configured..."
targets -set 4
puts "PL target selected."

puts "Done."
exit
