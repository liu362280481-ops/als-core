connect
after 2000

puts "Targets:"
puts [targets]

puts "1. Try to access PSU (parent)..."
targets -set 4

puts "2. Try system reset..."
rst -system
after 500

puts "3. Check targets:"
puts [targets]

exit
