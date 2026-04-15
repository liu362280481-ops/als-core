connect

puts ">>> 1. 瘫痪 PMU 安全门限..."
targets -set -nocase -filter {name =~ "*PSU*"}
mask_write 0xFFCA0038 0x1C0 0x1C0
after 500

puts ">>> 2. 灌入 PL 物理网表..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 1000

puts ">>> 3. 强行熟化 DDR4..."
source ./vitis_workspace/als_platform/hw/sdt/psu_init.tcl
psu_init
after 1000
psu_ps_pl_isolation_removal
after 500
psu_ps_pl_reset_config
after 500

puts ">>> 4. 执行绝对物理复位，由硬件底层强制洗净 EL3 寄存器..."
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor -clear-registers
after 500

puts ">>> 5. 灵魂直注：安全屏障与 Cache 混沌已解除，直接下载探针！"
dow ./vitis_workspace/als_app/build/als_app.elf
after 500

puts ">>> 6. 释放时间轴，引爆奇点！"
con
exit
