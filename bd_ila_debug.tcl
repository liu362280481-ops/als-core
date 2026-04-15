# bd_ila_debug.tcl - BD 级 ILA 插针
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== 1. 创建 BD 独立端口暴露 AXI-Stream 信号 ==="

# 获取 als_core_0 的 AXI-Stream 引脚
set als [get_bd_cells als_core_0]

# 创建输入端口 (s_axis - 监听来自 AXI DMA 的数据)
create_bd_port -dir I -from 47 -to 0 dbg_s_axis_tdata
create_bd_port -dir I dbg_s_axis_tvalid
create_bd_port -dir O dbg_s_axis_tready
create_bd_port -dir I dbg_s_axis_tlast

# 创建输出端口 (m_axis - 监听送往 BRAM 的数据)
create_bd_port -dir O -from 47 -to 0 dbg_m_axis_tdata
create_bd_port -dir O dbg_m_axis_tvalid
create_bd_port -dir I dbg_m_axis_tready
create_bd_port -dir O dbg_m_axis_tlast

# 创建时钟端口 (连接 als_core_0 的 aclk)
create_bd_port -dir I -type clk dbg_aclk
set_property CONFIG.FREQ_HZ 100000000 [get_bd_ports dbg_aclk]

puts "端口已创建"

# 获取这些端口的对象
set s_data_p  [get_bd_ports dbg_s_axis_tdata]
set s_valid_p [get_bd_ports dbg_s_axis_tvalid]
set s_ready_p [get_bd_ports dbg_s_axis_tready]
set s_last_p  [get_bd_ports dbg_s_axis_tlast]
set m_data_p  [get_bd_ports dbg_m_axis_tdata]
set m_valid_p [get_bd_ports dbg_m_axis_tvalid]
set m_ready_p [get_bd_ports dbg_m_axis_tready]
set m_last_p  [get_bd_ports dbg_m_axis_tlast]
set clk_p     [get_bd_ports dbg_aclk]

puts "\n=== 2. 获取 als_core_0 的内部信号网络 ==="

# 连接到 als_core_0 的 s_axis
set s_data_net  [get_bd_nets -of [get_bd_pins ${als}/s_axis_tdata]]
set s_valid_net [get_bd_nets -of [get_bd_pins ${als}/s_axis_tvalid]]
set s_ready_net [get_bd_nets -of [get_bd_pins ${als}/s_axis_tready]]
set s_last_net  [get_bd_nets -of [get_bd_pins ${als}/s_axis_tlast]]

# 连接到 als_core_0 的 m_axis
set m_data_net  [get_bd_nets -of [get_bd_pins ${als}/m_axis_tdata]]
set m_valid_net [get_bd_nets -of [get_bd_pins ${als}/m_axis_tvalid]]
set m_ready_net [get_bd_nets -of [get_bd_pins ${als}/m_axis_tready]]
set m_last_net  [get_bd_nets -of [get_bd_pins ${als}/m_axis_tlast]]

puts "s_axis nets: $s_data_net $s_valid_net"
puts "m_axis nets: $m_data_net $m_valid_net"

# 将新端口连接到与 als_core_0 相同的网络
# s_axis 端口是输入，连接到 s_axis 网络
connect_bd_net $s_data_net  $s_data_p
connect_bd_net $s_valid_net $s_valid_p
connect_bd_net $s_ready_net $s_ready_p
connect_bd_net $s_last_net  $s_last_p

# m_axis 端口是输出，连接到 m_axis 网络
connect_bd_net $m_data_net  $m_data_p
connect_bd_net $m_valid_net $m_valid_p
connect_bd_net $m_ready_net $m_ready_p
connect_bd_net $m_last_net  $m_last_p

# 将时钟端口连接到 pl_clk0
connect_bd_net [get_bd_nets -of [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]] $clk_p

puts "端口已连接到网络"

puts "\n=== 3. 创建 ILA (独立探针模式) ==="
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_debug
set ila [get_bd_cells ila_debug]

# 配置 ILA: 4个探针, 深度 8192
set_property -dict [list \
  CONFIG.C_NUM_PROBE {8} \
  CONFIG.C_PROBE0_WIDTH {48} \
  CONFIG.C_PROBE1_WIDTH {1} \
  CONFIG.C_PROBE2_WIDTH {1} \
  CONFIG.C_PROBE3_WIDTH {1} \
  CONFIG.C_PROBE4_WIDTH {1} \
  CONFIG.C_PROBE5_WIDTH {1} \
  CONFIG.C_PROBE6_WIDTH {1} \
  CONFIG.C_PROBE7_WIDTH {1} \
  CONFIG.C_DATA_DEPTH {8192} \
  CONFIG.C_INPUT_PIPE_STAGES {0} \
] $ila

puts "ILA 已配置: 8 probes, 深度 8192"

puts "\n=== 4. 连接 ILA 探针 ==="

# 连接时钟
connect_bd_net [get_bd_nets -of [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]] [get_bd_pins ila_debug/clk]

# 连接探针
# PROBE0[47:0] = s_axis_tdata
connect_bd_net $s_data_net [get_bd_pins ila_debug/probe0]
# PROBE1[0] = s_axis_tvalid
connect_bd_net $s_valid_net [get_bd_pins ila_debug/probe1]
# PROBE2[0] = s_axis_tready
connect_bd_net $s_ready_net [get_bd_pins ila_debug/probe2]
# PROBE3[0] = s_axis_tlast
connect_bd_net $s_last_net [get_bd_pins ila_debug/probe3]
# PROBE4[47:0] = m_axis_tdata
connect_bd_net $m_data_net [get_bd_pins ila_debug/probe4]
# PROBE5[0] = m_axis_tvalid
connect_bd_net $m_valid_net [get_bd_pins ila_debug/probe5]
# PROBE6[0] = m_axis_tready
connect_bd_net $m_ready_net [get_bd_pins ila_debug/probe6]
# PROBE7[0] = m_axis_tlast
connect_bd_net $m_last_net [get_bd_pins ila_debug/probe7]

puts "ILA 探针已连接"

puts "\n=== 5. 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证结果: $rc"
if {$rc == 0} {
  puts "验证通过!"
} else {
  puts "警告: [string range $err 0 300]"
}

save_bd_design
puts "BD 已保存"

puts "\n=== ILA 配置摘要 ==="
puts "PROBE0[47:0]: s_axis_tdata (来自 DMA 的输入)"
puts "PROBE1[0]:    s_axis_tvalid"
puts "PROBE2[0]:    s_axis_tready"
puts "PROBE3[0]:    s_axis_tlast"
puts "PROBE4[47:0]: m_axis_tdata (送往 BRAM 的输出)"
puts "PROBE5[0]:    m_axis_tvalid"
puts "PROBE6[0]:    m_axis_tready"
puts "PROBE7[0]:    m_axis_tlast"
puts "时钟: pl_clk0 (100MHz)"
puts "深度: 8192 samples"
puts ""
puts "触发条件建议: m_axis_tvalid == 0 (输出停止时触发)"

exit
