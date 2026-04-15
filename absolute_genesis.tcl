puts ">>> 0. 建立 JTAG 物理连接并等待握手..."
connect
after 3000

puts ">>> 1. 锁定 APU 总线并执行全局硬件复位..."
targets -set -filter {name =~ "*APU*"}
rst -system
after 3000

puts ">>> 2. 注入时钟池与初始化寄存器 (psu_init)..."
source "/home/liujiawei/ALS_Silicon_Workspace/als_vitis_v14_xsct/als_platform_pure/hw/psu_init.tcl"
psu_init
after 1000

puts ">>> 3. 铺设 16nm 物理底物 (Bitstream)..."
fpga "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_system_wrapper.bit"
after 1000

puts ">>> 4. 撕开 PS-PL 电源隔离膜..."
psu_post_config
psu_ps_pl_isolation_removal
psu_ps_pl_reset_config
after 1000

puts ">>> 5. 靶向 Cortex-A53 #0，准备灵魂注入..."
targets -set -filter {name =~ "*Cortex-A53 #0*"}
rst -processor -clear-registers
after 1000

puts ">>> 6. 强行下载 V14 Armored 探针..."
dow "/home/liujiawei/ALS_Silicon_Workspace/als_vitis_v14_xsct/als_app_pure/Debug/als_app_pure.elf"
after 500

puts ">>> 7. 观测指令指针并全速点火！"
rrd pc
con
