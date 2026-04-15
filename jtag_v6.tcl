connect
after 2000

puts "1. Check targets:"
puts [targets]

puts "2. Load bitstream first (without PMU injection)..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000
puts "PL loaded."

puts "3. Check targets after:"
puts [targets]

puts "4. Try A53 #0..."
targets -set 9
stop
after 500

puts "Done."
exit
