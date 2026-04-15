puts ">>> 连接 JTAG..."
connect

puts ">>> 选择 Cortex-A53 #0..."
targets -set 9

puts ">>> 停止处理器..."
stop
after 500

puts ">>> 读取 PC..."
rrd pc

puts ">>> 读取全部寄存器..."
rrd

puts ">>> 读取 DDR 内存 0x00100000..."
mrd 0x00100000 10

puts ">>> 读取 0x00000000..."
mrd 0x00000000 10

exit
