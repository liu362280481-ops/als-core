# connect_ila_to_als_core.tcl - 将 system_ila_0 连接到 als_core_0 m_axis
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== 检查 system_ila_0 端口 ==="
set ila [get_bd_cells system_ila_0]
puts "system_ila_0: $ila"

puts "接口引脚:"
foreach p [get_bd_intf_pins -of $ila] {
  puts "  [get_property NAME $p]"
}

puts "\n=== 检查 interface_nets ==="
puts "als_core_0_m_axis net:"
set m_net [get_bd_intf_nets als_core_0_m_axis]
puts "  [get_property NAME $m_net]"
puts "  ports: [get_property INTERFACE_PORTS $m_net]"

puts "\n=== 尝试连接 SLOT_0_AXI 到 als_core_0_m_axis ==="
# 获取 system_ila_0 的 SLOT_0_AXI 接口引脚
set slot_pin [get_bd_intf_pins system_ila_0/SLOT_0_AXI]
puts "SLOT_0_AXI pin: $slot_pin"

# 连接到 als_core_0_m_axis net
if {$slot_pin ne ""} {
  puts "连接 $slot_pin -> als_core_0_m_axis..."
  connect_bd_intf_net -intf $slot_pin als_core_0_m_axis
  puts "连接完成!"
} else {
  puts "未找到 SLOT_0_AXI"
}

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err
puts "验证: $rc"
if {$rc == 0} { puts "验证通过!" }

save_bd_design
puts "BD 已保存"

puts "\n=== 确认连接 ==="
set slot_net [get_bd_intf_nets -of [get_bd_intf_pins system_ila_0/SLOT_0_AXI]]
if {$slot_net ne ""} {
  puts "SLOT_0_AXI 已连接: [get_property NAME $slot_net]"
} else {
  puts "SLOT_0_AXI 仍未连接"
}

exit
