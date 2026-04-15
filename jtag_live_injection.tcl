puts ">>> 1. 连接 JTAG 物理层..."
connect

puts ">>> 2. 解锁 PMU 并注入固件..."
targets -set 2
dow ./pmu_isolated_ws2/pmu_plat2/zynqmp_pmufw/build/pmufw.elf
con
after 500

puts ">>> 3. 锁定 Cortex-A53 #0 并注入 FSBL..."
targets -set 9
rst -processor
dow ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
con

puts ">>> 4. 给予 5 秒 FSBL 初始化时间..."
after 5000

puts ">>> 5. 冻结时间！提取死亡坐标..."
stop
after 500

puts "=========================================================="
puts "💀 【硅基死亡坐标提取报告】"
puts "=========================================================="
puts "【PC 指针】:"
rrd pc
puts "----------------------------------------------------------"
puts "【寄存器快照】:"
rrd
puts "=========================================================="
exit
