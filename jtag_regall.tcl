connect
after 2000

fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

targets -set 9
stop
after 500

puts "Reading ALL registers..."
set regs [rrd]
puts "$regs"

con

exit
