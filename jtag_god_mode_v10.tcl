connect

puts ">>> 1. 瘫痪 PMU 安全门限，接管系统最高权限..."
targets -set -nocase -filter {name =~ "*PSU*"}
mask_write 0xFFCA0038 0x1C0 0x1C0
after 500

puts ">>> 2. [绝对寂静] 在 PL 端毫无生机的状态下，执行官方 psu_init 熟化 DDR4..."
source $PSU_INIT_PATH
psu_init
after 1000

puts ">>> 3. [时空隔离直注] 趁着没有 AXI 洪流干扰，安全注入灵魂探针！"
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
dow $ELF_PATH
after 500

puts ">>> 4. 灵魂部署完毕！现在开始灌入 16nm 硅基宇宙逻辑门拓扑..."
fpga $BIT_PATH
after 2000

puts ">>> 5. 移除跨维隔离膜，打通 PS-PL 互联动脉..."
targets -set -nocase -filter {name =~ "*A53*#0"}
psu_ps_pl_isolation_removal
after 500
psu_ps_pl_reset_config
after 500

puts ">>> 6. 释放时间轴，引爆奇点！"
con
exit
