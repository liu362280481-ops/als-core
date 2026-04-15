# test_include.tcl - 测试 include_bd_addr_seg 正确语法
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set dma  [get_bd_cells axi_dma_0]

puts "启用 GP3..."
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq

puts "创建 axi_smc_1..."
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1

puts "S2MM -> axi_smc_1..."
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
disconnect_bd_intf_net [get_bd_intf_nets -of_objects $s2mm] -obj $s2mm
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]

puts "时钟复位..."
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_smc_1/aclk]
connect_bd_net [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins axi_smc_1/aresetn]

# ============================================================
# 地址段修复
# ============================================================
puts "\n=== 地址段修复 ==="

# 获取地址空间对象
set s2mm_as [get_bd_addr_spaces -of_objects $dma -filter "NAME =~ *S2MM*"]
set mm2s_as [get_bd_addr_spaces -of_objects $dma -filter "NAME =~ *MM2S*"]

puts "S2MM addr space: $s2mm_as"
puts "MM2S addr space: $mm2s_as"

# 先删除 S2MM 的 HP0 段
puts "\n删除 S2MM HP0 段..."
foreach seg [get_bd_addr_segs -of_objects $s2mm_as] {
  puts "  S2MM seg: [get_property NAME $seg]"
  if {[string match "*HP0*" [get_property NAME $seg]]} {
    puts "    删除!"
    delete_bd_objs $seg
  }
}

# 删除 MM2S 的 HP0 DDR 段
puts "删除 MM2S HP0 DDR 段..."
foreach seg [get_bd_addr_segs -of_objects $mm2s_as] {
  puts "  MM2S seg: [get_property NAME $seg]"
  if {[string match "*HP0*" [get_property NAME $seg]]} {
    puts "    删除!"
    delete_bd_objs $seg
  }
}

# 现在尝试 include，用实际段对象
puts "\n获取 HP1_DDR 段..."
set hp1_ddr_seg_obj ""
foreach seg [get_bd_addr_segs] {
  if {[get_property NAME $seg] eq "HP1_DDR_LOW"} {
    set hp1_ddr_seg_obj $seg
    puts "  找到: $seg (obj)"
  }
}

puts "\n获取 HP0_DDR 段..."
set hp0_ddr_seg_obj ""
foreach seg [get_bd_addr_segs] {
  if {[get_property NAME $seg] eq "HP0_DDR_LOW"} {
    set hp0_ddr_seg_obj $seg
    puts "  找到: $seg (obj)"
  }
}

# 尝试 include
if {$hp1_ddr_seg_obj ne ""} {
  puts "\ninclude_bd_addr_seg S2MM <- HP1_DDR..."
  # 正确语法: include_bd_addr_seg <master_addr_space> <slave_segment>
  include_bd_addr_seg $s2mm_as $hp1_ddr_seg_obj
  puts "  成功!"
} else {
  puts "  未找到 HP1_DDR"
}

if {$hp0_ddr_seg_obj ne ""} {
  puts "\ninclude_bd_addr_seg MM2S <- HP0_DDR..."
  include_bd_addr_seg $mm2s_as $hp0_ddr_seg_obj
  puts "  成功!"
}

assign_bd_address

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
if {$rc == 0} {
  puts "验证通过!"
} else {
  puts "验证失败: [string range $err 0 200]"
}

save_bd_design

puts "\n=== 最终地址 ==="
foreach seg [get_bd_addr_segs] {
  puts "  [get_property NAME $seg] = [get_property OFFSET $seg]"
}

exit
