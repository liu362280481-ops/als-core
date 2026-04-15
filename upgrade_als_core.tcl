# upgrade_als_core.tcl - 升级 als_core IP + 标记调试网络
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr

puts "\n=== 升级 als_core IP ==="
upgrade_ip [get_ips als_core_0]
puts "IP 升级完成"

puts "\n=== 标记 BD 调试网络 ==="
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set debug_nets {}
set signals {s_axis_tvalid s_axis_tready s_axis_tlast s_axis_tdata m_axis_tvalid m_axis_tready m_axis_tlast m_axis_tdata}
foreach sig $signals {
  set pin [get_bd_pins -of [get_bd_cells als_core_0] -filter "NAME =~ *$sig*"]
  if {$pin ne ""} {
    set n [get_bd_nets -of $pin]
    if {$n ne ""} {
      catch {set_property MARK_DEBUG true $n}
      lappend debug_nets $n
      puts "标记: $sig -> [get_property NAME $n]"
    }
  }
}

puts "共标记 [llength $debug_nets] 个网络"

save_bd_design
puts "BD 已保存"

puts "\n=== 升级完成 ==="
exit
