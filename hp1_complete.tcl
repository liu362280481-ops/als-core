# hp1_complete.tcl - 双动脉分离完整版（含悬空网络清理）
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set dma  [get_bd_cells axi_dma_0]

puts "1. GP3 -> HP1..."
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq

puts "2. 创建 axi_smc_1..."
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1

puts "3. S2MM 链路重连..."
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_net [get_bd_intf_nets -of_objects $s2mm]
if {[llength $old_net] > 0} {
  puts "  断开: [get_property NAME $old_net]"
  disconnect_bd_intf_net $old_net -obj $s2mm
}
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
puts "  S2MM -> axi_smc_1 -> HP1"

puts "4. 时钟复位..."
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_smc_1/aclk]
connect_bd_net [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins axi_smc_1/aresetn]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]
puts "  时钟完成"

puts "5. 清理悬空网络..."
# 删除旧的 S2MM 和 S2MM_SG 悬空网络
foreach net_name {axi_dma_0_M_AXI_S2MM axi_dma_0_M_AXI_SG} {
  set dangling_nets [get_bd_nets $net_name]
  if {[llength $dangling_nets] > 0} {
    puts "  删除悬空网络: $net_name"
    delete_bd_objs $dangling_nets
  }
}

puts "6. 地址段重映射..."
set s2mm_as [get_bd_addr_spaces -of_objects $dma -filter "NAME =~ *S2MM*"]
set mm2s_as [get_bd_addr_spaces -of_objects $dma -filter "NAME =~ *MM2S*"]

# 删除 S2MM 的 HP0 段
puts "  删除 S2MM HP0 段..."
foreach seg [get_bd_addr_segs -of_objects $s2mm_as] {
  if {[string match "*HP0*" [get_property NAME $seg]]} {
    puts "    删除: [get_property NAME $seg]"
    delete_bd_objs $seg
  }
}

# 删除 MM2S 的 HP0 DDR 段（保留 OCM）
puts "  删除 MM2S HP0 DDR 段..."
foreach seg [get_bd_addr_segs -of_objects $mm2s_as] {
  if {[get_property NAME $seg] eq "HP0_DDR_LOW"} {
    puts "    删除: HP0_DDR_LOW"
    delete_bd_objs $seg
  }
}

# 重新分配
assign_bd_address

puts "7. 验证..."
set rc [catch {validate_bd_design} err]
puts "验证: $rc"
if {$rc == 0} {
  puts "验证通过!"
}

save_bd_design
puts "BD 已保存"

puts "\n=== 连接确认 ==="
puts "MM2S -> [get_property NAME [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]]]"
puts "S2MM -> [get_property NAME [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]]]"

puts "\n=== 地址 ==="
foreach seg [get_bd_addr_segs] {
  puts "  [get_property NAME $seg] = [get_property OFFSET $seg] / [get_property RANGE $seg]"
}

exit
