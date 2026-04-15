# hp1_final.tcl - 双动脉分离术终版
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

puts "\n=== 3. S2MM 链路重连 ==="
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_net [get_bd_intf_nets -of_objects $s2mm]
if {[llength $old_net] > 0} {
  disconnect_bd_intf_net $old_net -obj $s2mm
  puts "已断开 S2MM 旧连接"
}
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
puts "S2MM -> axi_smc_1 -> S_AXI_HP1_FPD"

puts "\n=== 4. 时钟复位 ==="
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_smc_1/aclk]
connect_bd_net [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins axi_smc_1/aresetn]
puts "完成"

puts "\n=== 5. 地址段修复 ==="
set s2mm_as [get_bd_addr_spaces -of_objects $dma -filter "NAME =~ *S2MM*"]
set mm2s_as [get_bd_addr_spaces -of_objects $dma -filter "NAME =~ *MM2S*"]

# 删除 S2MM 的 HP0 段
puts "删除 S2MM HP0 段..."
set del_list {}
foreach seg [get_bd_addr_segs -of_objects $s2mm_as] {
  if {[string match "*HP0*" [get_property NAME $seg]]} {
    lappend del_list $seg
  }
}
if {[llength $del_list] > 0} {
  delete_bd_objs $del_list
  puts "  已删除 [llength $del_list] 个"
}

# 删除 MM2S 的 HP0 DDR 段
puts "删除 MM2S HP0 DDR 段..."
set del_list_mm2s {}
foreach seg [get_bd_addr_segs -of_objects $mm2s_as] {
  set sn [get_property NAME $seg]
  if {$sn eq "HP0_DDR_LOW" || [string match "*HP0*" $sn]} {
    lappend del_list_mm2s $seg
  }
}
if {[llength $del_list_mm2s] > 0} {
  delete_bd_objs $del_list_mm2s
  puts "  已删除 [llength $del_list_mm2s] 个"
}

# 获取段对象
set hp1_ddr_obj ""
set hp0_ddr_obj ""
foreach seg [get_bd_addr_segs] {
  if {[get_property NAME $seg] eq "HP1_DDR_LOW"} { set hp1_ddr_obj $seg }
  if {[get_property NAME $seg] eq "HP0_DDR_LOW"} { set hp0_ddr_obj $seg }
}
puts "HP1_DDR: $hp1_ddr_obj"
puts "HP0_DDR: $hp0_ddr_obj"

# include HP1_DDR 到 S2MM
if {$hp1_ddr_obj ne ""} {
  puts "include HP1_DDR -> S2MM..."
  set rc [catch {include_bd_addr_seg $s2mm_as $hp1_ddr_obj} err]
  if {$rc} { puts "  失败: $err" } else { puts "  成功" }
}

# include HP0_DDR 到 MM2S
if {$hp0_ddr_obj ne ""} {
  puts "include HP0_DDR -> MM2S..."
  set rc [catch {include_bd_addr_seg $mm2s_as $hp0_ddr_obj} err]
  if {$rc} { puts "  失败: $err" } else { puts "  成功" }
}

assign_bd_address

puts "\n=== 6. 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证结果: $rc"
if {$rc == 0} { puts "验证通过!" } else { puts "有错误: [string range $err 0 300]" }

save_bd_design
puts "BD 已保存"

puts "\n=== 最终地址 ==="
foreach seg [get_bd_addr_segs] {
  puts "  [get_property NAME $seg] = [get_property OFFSET $seg] / [get_property RANGE $seg]"
}

puts "\n=== 连接 ==="
puts "MM2S -> [get_property NAME [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]]]"
puts "S2MM -> [get_property NAME [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]]]"

puts "\n=== HP 端口 ==="
foreach p [get_bd_intf_pins -of_objects $zynq] { puts "  [get_property NAME $p]" }

exit
