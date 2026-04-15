# bypass_hp1_final.tcl - 双动脉分离术（地址修复版）
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set dma  [get_bd_cells axi_dma_0]

puts "\n=== 1. 激活 HP1 (GP3) ==="
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq
puts "HP1 激活完成"

puts "\n=== 2. 创建 axi_smc_1 ==="
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1
puts "axi_smc_1 创建完成"

puts "\n=== 3. S2MM 链路分离 ==="
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_net [get_bd_intf_nets -of_objects $s2mm]
puts "S2MM 连接到: [get_property NAME $old_net]"
disconnect_bd_intf_net $old_net -obj $s2mm
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
puts "S2MM -> axi_smc_1 -> S_AXI_HP1_FPD"

puts "\n=== 4. 时钟复位 ==="
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_smc_1/aclk]
connect_bd_net [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins axi_smc_1/aresetn]
puts "时钟复位完成"

puts "\n=== 5. 地址段重映射 ==="
# 列出所有地址段
puts "当前地址段:"
foreach seg [get_bd_addr_segs] {
  puts "  [get_property NAME $seg] = [get_property OFFSET $seg] / [get_property RANGE $seg]"
}

# 删除 S2MM 的 HP0 段 (HP0_DDR_LOW 和 HP0_LPS_OCM)
puts "\n删除 S2MM 的 HP0 地址段..."
foreach seg [get_bd_addr_segs -of_objects [get_bd_addr_spaces Data_S2MM]] {
  set seg_name [get_property NAME $seg]
  puts "  S2MM seg: $seg_name"
  if {[string match "*HP0*" $seg_name] || [string match "*HP1*" $seg_name]} {
    puts "  删除: $seg_name"
    delete_bd_objs $seg
  }
}

# 删除 MM2S 的 HP0 DDR 段
puts "\n删除 MM2S 的 HP0 地址段..."
foreach seg [get_bd_addr_segs -of_objects [get_bd_addr_spaces Data_MM2S]] {
  set seg_name [get_property NAME $seg]
  puts "  MM2S seg: $seg_name"
  if {[string match "*HP0*" $seg_name]} {
    puts "  删除: $seg_name"
    delete_bd_objs $seg
  }
}

# 包含 HP1_DDR 到 S2MM
puts "\n包含 HP1_DDR 到 S2MM..."
set hp1_ddr_segs {}
foreach seg [get_bd_addr_segs] {
  set seg_name [get_property NAME $seg]
  if {$seg_name eq "HP1_DDR_LOW"} {
    lappend hp1_ddr_segs $seg
    puts "  找到: HP1_DDR_LOW"
  }
}
if {[llength $hp1_ddr_segs] > 0} {
  include_bd_addr_seg [get_bd_addr_spaces Data_S2MM] $hp1_ddr_segs
  puts "  HP1_DDR 已加入 S2MM"
}

# 包含 HP0_DDR 到 MM2S
puts "\n包含 HP0_DDR 到 MM2S..."
set hp0_ddr_segs {}
foreach seg [get_bd_addr_segs] {
  set seg_name [get_property NAME $seg]
  if {$seg_name eq "HP0_DDR_LOW"} {
    lappend hp0_ddr_segs $seg
  }
}
if {[llength $hp0_ddr_segs] > 0} {
  include_bd_addr_seg [get_bd_addr_spaces Data_MM2S] $hp0_ddr_segs
  puts "  HP0_DDR 已加入 MM2S"
}

assign_bd_address -randomize_remaining_addresses

puts "\n=== 6. 验证 ==="
set rc [catch {validate_bd_design} err]
if {$rc} {
  puts "验证: $err"
} else {
  puts "验证通过!"
}

save_bd_design
puts "BD 已保存"

puts "\n=== 最终地址映射 ==="
foreach seg [get_bd_addr_segs] {
  puts "  [get_property NAME $seg] = [get_property OFFSET $seg] / [get_property RANGE $seg]"
}

puts "\n=== 连接确认 ==="
puts "MM2S -> [get_property NAME [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]]]"
puts "S2MM -> [get_property NAME [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]]]"

exit
