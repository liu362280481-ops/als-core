connect

puts ">>> 1. 瘫痪 PMU 安全门限..."
targets -set -nocase -filter {name =~ "*PSU*"}
mask_write 0xFFCA0038 0x1C0 0x1C0
after 500

puts ">>> 2. <可选> 唤醒 PMU 协处理器..."
if { "./vitis_workspace/als_platform/export/als_platform/sw/pmu_domain/qemu/pmufw.elf" != "" } {
    targets -set -nocase -filter {name =~ "*MicroBlaze PMU*"}
    catch {
        dow ./vitis_workspace/als_platform/export/als_platform/sw/pmu_domain/qemu/pmufw.elf
        con
    }
    after 500
}

puts ">>> 3. <时空反转> 先行植入 FSBL，在绝对安静中熟化主脑与 AXI 桥接闸门..."
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor -clear-registers
dow ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
con

puts ">>> 4. 等待 FSBL 建立宇宙物理法则 (5秒)..."
after 5000
stop

puts ">>> 5. 主脑已完全就绪！开始灌入 PL 物理网表，迎接自由运行核心的 AXI 洪流！"
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 2000

puts ">>> 6. 灵魂直注：向已熟化且安全的 DDR4 空间下载探针！"
targets -set -nocase -filter {name =~ "*A53*#0"}
dow ./vitis_workspace/als_app/build/als_app.elf
after 500

puts ">>> 7. 释放时间轴，引爆奇点！"
con
exit
