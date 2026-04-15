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

puts ">>> 4. <因果律封印> 在复位原点(0xFFFF0000)植入衔尾蛇死循环 (0x14000000)..."
targets -set -nocase -filter {name =~ "*A53*#0"}
mwr 0xffff0000 0x14000000
after 100

puts ">>> 5. 执行纯净物理复位，清洗全部寄存器与乱码记忆..."
rst -processor -clear-registers
after 500

puts ">>> 6. 灵魂直注：此时 CPU 处于完美稳态，Cache 屏障解除！"
dow ./vitis_workspace/als_app/build/als_app.elf
after 500

puts ">>> 7. 释放时间轴，引爆奇点！"
con
exit
