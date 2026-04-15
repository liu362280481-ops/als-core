connect
after 2000

puts "1. Load bitstream..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000
puts "PL loaded."

puts "2. Select A53 #0..."
targets -set 9

puts "3. Read memory at 0x0..."
mrd 0x0 8

puts "Done."
exit
