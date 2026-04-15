connect
after 2000

fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

targets -set 9
stop
after 500

puts "Read PC from target 9..."
set pc [rrd pc]
puts "PC: $pc"

puts "Read r0 from target 9..."
set r0 [rrd r0]
puts "r0: $r0"

con

exit
