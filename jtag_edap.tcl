connect
after 2000

fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

targets -set 9
stop
after 500

puts "Read via EDAP (Debug Access Port)..."
puts "Try reading PC via ARM PC sample register..."
mrd 0x80030000 4

puts "Read ROM table..."
mrd 0x80000000 4

con

exit
