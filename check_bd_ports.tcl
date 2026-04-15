# check_bd_ports.tcl
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== ZYNQ 所有接口端口 ==="
set zynq [get_bd_cells zynq_ultra_ps_e_0]
set ports [get_bd_intf_pins -of_objects $zynq]
foreach p $ports {
  puts "  [get_property NAME $p]"
}

puts "\n=== ZYNQ 所有时钟端口 ==="
set clk_pins [get_bd_pins -of_objects $zynq -filter {TYPE =~ *clk*}]
foreach p $clk_pins {
  puts "  [get_property NAME $p]"
}

puts "\n=== 查看 HP 相关地址空间 ==="
set addrs [get_bd_addr_spaces]
foreach a $addrs {
  puts "  [get_property NAME $a]: [get_property TYPE $a]"
}

puts "\n=== 查看 HP1 相关属性 ==="
set zynq [get_bd_cells zynq_ultra_ps_e_0]
set all_props [lsort [get_property -name $zynq]]
set hp_props [filter $all_props "*HP1*|*SAXIGP1*"]
puts "HP1 相关属性: $hp_props"

exit
