# ila_simple.tcl - ILA 调试简单版 (直接连接标量信号)
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== 创建 System ILA ==="
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.0 system_ila_0
set ila [get_bd_cells system_ila_0]

puts "ILA ports:"
foreach p [get_bd_pins -of $ila] { puts "  [get_property NAME $p]" }

puts "\n=== 配置 ILA ==="
# System ILA: 监控 8 个信号, 深度 4096
set_property -dict [list \
  CONFIG.C_NUM_MONITOR_SLOTS {1} \
  CONFIG.C_SLOT_0_AXI_MODE {1} \
  CONFIG.C Monitor Slot 0/Has TRIGGER {1} \
  CONFIG.C_MONITOR Slot 0/Allow Trigger On Streaming {1} \
] $ila

puts "\n=== 找到并连接信号 ==="
set als_core [get_bd_cells als_core_0]

# 列出所有 als_core 端口
puts "als_core 端口:"
foreach p [get_bd_pins -of $als_core] {
  puts "  [get_property NAME $p]"
}

# 连接时钟
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins system_ila_0/clk]

# 连接 AXI-Stream 监控端口
# System ILA 的 monitor_0 端口是 AXI-Stream 类型
set als_saxis [get_bd_intf_pins -of $als_core -filter {NAME =~ *S_AXIS*}]
set als_maxis [get_bd_intf_pins -of $als_core -filter {NAME =~ *M_AXIS*}]
puts "S_AXIS: $als_saxis"
puts "M_AXIS: $als_maxis"

# 连接 S_AXIS 和 M_AXIS 到 ILA monitor
if {$als_saxis ne ""} {
  catch {
    connect_bd_intf_net $als_saxis [get_bd_intf_pins system_ila_0/monitor_0]
    puts "S_AXIS 已连接"
  }
}
if {$als_maxis ne ""} {
  catch {
    connect_bd_intf_net $als_maxis [get_bd_intf_pins system_ila_0/monitor_0]
    puts "M_AXIS 已连接"
  }
}

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证: $rc"

save_bd_design
puts "BD 已保存"

exit
