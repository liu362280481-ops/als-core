connect
after 2000

fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

puts "Check targets:"
puts [targets]

puts "Select APU (target 9)..."
targets -set 9

puts "Stop APU..."
stop
after 500

puts "Read PC via rrd..."
set pc [rrd pc]
puts "PC: $pc"

con

exit
