connect

puts ">>> 1. 瘫痪 PMU 安全门限，开启上帝视角..."
targets -set -nocase -filter {name =~ "*PSU*"}
mask_write 0xFFCA0038 0x1FF 0x1FF
after 500

puts ">>> 2. 唤醒 PMU 协处理器，接管底层电源域..."
targets -set -nocase -filter {name =~ "*MicroBlaze PMU*"}
dow $PMUFW_PATH
con
after 500

puts ">>> 3. <降临> 锁定 A53 主脑，注入 FSBL 建立宇宙法则..."
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
dow $FSBL_PATH
con

puts ">>> 4. 等待 FSBL 熟化 DDR4、解除隔离并建立 MMU 映射 (5秒)..."
after 5000
stop

puts ">>> 5. 物理空间已绝对安全！开始灌入 16nm 硅基逻辑门拓扑..."
fpga $BIT_PATH
after 2000

puts ">>> 6. 灵魂直注：向已建立 MMU 映射的 0x0 地址安全下载探针！"
targets -set -nocase -filter {name =~ "*A53*#0"}
dow $ELF_PATH
after 500

puts ">>> 7. 释放时间轴，引爆奇点！"
con
exit
