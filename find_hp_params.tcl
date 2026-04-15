# find_hp_params.tcl - 查找 ZYNQ HP 相关参数
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

set zynq [get_bd_cells zynq_ultra_ps_e_0]

puts "\n=== 查找 HP 相关参数 ==="
set all_props [list_property [get_bd_cells zynq_ultra_ps_e_0]]
set hp_props {}
foreach p $all_props {
  if {[regexp -nocase {HP|SAXI|AXI_HP|FPD} $p]} {
    lappend hp_props $p
  }
}

puts "HP相关属性:"
foreach p [lsort -unique $hp_props] {
  puts "  $p"
}

puts "\n=== 尝试启用 HP1 的所有可能参数 ==="
set candidates {
  {PSU__USE__S_AXI_HP1_FPD 1}
  {PSU__USE__S_AXI_HP2_FPD 1}
  {PSU__USE__S_AXI_HP3_FPD 1}
  {CONFIG.PSU__USE__S_AXI_HP1_FPD 1}
  {CONFIG.PSU__SAXIGP1__ENABLE 1}
  {PSU__HP1__ENABLE 1}
  {PSU__FPD__HP1__ENABLE 1}
  {PSU__SAXIGP1__AXI_STATUS {NP} C0 {C1}}
}
foreach candidate $candidates {
  set param [lindex $candidate 0]
  set val [lindex $candidate 1]
  if {[catch {
    set_property -dict [list $param $val] $zynq
    puts "  OK: $param = $val"
  } err]} {
    puts "  FAIL: $param ($err)"
  }
}

puts "\n=== 检查 SAXIGP 接口 ==="
set saxigp_pins [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *SAXIGP*}]
puts "SAXIGP pins: $saxigp_pins"

set all_pins [get_bd_intf_pins -of_objects $zynq]
puts "所有接口引脚:"
foreach p $all_pins {
  puts "  [get_property NAME $p]"
}

exit
