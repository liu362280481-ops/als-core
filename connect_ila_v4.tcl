# connect_ila_v4.tcl
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "获取 net 对象..."
set n [get_bd_intf_nets /als_core_0_m_axis]
puts "net 对象: $n"

puts "获取 pin 对象..."
set slot [get_bd_intf_pins system_ila_0/SLOT_0_AXI]
puts "pin 对象: $slot"

puts "连接..."
connect_bd_intf_net $n $slot
puts "完成!"

set rc [catch {validate_bd_design} err]
puts "验证: $rc"

save_bd_design
puts "BD 已保存"

exit
