# ==============================================================================
# [ALS-CORE] 终极物理点火序列 (全自动寻址版)
# ==============================================================================

# 绝对物理寻址（已自动对齐到最新生成的纯净工作空间）
set BIT_FILE      "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_system_wrapper.bit"
set PSU_INIT_TCL  "/home/liujiawei/ALS_Silicon_Workspace/als_vitis_v14_xsct/als_platform_pure/hw/psu_init.tcl"
set ELF_FILE      "/home/liujiawei/ALS_Silicon_Workspace/als_vitis_v14_xsct/als_app_pure/Debug/als_app_pure.elf"

puts "\[SYSTEM\] 创世时钟启动。开始向 Zynq UltraScale+ 注入灵魂..."

puts ">>> 0. 建立 JTAG 高维神经连接..."
connect

puts ">>> 1. 夺取 PSU 控制权，执行宇宙级大复位..."
targets -set -filter {name =~ "*PSU*"}
rst -system
after 2000 

puts ">>> 2. 铺设 103K 逻辑门底物 (烧录 bitstream)..."
targets -set -filter {name =~ "*PSU*"}
fpga $BIT_FILE
after 1000

puts ">>> 3. 熟化时钟池与 DDR4 内存阵列 (执行 psu_init)..."
source $PSU_INIT_TCL
psu_init
after 1000
psu_post_config
after 1000

puts ">>> 4. 靶向锁定主脑 (Cortex-A53 #0)，洗净脏寄存器..."
targets -set -filter {name =~ "*Cortex-A53 #0*"}
rst -processor
after 500

puts ">>> 5. 注射 72KB 纯净 C 语言探针..."
dow -clear $ELF_FILE
after 500

puts ">>> 6. 拆除隔离膜，系统主权移交 (con)..."
con

puts "======================================================================="
puts " \[SUCCESS\] 点火序列完成！请立刻观测串口终端！"
puts "======================================================================="
