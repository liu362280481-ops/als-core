# ila_final.tcl - ILA 调试 (MARK_DEBUG 方式)
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== 列出所有 als_core_0 端口 ==="
set als_core [get_bd_cells als_core_0]
set all_pins [get_bd_pins -of $als_core]

puts "als_core 0 端口数: [llength $all_pins]"
foreach p $all_pins {
  puts "  [get_property NAME $p]"
}

puts "\n=== 标记 AXI-Stream 网络为调试 ==="
set debug_nets {}
set sig_names {s_axis_tvalid s_axis_tready s_axis_tlast s_axis_tdata m_axis_tvalid m_axis_tready m_axis_tlast m_axis_tdata}
foreach sig $sig_names {
  foreach p [get_bd_pins -of $als_core -filter "NAME =~ *$sig*"] {
    set nets [get_bd_nets -of $p]
    foreach n $nets {
      if {$n ne ""} {
        set nname [get_property NAME $n]
        puts "标记: $nname"
        catch {set_property MARK_DEBUG true $n}
        lappend debug_nets $n
      }
    }
  }
}

puts "共标记 [llength $debug_nets] 个网络"

puts "\n=== 验证 MARK_DEBUG ==="
set verified 0
foreach n $debug_nets {
  set md [catch {get_property MARK_DEBUG $n} result]
  if {!$md && $result} {
    puts "OK: [get_property NAME $n] = $result"
    incr verified
  }
}
puts "验证通过: $verified / [llength $debug_nets]"

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证: $rc"

save_bd_design
puts "BD 已保存"

puts "\n=== 已标记的调试网络 ==="
foreach n [lsort -unique $debug_nets] {
  puts "  [get_property NAME $n]"
}

puts "\n=== 后续步骤 ==="
puts "1. 综合后, Vivado 会自动创建 ILA"
puts "2. 在 Hardware Manager 中设置触发: m_axis_tvalid == 0"
puts "3. 观察第 9022 个 cell 时刻的信号跳变"

exit
