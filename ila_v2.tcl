# ila_v2.tcl - ILA 调试信号标记 (mark_debug 方式)
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== 标记调试信号 ==="

# 获取 als_core_0 的所有 AXI-Stream 端口
set als_core [get_bd_cells als_core_0]

# 列出所有端口
puts "als_core 端口列表:"
foreach p [get_bd_pins -of $als_core] {
  puts "  [get_property NAME $p]"
}

# 标记输入端口为调试
set s_signals {}
foreach sig {s_axis_tvalid s_axis_tready s_axis_tlast s_axis_tdata} {
  set p [get_bd_pins -of $als_core -filter "NAME =~ *$sig*"]
  if {[llength $p] > 0} {
    mark_debug -net $p 1
    puts "已标记: $sig -> $p"
    lappend s_signals $p
  } else {
    puts "未找到: $sig"
  }
}

# 标记输出端口为调试
set m_signals {}
foreach sig {m_axis_tvalid m_axis_tready m_axis_tlast m_axis_tdata} {
  set p [get_bd_pins -of $als_core -filter "NAME =~ *$sig*"]
  if {[llength $p] > 0} {
    mark_debug -net $p 1
    puts "已标记: $sig -> $p"
    lappend m_signals $p
  } else {
    puts "未找到: $sig"
  }
}

puts "\n=== 运行 setup_debug (自动生成 ILA) ==="
setup_debug

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证: $rc"
if {$rc == 0} {
  puts "验证通过!"
}

save_bd_design
puts "BD 已保存"

puts "\n已标记的信号:"
puts "  输入: $s_signals"
puts "  输出: $m_signals"
puts ""
puts "触发设置建议: m_axis_tvalid == 0"

exit
