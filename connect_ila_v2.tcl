# connect_ila_to_als_core_v2.tcl
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "获取接口对象..."
set slot [get_bd_intf_pins system_ila_0/SLOT_0_AXI]
puts "SLOT_0_AXI: $slot"

# 正确语法: connect_bd_intf_net <net> -intf_obj <pin>
# 先获取 net 对象
set nets [get_bd_intf_nets]
puts "Interface nets:"
foreach n $nets {
  if {[regexp {als_core_0_m_axis} $n]} {
    puts "  找到: $n"
    puts "  连接 $slot -> $n"
    connect_bd_intf_net $n -intf_obj $slot
    break
  }
}

set rc [catch {validate_bd_design} err]
puts "验证: $rc"
if {$rc == 0} { puts "验证通过!" }

save_bd_design
puts "BD 已保存"

puts "确认:"
set ns [get_bd_intf_nets -of $slot]
puts "SLOT_0_AXI 已连接到: [get_property NAME $ns]"

exit
