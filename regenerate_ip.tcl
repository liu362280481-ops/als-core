# regenerate_ip.tcl - 重新生成 IP 输出产物
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr

puts "\n=== 生成 IP 输出产物 ==="
generate_ip_interfaces [get_files als_core_ip/src/als_core_top.sv]

puts "\n=== 标记 BD 调试网络 ==="
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set debug_nets {}
set signals {s_axis_tvalid s_axis_tready s_axis_tlast s_axis_tdata m_axis_tvalid m_axis_tready m_axis_tlast m_axis_tdata}
foreach sig $signals {
  set pins [get_bd_pins -of [get_bd_cells als_core_0] -filter "NAME =~ *$sig*"]
  foreach pin $pins {
    if {$pin ne ""} {
      set n [get_bd_nets -of $pin]
      if {$n ne ""} {
        catch {set_property MARK_DEBUG true $n}
        lappend debug_nets $n
        puts "标记: $sig -> [get_property NAME $n]"
      }
    }
  }
}

puts "共标记 [llength $debug_nets] 个网络"

save_bd_design
puts "BD 已保存"

puts "\n=== 下一步 ==="
puts "运行 rebuild_v18.tcl 进行综合和实现"
puts "ILA 将由 MARK_DEBUG 属性自动创建"

exit
