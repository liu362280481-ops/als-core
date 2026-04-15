# bypass_hp1.tcl - 双动脉分离术 (HP1 via GP3)
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]

puts "\n=== Step 2: 激活 HP1 (GP3) ==="
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq
puts "GP3 已激活"

puts "\n=== 检查端口变化 ==="
set new_pins [get_bd_intf_pins -of_objects $zynq]
puts "ZYNQ 端口列表:"
foreach p $new_pins { puts "  [get_property NAME $p]" }

puts "\n=== Step 4: 创建 axi_smc_1 ==="
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells axi_smc_1]
puts "axi_smc_1 创建完成"

puts "\n=== Step 3: 切断 S2MM 旧连接 ==="
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_net [get_bd_intf_nets -of_objects $s2mm]
puts "旧连接: [get_property NAME $old_net]"
disconnect_bd_intf_net $old_net -obj $s2mm
puts "已断开"

puts "\n=== Step 5: 重新连线 ==="
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
puts "S2MM -> axi_smc_1/S00_AXI"

set hp1_pin [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *HP1*}]
if {[llength $hp1_pin] > 0} {
  connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] $hp1_pin
  puts "axi_smc_1/M00_AXI -> $hp1_pin"
} else {
  puts "ERROR: HP1 端口仍然不存在!"
}

puts "\n=== Step 6: 时钟复位 ==="
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk "/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)" Freq "100" Ref_Clk0 {} Ref_Clk1 {} } [get_bd_pins axi_smc_1/aclk]
puts "时钟自动化完成"

puts "\n=== Step 7: 地址分配 ==="
assign_bd_address
puts "地址已分配"

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
if {$rc} {
  puts "验证失败: $err"
} else {
  puts "验证通过!"
}

save_bd_design
puts "BD 已保存"

puts "\n=== 最终端口列表 ==="
foreach p [get_bd_intf_pins -of_objects $zynq] { puts "  [get_property NAME $p]" }

exit
