connect
after 2000

puts "Targets:"
puts [targets]

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
