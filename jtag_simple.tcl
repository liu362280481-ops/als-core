connect
after 2000

puts "1. Load bitstream to PL..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

puts "2. Select A53 #0..."
targets -set 9

puts "3. Download FSBL..."
dow ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
after 1000

puts "4. Download app ELF..."
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000

puts "5. Start..."
con

puts "=========================================="
puts "Genesis complete. Check UART."
puts "=========================================="
exit
