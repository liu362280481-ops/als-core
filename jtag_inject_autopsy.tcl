connect
targets -set -filter {name =~ "Cortex-A53 #0*"}
rst -processor
after 500
puts ">>> 正在向 16nm 硅基底物强注 FSBL..."
dow ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
after 500
memmap -file ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
puts ">>> 强行释放时钟，点火！"
con
after 5000
stop
after 500
puts "=========================================================="
puts "💀 【硅基死亡坐标提取报告】"
puts "=========================================================="
puts "【1】PC 指针:"
rrd pc
puts "----------------------------------------------------------"
puts "【2】寄存器:"
rrd r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 sp lr pc cpsr
puts "----------------------------------------------------------"
puts "【3】Call Stack Backtrace:"
bt
puts "=========================================================="
exit
