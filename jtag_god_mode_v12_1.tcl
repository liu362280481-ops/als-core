connect

puts ">>> 1. 触发全硅基系统级大复位 (System Reset)，粉碎一切历史 AXI 死锁！"
targets -set -nocase -filter {name =~ "*PSU*"}
rst -system
after 2000

puts ">>> 2. 瘫痪 PMU 安全门限..."
targets -set -nocase -filter {name =~ "*PSU*"}
mask_write 0xFFCA0038 0x1FF 0x1FF
after 500

puts ">>> 3. <创世第一法则> 优先铺设 16nm 逻辑门硬件底盘！"
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

puts ">>> 4. <创世第二法则> 硬件就位后，执行 psu_init 熟化时钟与 DDR4..."
source ./vitis_workspace/als_platform/hw/sdt/psu_init.tcl
psu_init
after 1000

puts ">>> 5. 移除跨维隔离膜，打通 PS-PL 绝对安全的因果动脉..."
psu_ps_pl_isolation_removal
after 1000
psu_ps_pl_reset_config
after 1000

puts ">>> 6. 锁定 A53 主脑，洗净残存寄存器..."
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor -clear-registers
after 500

puts ">>> 7. 灵魂直注：向没有任何 AXI 扰动的 0x0 纯净地址下载 ELF！"
dow ./vitis_workspace/als_app/build/als_app.elf
after 500

puts ">>> 8. 释放时间轴，引爆奇点！"
con
exit
