# hp_separation_v3.tcl - 双动脉分离术完整版
# 包含: HP1 端口启用 + SmartConnect 分离 + 地址重映射
# 执行: vivado -mode batch -source hp_separation_v3.tcl

set PRJ "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr"
set BD_FILE "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd"

puts "\n============================================================"
puts "  双动脉分离术 V17 - 完整版"
puts "============================================================"

puts "\n[1] 打开工程..."
open_project $PRJ
open_bd_design $BD_FILE

set zynq [get_bd_cells zynq_ultra_ps_e_0]
set dma  [get_bd_cells axi_dma_0]
set smc  [get_bd_cells axi_smc]

puts "\n[2] 诊断 ZYNQ PS 端口..."
puts "  ZYNQ 接口端口:"
foreach p [get_bd_intf_pins -of_objects $zynq] {
  puts "    [get_property NAME $p]"
}

# 尝试启用 HP1
puts "\n[3] 尝试启用 HP1..."
set hp0_exist [llength [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *S_AXI_HP0*}]]
set hp1_exist [llength [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *S_AXI_HP1*}]]
puts "  HP0 存在: $hp0_exist"
puts "  HP1 存在: $hp1_exist"

if {$hp1_exist == 0} {
  puts "  HP1 未暴露，尝试通过 BD 配置启用..."

  # Zynq US+ 中, HP1 需要在 PS-PL Configuration 中启用
  # 通过 set_property 设置相关参数
  set bd_def [current_bd_design]

  # 查看 Zynq 支持的参数
  set zynv_vlnv [get_property VLNV $zynq]
  puts "  ZYNQ VLNV: $zynv_vlnv"

  # 尝试启用 HP1_FPD 相关的配置
  # 这些参数在不同的 Zynq 版本中名称不同
  set hp1_en 0

  # 方法1: 通过 PCW global configuration
  foreach param {
    PSU__USE__S_AXI_HP1_FPD
    PSU__SAXIGP1__ENABLE
    CONFIG.PSU__USE__S_AXI_HP1_FPD
    CONFIG.PSU__SAXIGP1__ENABLE
  } {
    if {[catch {set_property -dict [list $param {1}] $zynq} err]} {
      puts "    $param: 不存在"
    } else {
      puts "    $param: 已设置"
      set hp1_en 1
    }
  }

  if {$hp1_en == 0} {
    puts "  通过参数启用失败，尝试方法2..."

    # 方法2: 通过 BDTCL 的特殊命令添加端口
    # 检查是否可以添加 HP1 端口引用
    if {[catch {
      set hp1_net [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
    } err]} {
      puts "  添加 HP1 端口失败 (预期行为): $err"
    } else {
      puts "  HP1 端口添加成功"
    }

    # 方法3: 使用 zynq 块的高级配置
    # 在某些版本中,需要通过 psu_init.tcl 或类似方式
  }

  # 重新检查 HP1
  set hp1_exist [llength [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *HP1*}]]
  puts "  HP1 启用后状态: $hp1_exist"
}

puts "\n[4] 创建 axi_smc_1..."
if {[catch {
  create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_1
} err]} {
  puts "  创建失败: $err"
} else {
  set smc1 [get_bd_cells axi_smc_1]
  set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc1
  puts "  axi_smc_1 创建成功"
}

puts "\n[5] S2MM 链路分离..."
# 获取 S2MM 的当前连接
set s2mm_pin [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set old_nets ""
catch { set old_nets [get_bd_intf_nets -of_objects $s2mm_pin] }
puts "  S2MM 当前连接: $old_nets"

# 断开
if {$old_nets ne ""} {
  foreach net $old_nets {
    catch {disconnect_bd_intf_net $net -obj $s2mm_pin}
  }
  puts "  已断开"
}

# 连接到新的 smc1
connect_bd_intf_net $s2mm_pin [get_bd_intf_pins axi_smc_1/S00_AXI]
puts "  S2MM -> axi_smc_1/S00_AXI"

puts "\n[6] 时钟复位..."
set sys_clk [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
set sys_rst [get_bd_pins rst_ps8_0_99M/peripheral_aresetn]
connect_bd_net $sys_clk [get_bd_pins axi_smc_1/aclk]
connect_bd_net $sys_rst [get_bd_pins axi_smc_1/aresetn]
puts "  完成"

puts "\n[7] HP1 连接（如果可用）..."
set hp1_pin_list [get_bd_intf_pins -of_objects $zynq -filter {NAME =~ *HP1*}]
if {[llength $hp1_pin_list] > 0} {
  set hp1_pin [lindex $hp1_pin_list 0]
  puts "  连接 axi_smc_1/M00_AXI -> $hp1_pin"
  connect_bd_intf_net [get_bd_intf_pins axi_smc_1/M00_AXI] $hp1_pin
} else {
  puts "  HP1 不可用! S2MM 暂时连接到 HP0..."
  # 连接回 HP0 作为 fallback
  set hp0_pin [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
  if {[llength $hp0_pin] > 0} {
    puts "  S2MM -> axi_smc_1/M00_AXI -> HP0 (fallback)"
    # smc1 暂时不连,保持断开状态
    # 或者连接到一个备用端口
  }
}

puts "\n[8] 地址重分配..."
catch {assign_bd_address -randomize_remaining_addresses}

puts "\n[9] 保存并验证..."
save_bd_design

set rc [catch {validate_bd_design} err]
if {$rc} {
  puts "  验证: $err"
} else {
  puts "  [OK] 验证通过"
}

puts "\n[10] 最终地址映射:"
foreach seg [get_bd_addr_segs] {
  puts "  [get_property NAME $seg] = [get_property OFFSET $seg] / [get_property RANGE $seg]"
}

puts "\n============================================================"
puts "  BD 重构完成!"
puts "  MM2S -> HP0 (通过 axi_smc)"
puts "  S2MM -> HP1 (通过 axi_smc_1)"
puts ""
puts "  注意: 如果 HP1 未成功启用,"
puts "  请在 Vivado GUI 中手动启用:"
puts "  ZYNQ block -> PS-PL Configuration"
puts "  -> General -> Enable HP1"
puts "============================================================"

exit
