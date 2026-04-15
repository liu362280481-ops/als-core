# ila_v3.tcl - ILA 调试 (MARK_DEBUG 方式)
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== 标记 BD 网络为调试 ==="

set als_core [get_bd_cells als_core_0]

# 获取所有 als_core 端口对应的网络
set debug_nets {}
foreach sig {s_axis_tvalid s_axis_tready s_axis_tlast s_axis_tdata m_axis_tvalid m_axis_tready m_axis_tlast m_axis_tdata} {
  set p [get_bd_pins -of $als_core -filter "NAME =~ *$sig*"]
  if {[llength $p] > 0} {
    # 获取该端口连接的网络
    set n [get_bd_nets -of $p]
    if {[llength $n] > 0} {
      set n_name [get_property NAME $n]
      puts "设置 MARK_DEBUG on net: $n_name (port: $sig)"
      set_property MARK_DEBUG true $n
      lappend debug_nets $n
    } else {
      puts "端口未连接: $sig"
    }
  } else {
    puts "未找到端口: $sig"
  }
}

puts "\n已标记 [llength $debug_nets] 个网络"

# 检查 ILA 是否已存在
set ila [get_bd_cells system_ila_0]
if {$ila eq ""} {
  puts "\n创建 ILA..."
  create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 system_ila_0
  set ila [get_bd_cells system_ila_0]
}

# 配置 ILA: 采样深度 8192, 64bit 采集
set_property -dict [list \
  CONFIG.C_MONITOR_TYPE {Native} \
  CONFIG.C_NUM_MONITOR_SLOTS {1} \
  CONFIG.C_MONITOR_WIDTH {64} \
  CONFIG.C_DATA_DEPTH {8192} \
  CONFIG.C_INPUT_PIPE_STAGES {0} \
] [get_bd_cells system_ila_0]

# 连接时钟
set sys_clk [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net $sys_clk [get_bd_pins system_ila_0/clk]

# 让 Vivado 自动连接调试信号
# 这会弹出向导或者自动进行
puts "\n运行调试连接自动化..."
run_debug_connection

puts "\n=== 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证: $rc"
if {$rc == 0} {
  puts "验证通过!"
} else {
  puts "警告: $err"
}

save_bd_design
puts "BD 已保存"

puts "\n=== 已配置 ILA 调试 ==="
puts "  时钟: pl_clk0 (100MHz)"
puts "  深度: 8192 samples"
puts "  触发条件建议: m_axis_tvalid == 0"

exit
