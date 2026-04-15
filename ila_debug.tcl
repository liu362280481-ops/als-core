# ila_debug.tcl - 添加 ILA 调试探针
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
open_bd_design /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.srcs/sources_1/bd/als_system/als_system.bd

puts "\n=== 1. 创建 ILA (AXI-Stream 4通道, 64bit data + 4bit control) ==="
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 system_ila_0
set ila [get_bd_cells system_ila_0]
# 配置 ILA: 1个监视端口 (monitor)，C_MONITOR_TYPE=1, NUM_MONITOR_SLOTS=1
set_property -dict [list \
  CONFIG.C_MONITOR_TYPE {Native} \
  CONFIG.C_NUM_MONITOR_SLOTS {1} \
  CONFIG.C_MONITOR_WIDTH {64} \
  CONFIG.C_DATA_DEPTH {4096} \
  CONFIG.C_INPUT_PIPE_STAGES {0} \
  CONFIG.C_EN_LOCORAGE_DETECTION {false} \
] $ila
puts "ILA 创建完成"

puts "\n=== 2. 连接时钟 ==="
# 获取 pl_clk0 时钟
set sys_clk [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net $sys_clk [get_bd_pins system_ila_0/clk]

puts "\n=== 3. 准备探针信号 ==="
# als_core 的 AXI-Stream 信号在 BD 中
# 输入: s_axis_tdata[47:0], s_axis_tvalid, s_axis_tready, s_axis_tlast
# 输出: m_axis_tdata[47:0], m_axis_tvalid, m_axis_tready, m_axis_tlast

# 找到 als_core
set als_core [get_bd_cells als_core_0]
puts "als_core: $als_core"

# 获取 als_core 的所有端口
puts "als_core 端口:"
foreach p [get_bd_pins -of $als_core] {
  puts "  [get_property NAME $p]"
}

puts "\n=== 4. 连接 ILA 探针 ==="
# ILA 有 4 个探针槽位: PROBE0, PROBE1, PROBE2, PROBE3
# PROBE0[63:0] = s_axis_tdata (48bit used)
# PROBE1[3:0]   = s_axis_tvalid, s_axis_tready, s_axis_tlast, ( spare )
# PROBE2[63:0] = m_axis_tdata (48bit used)
# PROBE3[3:0]   = m_axis_tvalid, m_axis_tready, m_axis_tlast, (spare)

# 获取探针端口
set probe0 [get_bd_pins system_ila_0/PROBE0]
set probe1 [get_bd_pins system_ila_0/PROBE1]
set probe2 [get_bd_pins system_ila_0/PROBE2]
set probe3 [get_bd_pins system_ila_0/PROBE3]

# 连接 s_axis_tdata
set s_data_pin [get_bd_pins -of $als_core -filter {NAME =~ *s_axis_tdata*}]
if {[llength $s_data_pin] > 0} {
  puts "连接 s_axis_tdata -> PROBE0"
  connect_bd_net [get_bd_net -of $s_data_pin] $probe0
} else {
  puts "未找到 s_axis_tdata，直接端口连接"
  connect_bd_intf_net [get_bd_intf_pins -of $als_core -filter {NAME =~ *S_AXIS*}] $probe0
}

# 连接 s_axis 控制信号
set s_ctrl_pins [get_bd_pins -of $als_core -filter {NAME =~ *s_axis_tvalid* || NAME =~ *s_axis_tready* || NAME =~ *s_axis_tlast*}]
puts "s_axis 控制信号: $s_ctrl_pins"

# 连接 m_axis_tdata
set m_data_pin [get_bd_pins -of $als_core -filter {NAME =~ *m_axis_tdata*}]
if {[llength $m_data_pin] > 0} {
  puts "连接 m_axis_tdata -> PROBE2"
  connect_bd_net [get_bd_net -of $m_data_pin] $probe2
}

# 连接 m_axis 控制信号
set m_ctrl_pins [get_bd_pins -of $als_core -filter {NAME =~ *m_axis_tvalid* || NAME =~ *m_axis_tready* || NAME =~ *m_axis_tlast*}]
puts "m_axis 控制信号: $m_ctrl_pins"

# 尝试通过 AXI-Stream 接口连接
puts "\n尝试通过接口连接..."
set s_if [get_bd_intf_pins -of $als_core -filter {NAME =~ *S_AXIS*}]
set m_if [get_bd_intf_pins -of $als_core -filter {NAME =~ *M_AXIS*}]
puts "S_AXIS: $s_if"
puts "M_AXIS: $m_if"

# 如果有分离的端口，尝试标记为 debug
# AXI-Stream 信号通过接口连接，ILA 监视接口
if {$s_if ne ""} {
  puts "标记 S_AXIS 为调试..."
  set_property -dict [list CONFIG.PROBE_TYPE {data_and_trigger} $probe0
  set_property -dict [list CONFIG.PROBE_TYPE {data_and_trigger} $probe1
}

puts "\n=== 5. 验证 ==="
set rc [catch {validate_bd_design} err]
puts "验证: $rc"
if {$rc == 0} {
  puts "验证通过!"
} else {
  puts "警告: $err"
}

save_bd_design
puts "BD 已保存"

puts "\n=== ILA 调试配置 ==="
puts "  时钟: pl_clk0 (100MHz)"
puts "  PROBE0: s_axis_tdata[47:0]"
puts "  PROBE1: s_axis_tvalid, s_axis_tready, s_axis_tlast"
puts "  PROBE2: m_axis_tdata[47:0]"
puts "  PROBE3: m_axis_tvalid, m_axis_tready, m_axis_tlast"
puts "  深度: 4096 samples"
puts ""
puts "触发设置: m_axis_tvalid == 0 (输出停止时触发)"

exit
