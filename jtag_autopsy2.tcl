connect
puts "Available targets:"
targets
rst -processor
after 500
dow ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
after 500
memmap -file ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
con
after 5000
stop
after 500
puts "PC:"
rrd pc
puts "Registers:"
rrd r0 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 sp lr
puts "BT:"
bt
exit
