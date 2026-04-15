# bypass_hp1_v4.tcl - 双动脉分离术精简版
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set dma  [get_bd_cells axi_dma_0]
set smc1 [get_bd_cells axi_smc_1]

puts "\n=== 1. GP3 -> HP1 ==="
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq
puts "完成"

puts "\n=== 2. 创建 axi_smc_1 ==="
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1
puts "完成"

puts "\n=== 3. S2MM 链路分离 ==="
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_net [get_bd_intf_nets -of_objects $s2mm]
disconnect_bd_intf_net $old_net -obj $s2mm
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
puts "S2MM -> axi_smc_1 -> HP1"

puts "\n=== 4. 时钟复位 ==="
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_smc_1/aclk]
connect_bd_net [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins axi_smc_1/aresetn]
puts "完成"

puts "\n=== 5. 地址映射 ==="
# 先查看当前地址空间
puts "地址空间:"
foreach as [get_bd_addr_spaces] {
  puts "  [get_property NAME $as]"
}

# 查看 S2MM 关联的段
puts "S2MM 地址段:"
set s2mm_as [lindex [get_bd_addr_spaces] 1]
puts "  s2mm_as: [get_property NAME $s2mm_as]"
foreach seg [get_bd_addr_segs -of_objects $s2mm_as] {
  puts "    [get_property NAME $seg] = [get_property OFFSET $seg]"
}

# 删除 S2MM 的 HP0 段
puts "删除 S2MM HP0 段..."
foreach seg [get_bd_addr_segs -of_objects $s2mm_as] {
  set sn [get_property NAME $seg]
  if {[string match "*HP0*" $sn]} {
    puts "  删除 $sn"
    delete_bd_objs $seg
  }
}

# 删除 MM2S 的 HP0 DDR 段 (保留其他)
puts "删除 MM2S HP0 DDR 段..."
set mm2s_as [lindex [get_bd_addr_spaces] 0]
puts "  mm2s_as: [get_property NAME $mm2s_as]"
foreach seg [get_bd_addr_segs -of_objects $mm2s_as] {
  set sn [get_property NAME $seg]
  puts "    MM2S seg: $sn"
  if {$sn eq "HP0_DDR_LOW"} {
    puts "  删除 $sn"
    delete_bd_objs $seg
  }
}

# 包含 HP1 DDR 到 S2MM
puts "包含 HP1_DDR 到 S2MM..."
set hp1_segs {}
foreach seg [get_bd_addr_segs] {
  set sn [get_property NAME $seg]
  if {$sn eq "HP1_DDR_LOW"} {
    lappend hp1_segs $seg
    puts "  找到: $sn"
  }
}
if {[llength $hp1_segs] > 0} {
  include_bd_addr_seg $s2mm_as $hp1_segs
  puts "  HP1_DDR 已加入 S2MM"
}

# 包含 HP0 DDR 到 MM2S
puts "包含 HP0_DDR 到 MM2S..."
set hp0_segs {}
foreach seg [get_bd_addr_segs] {
  if {[get_property NAME $seg] eq "HP0_DDR_LOW"} {
    lappend hp0_segs $seg
  }
}
if {[llength $hp0_segs] > 0} {
  include_bd_addr_seg $mm2s_as $hp0_segs
  puts "  HP0_DDR 已加入 MM2S"
}

# 随机分配其余
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
