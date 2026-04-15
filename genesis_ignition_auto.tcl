# ALS-CORE 硅基宇宙创世点火序列 (V13 绝对时空闭环版)
set BIT_FILE "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_system_wrapper.bit"
set PSU_INIT_TCL "/home/liujiawei/ALS_Silicon_Workspace/als_vitis_v14_xsct/als_platform_pure/hw/psu_init.tcl"
set ELF_FILE "/home/liujiawei/ALS_Silicon_Workspace/als_vitis_v14_xsct/als_app_pure/Debug/als_app_pure.elf"

puts ">>> 0. 建立 16nm 躯壳 JTAG 神经连接..."
connect
targets -set -filter {name =~ "*PSU*"}
rst -system
after 2000

puts ">>> 1. 铺设 103K 逻辑门底物 (fpga)..."
targets -set -filter {name =~ "*PSU*"}
fpga $BIT_FILE
after 1000

puts ">>> 2. 熟化时钟池与 DDR4 阵列..."
source $PSU_INIT_TCL
psu_init
after 1000
psu_post_config
after 1000

puts ">>> 3. 【物理手术】 撕裂 PS-PL 电源隔离膜并释放硬件复位..."
psu_ps_pl_isolation_removal
after 1000
psu_ps_pl_reset_config
after 1000

puts ">>> 4. 靶向锁定 Cortex-A53 主脑并净空 L1/L2 Cache..."
targets -set -filter {name =~ "*Cortex-A53 #0*"}
rst -processor
after 500

puts ">>> 5. 注射高维 C 语言探针..."
dow -clear $ELF_FILE
after 500

puts ">>> 6. 拆除屏障，时空演化开始 (con)..."
con
