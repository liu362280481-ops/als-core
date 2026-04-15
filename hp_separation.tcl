# hp_separation.tcl - 双动脉分离手术 (MM2S->HP0, S2MM->HP1)
# 执行: source .../settings64.sh && xsct hp_separation.tcl

set PRJ "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr"
set BD_FILE "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd"

puts "\n============================================================"
puts "  双动脉分离术 - V17 AXI HP 端口分离"
puts "============================================================"

puts "\n[1] 打开工程..."
open_project $PRJ

puts "\n[2] 启用 S_AXI_HP1_FPD..."
open_bd_design $BD_FILE
set zynq [get_bd_cells zynq_ultra_ps_e_0]

# Zynq US+ HP1 必须明确启用
set_property -dict [list \
  CONFIG.PSU__USE__S_AXI_HP1_FPD {1} \
  CONFIG.PSU__SAXIGP1__ENABLE {1} \
] $zynq
puts "  HP1 已启用"

puts "\n[3] 创建 axi_smc_1..."
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
set smc1 [get_bd_cells axi_smc_1]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1
puts "  axi_smc_1 创建完成"

puts "\n[4] 切断 S2MM 原有连接..."
set s2mm_pin [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_net [get_bd_intf_nets -of_objects $s2mm_pin]
puts "  当前: [get_property NAME $old_net]"
disconnect_bd_intf_net $old_net -intf_obj $s2mm_pin
puts "  已断开"

puts "\n[5] S2MM -> axi_smc_1..."
connect_bd_intf_net $s2mm_pin [get_bd_intf_pins axi_smc_1/S00_AXI]
puts "  连接完成"

puts "\n[6] axi_smc_1 -> S_AXI_HP1_FPD..."
connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
puts "  HP1 连接完成"

puts "\n[7] 挂载时钟复位..."
set sys_clk [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
set sys_rst [get_bd_pins rst_ps8_0_99M/peripheral_aresetn]
connect_bd_net $sys_clk [get_bd_pins axi_smc_1/aclk]
connect_bd_net $sys_rst [get_bd_pins axi_smc_1/aresetn]
puts "  完成"

puts "\n[8] 清除冲突地址并重新分配..."
# 列出当前地址段
puts "  当前地址:"
foreach seg [get_bd_addr_segs] {
  puts "    [get_property NAME $seg] = [get_property OFFSET $seg] / [get_property RANGE $seg]"
}

# 删除 S2MM -> HP0 的旧映射
catch {
  set bad_segs [get_bd_addr_segs -of_objects [get_bd_addr_spaces dma/Data_S2MM]]
  foreach seg $bad_segs {
    delete_bd_objs $seg
    puts "  删除: [get_property NAME $seg]"
  }
}

# 重新分配
assign_bd_address -randomize_remaining_addresses

puts "\n[9] 新地址映射:"
foreach seg [get_bd_addr_segs] {
  puts "    [get_property NAME $seg] = [get_property OFFSET $seg] / [get_property RANGE $seg]"
}

puts "\n[10] 保存..."
save_bd_design
puts "  已保存"

puts "\n[11] 验证..."
set rc [catch {validate_bd_design} err]
if {$rc} {
  puts "  验证: $err"
} else {
  puts "  [OK] 验证通过"
}

puts "\n============================================================"
puts "  HP 分离完成!"
puts "  MM2S -> S_AXI_HP0_FPD (HP0)"
puts "  S2MM -> S_AXI_HP1_FPD (HP1)"
puts "============================================================"

exit
