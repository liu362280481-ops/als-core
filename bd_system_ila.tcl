# bd_system_ila.tcl - BD级 System ILA 插针
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== 1. 创建 System ILA ==="
catch {delete_bd_cells system_ila_0}
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0
set ila [get_bd_cells system_ila_0]

puts "\n=== 2. 配置 ILA (INTERFACE 模式) ==="
# C_MON_TYPE: NATIVE | INTERFACE | MIX
set_property -dict [list \
  CONFIG.C_MON_TYPE {INTERFACE} \
  CONFIG.C_NUM_MONITOR_SLOTS {1} \
] $ila

puts "=== 3. 检查 system_ila 端口 ==="
foreach p [get_bd_pins -of $ila] { puts "  PIN: [get_property NAME $p]" }
foreach p [get_bd_intf_pins -of $ila] { puts "  INTF_PIN: [get_property NAME $p]" }

puts "\n=== 4. 检查 als_core_0 接口 ==="
set als [get_bd_cells als_core_0]
foreach p [get_bd_intf_pins -of $als] { puts "  [get_property NAME $p]" }

puts "\n=== 5. 连接时钟 ==="
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins system_ila_0/clk]

puts "\n=== 6. 连接 AXI-Stream 监视接口 ==="
# system_ila 的 monitor_0 端口是 AXI-Stream 类型
set ila_monitor [get_bd_intf_pins -of $ila -filter {NAME =~ *monitor*}]
puts "ILA monitor: $ila_monitor"

# als_core_0 的 M_AXIS (输出) 和 S_AXIS (输入)
set als_maxis [get_bd_intf_pins -of $als -filter {NAME =~ *M_AXIS*}]
set als_saxis [get_bd_intf_pins -of $als -filter {NAME =~ *S_AXIS*}]
puts "als M_AXIS: $als_maxis"
puts "als S_AXIS: $als_saxis"

# 监视 als_core_0 的输出 (m_axis → BRAM)
if {$als_maxis ne ""} {
  connect_bd_intf_net $als_maxis $ila_monitor
  puts "已连接: $als_maxis -> $ila_monitor"
} elseif {$als_saxis ne ""} {
  connect_bd_intf_net $als_saxis $ila_monitor
  puts "已连接: $als_saxis -> $ila_monitor"
} else {
  puts "警告: 未找到 AXI-Stream 接口!"
}

puts "\n=== 7. 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证: $rc"
if {$rc == 0} {
  puts "验证通过!"
}

save_bd_design
puts "BD 已保存"

exit
