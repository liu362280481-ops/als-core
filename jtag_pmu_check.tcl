connect
after 2000

puts "1. Select PSU..."
targets -set 5

puts "2. Try to read PSU registers..."
rrd

puts "3. Read memory at 0xFF5C0000 (PMU global control)..."
mrd 0xFF5C0000 4

exit
