puts ">>> 连接 JTAG..."
connect

puts ">>> 选择 Cortex-A53 #0 (APU)..."
targets -set 9

puts ">>> 读取 A53 PC..."
rrd pc

puts ">>> 读取 A53 寄存器..."
rrd

puts ">>> 读取 DDR 内存 (0x00100000, 10 words)..."
mrd 0x00100000 10

puts ">>> 读取 0x00000000 (10 words)..."
mrd 0x00000000 10

exit
