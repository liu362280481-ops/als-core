# bypass_simple.tcl - 最简化 HP1 连接
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set dma  [get_bd_cells axi_dma_0]

puts "\n=== 1. GP3 -> HP1 ==="
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq
puts "完成"

puts "\n=== 2. 创建 axi_smc_1 ==="
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1
puts "完成"

puts "\n=== 3. S2MM -> axi_smc_1 -> HP1 ==="
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_net [get_bd_intf_nets -of_objects $s2mm]
disconnect_bd_intf_net $old_net -obj $s2mm
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
puts "完成"

puts "\n=== 4. 时钟复位 ==="
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_smc_1/aclk]
connect_bd_net [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins axi_smc_1/aresetn]
puts "完成"

puts "\n=== 5. 地址自动分配 ==="
assign_bd_address
puts "完成"

puts "\n=== 6. 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证: $rc"
if {$rc == 0} {
  puts "验证通过!"
} else {
  puts "验证有错误: $err"
}

save_bd_design
puts "BD 已保存"

puts "\n=== 连接确认 ==="
puts "MM2S -> [get_property NAME [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]]]"
puts "S2MM -> [get_property NAME [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]]]"

puts "\n=== HP 端口列表 ==="
foreach p [get_bd_intf_pins -of_objects $zynq] {
  puts "  [get_property NAME $p]"
}

exit
