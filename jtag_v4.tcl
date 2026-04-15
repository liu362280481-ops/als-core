connect
after 2000

puts "0. Check targets:"
puts [targets]

puts "1. Load bitstream to PL..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000
puts "PL loaded."

puts "2. Check targets after PL load:"
puts [targets]

exit
