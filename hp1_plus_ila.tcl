# hp1_plus_ila.tcl - HP1 分离 + ILA 调试标记 (完整版)
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set dma  [get_bd_cells axi_dma_0]

puts "\n=== HP1 分离 ==="
puts "1. GP3 -> HP1..."
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq
puts "  完成"

puts "2. 创建 axi_smc_1..."
catch {create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1}
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1
puts "  axi_smc_1 创建完成"

puts "3. S2MM 链路分离..."
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_net [get_bd_intf_nets -of $s2mm]
if {[llength $old_net] > 0} { disconnect_bd_intf_net $old_net -obj $s2mm }
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
puts "  S2MM -> axi_smc_1 -> HP1"

puts "4. 时钟复位..."
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_smc_1/aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins axi_smc_1/aresetn]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]
puts "  时钟复位完成"

puts "5. 清理悬空网络..."
catch {delete_bd_objs [get_bd_nets axi_dma_0_M_AXI_S2MM]}
catch {delete_bd_objs [get_bd_nets axi_dma_0_M_AXI_SG]}

puts "6. 地址段修复..."
set s2mm_as [get_bd_addr_spaces -of $dma -filter "NAME =~ *S2MM*"]
set mm2s_as [get_bd_addr_spaces -of $dma -filter "NAME =~ *MM2S*"]
foreach seg [get_bd_addr_segs -of $s2mm_as] {
  if {[string match "*HP0*" [get_property NAME $seg]]} { delete_bd_objs $seg }
}
foreach seg [get_bd_addr_segs -of $mm2s_as] {
  if {[get_property NAME $seg] eq "HP0_DDR_LOW"} { delete_bd_objs $seg }
}
assign_bd_address
puts "  地址分配完成"

puts "\n=== ILA 调试标记 ==="
puts "7. 标记 AXI-Stream 信号..."
set sigs {s_axis_tvalid s_axis_tready s_axis_tlast s_axis_tdata m_axis_tvalid m_axis_tready m_axis_tlast m_axis_tdata}
foreach sig $sigs {
  set pins [get_bd_pins -of [get_bd_cells als_core_0] -filter "NAME =~ *$sig*"]
  foreach pin $pins {
    if {$pin ne ""} {
      set n [get_bd_nets -of $pin]
      if {$n ne ""} {
        catch {set_property MARK_DEBUG true $n}
        puts "  标记: $sig -> [get_property NAME $n]"
      }
    }
  }
}

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证: $rc"
if {$rc == 0} { puts "验证通过!" } else { puts "警告: [string range $err 0 200]" }

save_bd_design
puts "BD 已保存"

puts "\n=== HP1 连接确认 ==="
puts "MM2S -> [get_property NAME [get_bd_intf_nets -of [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]]]"
puts "S2MM -> [get_property NAME [get_bd_intf_nets -of [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]]]"
puts "HP0  -> [get_property NAME [get_bd_intf_nets -of [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]]]"
puts "HP1  -> [get_property NAME [get_bd_intf_nets -of [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]]]"

puts "\n=== ILA 时钟确认 ==="
puts "saxihp0_fpd_aclk -> [get_property NAME [get_bd_nets -of [get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk]]]"
puts "saxihp1_fpd_aclk -> [get_property NAME [get_bd_nets -of [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]]]"

exit
