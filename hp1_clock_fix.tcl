# hp1_clock_fix.tcl - 修复 HP1 时钟
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set dma  [get_bd_cells axi_dma_0]

puts "启用 GP3..."
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq

puts "创建 axi_smc_1..."
catch {delete_bd_objs [get_bd_cells axi_smc_1]}
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1

puts "S2MM 重连..."
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
catch {disconnect_bd_intf_net [get_bd_intf_nets -of_objects $s2mm] -obj $s2mm}
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]

puts "axi_smc_1 时钟复位..."
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_smc_1/aclk]
connect_bd_net [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins axi_smc_1/aresetn]

puts "HP1 FPD 时钟..."
# HP1 使用 saxihp1_fpd_aclk，需要连接到与 HP0 相同的时钟源
# HP0 的时钟源是 pl_clk0 或 IOPLL 输出
# 这里连接 saxihp1_fpd_aclk 到 pl_clk0 (100MHz)
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]
puts "saxihp1_fpd_aclk -> pl_clk0"

puts "地址段修复..."
set s2mm_as [get_bd_addr_spaces -of_objects $dma -filter "NAME =~ *S2MM*"]
set mm2s_as [get_bd_addr_spaces -of_objects $dma -filter "NAME =~ *MM2S*"]

# 删除旧段
foreach seg [get_bd_addr_segs -of_objects $s2mm_as] {
  if {[string match "*HP0*" [get_property NAME $seg]]} { delete_bd_objs $seg }
}
foreach seg [get_bd_addr_segs -of_objects $mm2s_as] {
  if {[string match "*HP0*" [get_property NAME $seg]]} { delete_bd_objs $seg }
}

# 获取段对象
set hp1_obj ""
set hp0_obj ""
foreach seg [get_bd_addr_segs] {
  if {[get_property NAME $seg] eq "HP1_DDR_LOW"} { set hp1_obj $seg }
  if {[get_property NAME $seg] eq "HP0_DDR_LOW"} { set hp0_obj $seg }
}

# 包含
if {$hp1_obj ne ""} { include_bd_addr_seg $s2mm_as $hp1_obj }
if {$hp0_obj ne ""} { include_bd_addr_seg $mm2s_as $hp0_obj }

assign_bd_address

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
if {$rc == 0} {
  puts "验证通过!"
} else {
  puts "验证: [string range $err 0 300]"
}

save_bd_design
puts "BD 已保存"

puts "\n=== 最终地址 ==="
foreach seg [get_bd_addr_segs] {
  set off [get_property OFFSET $seg]
  set rng [get_property RANGE $seg]
  puts "  [get_property NAME $seg] = $off / $rng"
}

puts "\n=== 时钟连接 ==="
foreach p [get_bd_pins -of_objects $zynq -filter {NAME =~ *aclk*}] {
  set net [get_bd_nets -of_objects $p]
  if {[llength $net] > 0} {
    puts "  [get_property NAME $p] -> [get_property NAME $net]"
  } else {
    puts "  [get_property NAME $p] -> (未连接)"
  }
}

exit
