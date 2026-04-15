# hp1_with_clock_fix.tcl - HP分离 + 时钟修复完整版
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]

puts "\n=== 1. GP3 -> HP1 ==="
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq
puts "HP1 激活"

puts "\n=== 2. 创建 axi_smc_1 ==="
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1
puts "axi_smc_1 创建"

puts "\n=== 3. S2MM 链路分离 ==="
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
catch {disconnect_bd_intf_net [get_bd_intf_nets -of $s2mm] -obj $s2mm}
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
puts "S2MM -> axi_smc_1 -> HP1"

puts "\n=== 4. 时钟复位（关键修复） ==="
# HP1 FPD 时钟 - 最重要的遗漏
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]
puts "saxihp1_fpd_aclk -> pl_clk0 (100MHz)"

# axi_smc_1 时钟
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_smc_1/aclk]
puts "axi_smc_1/aclk -> pl_clk0"

# axi_smc_1 复位
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins axi_smc_1/aresetn]
puts "axi_smc_1/aresetn -> pl_resetn0"

puts "\n=== 5. 清理悬空网络 ==="
foreach net_name {axi_dma_0_M_AXI_S2MM axi_dma_0_M_AXI_SG} {
  set dn [get_bd_nets $net_name]
  if {[llength $dn] > 0} { delete_bd_objs $dn; puts "  删除悬空: $net_name" }
}

puts "\n=== 6. 地址段修复 ==="
set s2mm_as [get_bd_addr_spaces -of [get_bd_cells axi_dma_0] -filter "NAME =~ *S2MM*"]
set mm2s_as [get_bd_addr_spaces -of [get_bd_cells axi_dma_0] -filter "NAME =~ *MM2S*"]

# 删除 S2MM HP0 段
foreach seg [get_bd_addr_segs -of $s2mm_as] {
  if {[string match "*HP0*" [get_property NAME $seg]]} {
    delete_bd_objs $seg; puts "  删除 S2MM HP0 段"
  }
}

# 删除 MM2S HP0 DDR 冗余段
foreach seg [get_bd_addr_segs -of $mm2s_as] {
  if {[get_property NAME $seg] eq "HP0_DDR_LOW"} {
    delete_bd_objs $seg; puts "  删除 MM2S HP0_DDR 段"
  }
}

assign_bd_address
puts "地址分配完成"

puts "\n=== 7. 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证结果: $rc"
if {$rc == 0} {
  puts "验证通过!"
} else {
  puts "警告: [string range $err 0 300]"
}

save_bd_design
puts "BD 已保存"

puts "\n=== 时钟连接确认 ==="
set clk_pins [get_bd_pins -of $zynq -filter {NAME =~ *aclk*}]
foreach p $clk_pins {
  set net [get_bd_nets -of $p]
  if {[llength $net] > 0} {
    puts "  [get_property NAME $p] -> [get_property NAME $net]"
  } else {
    puts "  [get_property NAME $p] -> (未连接)"
  }
}

puts "\n=== HP 端口 ==="
foreach hp [get_bd_intf_pins -of $zynq -filter {NAME =~ *HP*}] {
  set net [get_bd_intf_nets -of $hp]
  if {[llength $net] > 0} {
    puts "  [get_property NAME $hp] -> [get_property NAME $net]"
  }
}

puts "\n=== DMA 连接 ==="
puts "MM2S -> [get_property NAME [get_bd_intf_nets -of [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]]]"
puts "S2MM -> [get_property NAME [get_bd_intf_nets -of [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]]]"

exit
