connect
after 2000

fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

targets -set 9
stop
after 500

puts "Reading r0..."
set r0 [rrd r0]
puts "r0: $r0"

puts "Reading sp..."
set sp [rrd sp]
puts "sp: $sp"

con

exit
