# bypass_hp1_complete.tcl - 双动脉分离术完整版
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]

puts "\n=== 1. 激活 HP1 (GP3) ==="
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] $zynq
puts "GP3 激活完成"
puts "端口列表:"
foreach p [get_bd_intf_pins -of_objects $zynq] { puts "  [get_property NAME $p]" }

puts "\n=== 2. 创建 axi_smc_1 ==="
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1
puts "axi_smc_1 创建完成"

puts "\n=== 3. 切断 S2MM 旧连接 ==="
set s2mm [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_net [get_bd_intf_nets -of_objects $s2mm]
puts "旧连接: [get_property NAME $old_net]"
disconnect_bd_intf_net $old_net -obj $s2mm
puts "已断开"

puts "\n=== 4. 连接 S2MM -> axi_smc_1 ==="
connect_bd_intf_net $s2mm [get_bd_intf_pins axi_smc_1/S00_AXI]
puts "S2MM -> axi_smc_1/S00_AXI"

puts "\n=== 5. 连接 axi_smc_1 -> HP1 ==="
set hp1_pin [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *HP1*}]
puts "HP1 pin: $hp1_pin"
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] $hp1_pin
puts "axi_smc_1/M00_AXI -> S_AXI_HP1_FPD"

puts "\n=== 6. 时钟复位 ==="
# SmartConnect 端口列表
puts "axi_smc_1 端口:"
foreach p [get_bd_pins -of_objects $smc1] { puts "  [get_property NAME $p]" }
foreach p [get_bd_intf_pins -of_objects $smc1] { puts "  [get_property NAME $p]" }

# 获取系统时钟和复位
set sys_clk [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
set sys_rst [get_bd_pins rst_ps8_0_99M/peripheral_aresetn]
puts "系统时钟: [get_property NAME $sys_clk]"
puts "系统复位: [get_property NAME $sys_rst]"

# 尝试直接连接 (不需要两端都有对象)
# SmartConnect 通常自动继承时钟，但显式连接更安全
# 检查 smc1 是否有 aclk 端口
set smc1_aclk [get_bd_pins -of_objects $smc1 -filter {NAME =~ *aclk*}]
if {[llength $smc1_aclk] > 0} {
  puts "找到 aclk: $smc1_aclk"
  # 创建临时网络连接时钟
  connect_bd_net $sys_clk $smc1_aclk
  puts "时钟连接完成"
} else {
  puts "未找到 aclk 端口 (可能自动管理)"
}

puts "\n=== 7. 地址分配 ==="
assign_bd_address
puts "地址分配完成"

puts "\n=== 8. 验证 ==="
set rc [catch {validate_bd_design} err]
if {$rc} {
  puts "验证结果: $err"
} else {
  puts "验证通过!"
}

puts "\n=== 9. 保存 ==="
save_bd_design
puts "BD 已保存"

puts "\n=== 最终连接确认 ==="
set mm2s [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]
set mm2s_net [get_bd_intf_nets -of_objects $mm2s]
set s2mm_net_new [get_bd_intf_nets -of_objects [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]]
puts "MM2S -> [get_property NAME $mm2s_net]"
puts "S2MM -> [get_property NAME $s2mm_net_new]"

exit
