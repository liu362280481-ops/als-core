set log [open /tmp/xsct_dap.log w]

connect -url TCP:127.0.0.1:3121
after 2000

puts $log "1. Load bitstream..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

puts $log "2. Select target 5 (PSU)..."
targets -set 5

puts $log "3. Read DAP registers..."
# DAP base address is 0x80000000 for the APB
mrd 0x80000000 16

puts $log "4. Read DAP status..."
# DAP status register is at offset 0x4
mrd 0x80000004 4

close $log
exit
