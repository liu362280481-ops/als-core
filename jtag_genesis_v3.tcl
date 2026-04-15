connect
after 2000

puts "1. Check targets:"
puts [targets]

puts "2. Unlock security..."
targets -set 5
mask_write 0xFFCA0038 0x1C0 0x1C0
after 500

puts "3. Inject PMU firmware..."
targets -set 3
dow ./pmu_isolated_ws2/pmu_plat2/zynqmp_pmufw/build/pmufw.elf
con
after 500

puts "4. Load bitstream to PL..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 1000
puts "PL bitstream loaded."

puts "5. Wake A53 #0..."
targets -set 10
rst -processor
dow ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
con

puts "5b. Wait 5s for DDR training..."
after 5000
stop

puts "6. Download ALS app ELF..."
dow ./vitis_workspace/als_app/build/als_app.elf
con

puts "=========================================="
puts "V3 Genesis complete. Check UART."
puts "=========================================="
exit
