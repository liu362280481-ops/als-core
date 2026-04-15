connect
after 2000

puts "Targets:"
puts [targets]

puts "1. Stop A53 #0 (target 10)..."
targets -set 10
stop
after 500

puts "2. Read PC..."
set pc [rrd pc]
puts "PC: $pc"

puts "3. Download FSBL..."
dow ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
after 500

puts "4. Start..."
con

puts "Genesis: Step 1 done."
exit
