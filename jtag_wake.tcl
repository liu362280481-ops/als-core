connect
after 2000

puts "Targets:"
puts [targets]

puts "1. Select PMU..."
targets -set 3

puts "2. Try to read PMU regs..."
rrd

puts "3. Read PMU memory..."
mrd 0xFF990000 4

puts "Done."
exit
