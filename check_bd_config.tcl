# check_bd_config.tcl - 诊断当前 BD HP 端口状态
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design [get_files als_system.bd]

puts "\n=== 当前 ZYNQ HP 端口配置 ==="
set zynq [get_bd_cells zynq_ultra_ps_e_0]
set hp0_en [get_property CONFIG.PSU__USE__S_AXI_HP0_FPD $zynq]
set hp1_en [get_property CONFIG.PSU__USE__S_AXI_HP1_FPD $zynq]
set hp2_en [get_property CONFIG.PSU__USE__S_AXI_HP2_FPD $zynq]
set hp3_en [get_property CONFIG.PSU__USE__S_AXI_HP3_FPD $zynq]
puts "HP0 enabled: $hp0_en"
puts "HP1 enabled: $hp1_en"
puts "HP2 enabled: $hp2_en"
puts "HP3 enabled: $hp3_en"

puts "\n=== 当前 DMA 地址映射 ==="
set addr_blk [get_bd_addr_segs]
foreach seg $addr_blk {
  set name [get_property NAME $seg]
  set range [get_property RANGE $seg]
  set offset [get_property OFFSET $seg]
  puts "$name -> $offset / $range"
}

puts "\n=== 当前 AXI 连接 ==="
set dma [get_bd_cells axi_dma_0]
puts "DMA MM2S ports:"
puts "  M_AXI_MM2S: [get_bd_intf_pins -of_objects $dma -filter {NAME =~ M_AXI_MM2S}]"
puts "DMA S2MM ports:"
puts "  M_AXI_S2MM: [get_bd_intf_pins -of_objects $dma -filter {NAME =~ M_AXI_S2MM}]"

puts "\n=== SmartConnect ==="
set smcs [get_bd_cells -filter {TYPE =~ *smartconnect*}]
puts "SmartConnects: $smcs"
foreach smc $smcs {
  set si [get_property CONFIG.NUM_SI $smc]
  puts "  $smc: NUM_SI=$si"
}

exit
