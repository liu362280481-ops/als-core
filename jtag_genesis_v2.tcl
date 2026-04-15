connect
after 2000
puts "1. Mask write to unlock security..."
targets -set 4
mask_write 0xFFCA0038 0x1C0 0x1C0
after 500

puts "2. Inject PMU firmware..."
targets -set 2
dow ./pmu_isolated_ws2/pmu_plat2/zynqmp_pmufw/build/pmufw.elf
con
after 500

puts "3. Reset and inject FSBL..."
targets -set 9
rst -processor
dow ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
con
after 5000

puts "4. Load bitstream to PL..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 1000

puts "5. Download ALS app ELF..."
targets -set 9
dow ./vitis_workspace/als_app/build/als_app.elf
con

puts "=========================================="
puts "Genesis complete. Check UART."
puts "=========================================="
exit
