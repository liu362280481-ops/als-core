connect

puts ">>> 1. 瘫痪 PMU 安全门限..."
targets -set -nocase -filter {name =~ "*PSU*"}
mask_write 0xFFCA0038 0x1C0 0x1C0
after 500

puts ">>> 2. 灌入 PL 物理网表..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 1000

puts ">>> 3. [可选] 唤醒 PMU 协处理器..."
if { "./vitis_workspace/als_platform/export/als_platform/sw/pmu_domain/qemu/pmufw.elf" != "" } {
    targets -set -nocase -filter {name =~ "*MicroBlaze PMU*"}
    catch {
        dow ./vitis_workspace/als_platform/export/als_platform/sw/pmu_domain/qemu/pmufw.elf
        con
    }
    after 500
}

puts ">>> 4. 植入全能拓荒者 (FSBL)，由 Xilinx 原生代码彻底熟化 DDR4、MMU 与 Cache..."
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor -clear-registers
dow ./vitis_workspace/als_platform/export/als_platform/sw/boot/fsbl.elf
con

puts ">>> 5. 等待 FSBL 物理开荒 (5秒)..."
after 5000
stop

puts ">>> 6. 灵魂直注：此时 Cache 混沌已完美解除，直接下载探针！"
dow ./vitis_workspace/als_app/build/als_app.elf
after 500

puts ">>> 7. 释放时间轴，引爆奇点！"
con
exit
