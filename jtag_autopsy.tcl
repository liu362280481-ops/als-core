connect
targets -set -filter {name =~ "Cortex-A53 #0*"}
stop
after 500
memmap -file ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
puts "=========================================================="
puts "💀 【硅基死亡坐标提取报告】"
puts "=========================================================="
puts "【1】核心当前状态与 PC 指针:"
rrd pc
puts "----------------------------------------------------------"
puts "【2】致命因果律回溯 (Call Stack Backtrace):"
bt
puts "=========================================================="
exit
