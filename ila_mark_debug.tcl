# ila_mark_debug.tcl - 直接在 BD 上标记网络为调试
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== 获取 als_core_0 的信号网络 ==="

# als_core_0 在 BD 层级中的完整路径
set als_core [get_bd_cells als_core_0]
puts "als_core: $als_core"

# 获取所有连接到 als_core_0 的网络
set all_nets {}
set all_pins [get_bd_pins -of $als_core]
foreach p $all_pins {
  set pname [get_property NAME $p]
  if {$pname =~ "*axis*" || $pname =~ "*tvalid*" || $pname =~ "*tready*" || $pname =~ "*tlast*" || $pname =~ "*tdata*"} {
    set n [get_bd_nets -of $p]
    if {$n ne ""} {
      set nname [get_property NAME $n]
      puts "  [get_property DIRECTION $p] $pname -> $nname"
      lappend all_nets $n
    }
  }
}

puts "\n=== 标记 AXI-Stream 网络为调试 ==="
set marked 0
foreach n [lsort -unique $all_nets] {
  set nname [get_property NAME $n]
  if {$nname ne ""} {
    catch {
      set_property MARK_DEBUG true $n
      puts "已标记: $nname"
      incr marked
    }
  }
}
puts "共标记 $marked 个网络"

puts "\n=== 运行 setup_debug (在综合之后, 这里仅作验证) ==="
# 注意: setup_debug 需要在综合后的网表上运行
# 但我们可以先验证 MARK_DEBUG 属性是否已设置
puts "\n验证 MARK_DEBUG 属性..."
foreach n [lsort -unique $all_nets] {
  set nname [get_property NAME $n]
  if {$nname ne ""} {
    set md [get_property MARK_DEBUG $n]
    if {$md} { puts "  [green]$nname: MARK_DEBUG=true[reset]" }
  }
}

puts "\n=== 添加 ILA 到 BD ==="
# 使用 system_ila (不是 ila)
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 ila_debug
set ila [get_bd_cells ila_debug]
puts "ILA 创建: $ila"

# 列出 ILA 端口
puts "ILA 端口:"
foreach p [get_bd_pins -of $ila] { puts "  [get_property NAME $p]" }
foreach p [get_bd_intf_pins -of $ila] { puts "  [get_property NAME $p]" }

# 连接时钟
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins ila_debug/clk]

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证: $rc"
if {$rc == 0} {
  puts "验证通过!"
}

save_bd_design
puts "BD 已保存"

puts "\n=== 下一步 ==="
puts "1. Vivado 会自动在综合时根据 MARK_DEBUG 创建 ILA core"
puts "2. 综合后运行: setup_debug -quiet"
puts "3. 或者在 Vivado GUI 中: Synthesis → Open Synthesized Design → Debug"
puts "4. 触发条件建议: m_axis_tvalid == 0"

exit
