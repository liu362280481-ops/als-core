# debug_setup.tcl - 在综合后的网表上设置调试
# 在 synth_1 完成后运行此脚本
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr

puts "\n=== 打开综合设计 ==="
open_run synth_1 -name synth_1

puts "\n=== 查找关键信号 ==="
set signals {}
foreach sig {
  als_core_0/s_axis_tvalid
  als_core_0/s_axis_tready
  als_core_0/s_axis_tlast
  als_core_0/m_axis_tvalid
  als_core_0/m_axis_tready
  als_core_0/m_axis_tlast
  als_core_0/membrane_update_0/flush_mode
  als_core_0/membrane_update_0/out_pixel_cnt
} {
  set obj [get_nets -hier -filter "NAME =~ *$sig*"]
  if {$obj ne ""} {
    puts "找到: $obj"
    lappend signals $obj
  } else {
    puts "未找到: $sig"
  }
}

puts "\n=== 标记调试 ==="
foreach s $signals {
  catch {mark_debug -net $s 1}
  puts "已标记: $s"
}

puts "\n=== 运行 setup_debug ==="
setup_debug

puts "\n=== 保存网表 ==="
save_checkpoint -force debug_netlist.dcp

puts "\n调试设置完成!"

exit
