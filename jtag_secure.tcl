connect
after 2000

puts "Targets:"
puts [targets]

puts "Select PSU (target 5)..."
targets -set 5

puts "Try mask_write to unlock security..."
mask_write 0xFFCA0038 0x1C0 0x1C0

after 500

puts "Select A53 #0..."
targets -set 10

puts "Stop..."
stop
after 500

puts "Read PC..."
set pc [rrd pc]
puts "PC: $pc"

con

exit
