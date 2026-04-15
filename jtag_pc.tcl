connect
after 2000

fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

targets -set 9
stop
after 500

set pc [rrd pc]
puts "PC: $pc"

con

puts "Done."
exit
