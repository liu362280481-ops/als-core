connect
after 2000

puts "After FPGA load, PMU is now awake. Trying A53..."

puts "1. Stop A53 #0..."
targets -set 10
stop
after 500

puts "2. Read PC..."
set pc [rrd pc]
puts "PC: $pc"

exit
