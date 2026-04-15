connect
after 2000

puts "1. Load bitstream..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000
puts "PL loaded."

puts "2. Select A53 #0..."
targets -set 9

puts "3. Stop..."
stop
after 500

puts "4. Read PC..."
set pc [rrd pc]
puts "PC: $pc"

puts "5. Download app ELF..."
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000

puts "6. Go..."
con

puts "Done. Check UART."
exit
