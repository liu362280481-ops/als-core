puts ">>> 1. 连接 JTAG..."
connect

puts ">>> 2. 列出所有可用目标..."
targets

puts ">>> 3. 尝试停止 PMU..."
targets -set 2
stop
after 500

puts ">>> 4. 读取 PMU 状态..."
rrd

puts "=========================================="
exit
