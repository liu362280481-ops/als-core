# bypass_hp1_v2.tcl - 双动脉分离术 (修复时钟)
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set smc1 [get_bd_cells axi_smc_1]

puts "\n=== Step 6: 手动连接时钟复位 ==="
# 获取系统时钟和复位
set sys_clk [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
set sys_rst [get_bd_pins rst_ps8_0_99M/peripheral_aresetn]

# 连接到 axi_smc_1
connect_bd_net $sys_clk [get_bd_pins axi_smc_1/aclk]
connect_bd_net $sys_rst [get_bd_pins axi_smc_1/aresetn]
puts "时钟复位已手动连接"

puts "\n=== Step 7: 地址分配 ==="
assign_bd_address
puts "地址已分配"

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
if {$rc} {
  puts "验证失败: $err"
} else {
  puts "验证通过!"
}

save_bd_design
puts "BD 已保存"

puts "\n=== 最终端口列表 ==="
foreach p [get_bd_intf_pins -of_objects $zynq] { puts "  [get_property NAME $p]" }

puts "\n=== DMA 连接确认 ==="
set mm2s [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set mm2s_net [get_bd_intf_nets -of_objects $mm2s]
set s2mm_net [get_bd_intf_nets -of_objects $s2mm]
puts "MM2S -> [get_property NAME $mm2s_net]"
puts "S2MM -> [get_property NAME $s2mm_net]"

exit
