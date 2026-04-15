# connect_ila_to_als_core.tcl
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "连接 system_ila_0/SLOT_0_AXI -> als_core_0_m_axis..."
connect_bd_intf_net [get_bd_intf_pins system_ila_0/SLOT_0_AXI] [get_bd_intf_nets als_core_0_m_axis]
puts "连接完成!"

set rc [catch {validate_bd_design} err]
puts "验证: $rc"

save_bd_design
puts "BD 已保存"

puts "确认:"
set slot_net [get_bd_intf_nets -of [get_bd_intf_pins system_ila_0/SLOT_0_AXI]]
puts "SLOT_0_AXI -> [get_property NAME $slot_net]"

exit
