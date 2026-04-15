# bypass_hp1_v5.tcl - 完整版含地址段创建
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
# 获取对象句柄
set s2mm_as [get_bd_addr_spaces -of_objects $dma -filter {NAME =~ *S2MM*}]
set mm2s_as [get_bd_addr_spaces -of_objects $dma -filter {NAME =~ *MM2S*}]

puts "S2MM addr space handle: $s2mm_as"
puts "MM2S addr space handle: $mm2s_as"

# 获取当前段
puts "S2MM 当前段:"
foreach seg [get_bd_addr_segs -of_objects $s2mm_as] {
  puts "  [get_property NAME $seg]"
}

puts "MM2S 当前段:"
foreach seg [get_bd_addr_segs -of_objects $mm2s_as] {
  puts "  [get_property NAME $seg]"
}

# 删除 S2MM 的 HP0 段
puts "删除 S2MM HP0 段..."
foreach seg [get_bd_addr_segs -of_objects $s2mm_as] {
  if {[string match "*HP0*" [get_property NAME $seg]]} {
    puts "  删除 [get_property NAME $seg]"
    delete_bd_objs $seg
  }
}

# 删除 MM2S 的 HP0 DDR 段
puts "删除 MM2S HP0 DDR 段..."
foreach seg [get_bd_addr_segs -of_objects $mm2s_as] {
  set seg_name [get_property NAME $seg]
  if {$seg_name eq "HP0_DDR_LOW" || [string match "*HP0*" $seg_name]} {
    puts "  删除 $seg_name"
    delete_bd_objs $seg
  }
}

# 获取 HP1_DDR 段对象
puts "获取 HP1 DDR 段..."
set hp1_ddr_seg ""
foreach seg [get_bd_addr_segs] {
  if {[get_property NAME $seg] eq "HP1_DDR_LOW"} {
    set hp1_ddr_seg $seg
    puts "  找到 HP1_DDR_LOW: $seg"
  }
}

# 获取 HP0_DDR 段对象
set hp0_ddr_seg ""
foreach seg [get_bd_addr_segs] {
  if {[get_property NAME $seg] eq "HP0_DDR_LOW"} {
    set hp0_ddr_seg $seg
    puts "  找到 HP0_DDR_LOW: $seg"
  }
}

# 包含 HP1 DDR 到 S2MM
if {$hp1_ddr_seg ne ""} {
  puts "包含 HP1_DDR 到 S2MM..."
  set rc [catch {include_bd_addr_seg $s2mm_as $hp1_ddr_seg} err]
  if {$rc} {
    puts "  include 失败: $err"
  } else {
    puts "  HP1_DDR 已加入 S2MM"
  }
}

# 包含 HP0 DDR 到 MM2S
if {$hp0_ddr_seg ne ""} {
  puts "包含 HP0_DDR 到 MM2S..."
  set rc [catch {include_bd_addr_seg $mm2s_as $hp0_ddr_seg} err]
  if {$rc} {
    puts "  include 失败: $err"
  } else {
    puts "  HP0_DDR 已加入 MM2S"
  }
}

# 分配其余地址
assign_bd_address -randomize_remaining_addresses

puts "\n=== 6. 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证结果: $err"

save_bd_design
puts "BD 已保存"

puts "\n=== 最终地址 ==="
foreach seg [get_bd_addr_segs] {
  puts "  [get_property NAME $seg] = [get_property OFFSET $seg] / [get_property RANGE $seg]"
}

puts "\n=== 连接 ==="
set mm2s_net [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]]
set s2mm_net [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]]
puts "MM2S -> [get_property NAME $mm2s_net]"
puts "S2MM -> [get_property NAME $s2mm_net]"

exit
