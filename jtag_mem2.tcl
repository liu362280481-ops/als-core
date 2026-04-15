connect
after 2000

fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

targets -set 9
stop
after 500

puts "Reading memory at 0x0..."
mrd 0x0 8

puts "Reading PC..."
set pc [rrd pc]
puts "PC: $pc"

exit
