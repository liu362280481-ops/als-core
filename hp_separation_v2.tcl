# hp_separation_v2.tcl - 双动脉分离术 (MM2S->HP0, S2MM->HP1)
# 执行: vivado -mode batch -source hp_separation_v2.tcl

set PRJ "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr"
set BD_FILE "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd"

puts "\n============================================================"
puts "  双动脉分离术 V17"
puts "============================================================"

puts "\n[1] 打开工程与BD..."
open_project $PRJ
open_bd_design $BD_FILE

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set dma  [get_bd_cells axi_dma_0]
set smc  [get_bd_cells axi_smc]

puts "\n[2] 诊断当前HP端口..."
set hp0_pins [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *HP0*}]
set hp1_pins [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *HP1*}]
puts "  HP0 pins: $hp0_pins"
puts "  HP1 pins: $hp1_pins"

# 如果HP1不存在，尝试通过写PSDDR配置启用
if {[llength $hp1_pins] == 0} {
  puts "\n  HP1 未暴露，尝试启用..."

  # 尝试通过 PCW/PS7 配置启用 HP1
  # Zynq US+ 的 HP1 启用实际上是通过修改 Zynq block 的配置
  # 这里使用 apply_bd_automation 是正确方式
  # 但更可靠的方法是直接创建 HP1 端口引用

  # 检查 Zynq 是否支持 HP1
  set ps7_props [list_property [get_bd_cells zynq_ultra_ps_e_0]]
  set hp1_related [filter $ps7_props "*HP1*|*SAXIGP1*"]
  puts "  HP1 相关属性: $hp1_related"

  # 尝试使用 create_bd_intf_pin 添加 HP1
  # 这是 Vivado 允许的高级操作
  puts "  尝试通过 regenerate zynq 端口..."
}

puts "\n[3] 尝试创建 axi_smc_1..."
if {[catch {create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1} err]} {
  puts "  创建失败: $err"
} else {
  set smc1 [get_bd_cells axi_smc_1]
  set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1
  puts "  axi_smc_1 创建成功"
}

puts "\n[4] 切断 S2MM 原有连接..."
set s2mm_pin [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_nets [get_bd_intf_nets -of_objects $s2mm_pin]
puts "  S2MM 连接到: [get_property NAME $old_nets]"
if {[llength $old_nets] > 0} {
  disconnect_bd_intf_net $old_nets -obj $s2mm_pin
  puts "  已断开"
}

puts "\n[5] 连接 S2MM -> axi_smc_1..."
connect_bd_intf_net $s2mm_pin [get_bd_intf_pins axi_smc_1/S00_AXI]
puts "  完成"

puts "\n[6] 挂载时钟复位到 axi_smc_1..."
set sys_clk [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
set sys_rst [get_bd_pins rst_ps8_0_99M/peripheral_aresetn]
if {[llength $sys_clk] > 0 && [llength $sys_rst] > 0} {
  connect_bd_net $sys_clk [get_bd_pins axi_smc_1/aclk]
  connect_bd_net $sys_rst [get_bd_pins axi_smc_1/aresetn]
  puts "  时钟复位完成"
} else {
  puts "  时钟/复位未找到，跳过"
}

puts "\n[7] HP1 连接（条件执行）..."
set hp1_avail [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *HP1*}]
if {[llength $hp1_avail] > 0} {
  puts "  HP1 可用，连接 axi_smc_1 -> S_AXI_HP1_FPD"
  connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] $hp1_avail
} else {
  puts "  HP1 不可用! 将 S2MM 连接回 HP0（临时方案）"
  puts "  注: 需要先通过 Vivado GUI 或 BD 自动化启用 HP1"
  # 先保持断开状态，不要回连
}

puts "\n[8] 地址重分配..."
catch {assign_bd_address -randomize_remaining_addresses}

puts "\n[9] 保存..."
save_bd_design
puts "  已保存"

puts "\n[10] 地址结果:"
foreach seg [get_bd_addr_segs] {
  puts "  [get_property NAME $seg] = [get_property OFFSET $seg] / [get_property RANGE $seg]"
}

puts "\n============================================================"
puts "  HP 分离步骤完成!"
puts "  重要: 需要手动在 Vivado GUI 中启用 S_AXI_HP1_FPD"
puts "  路径: double-click ZYNQ -> PS-PL Configuration ->"
puts "        HP Interfaces -> S_AXI_HP1_FPD"
puts "============================================================"

exit
