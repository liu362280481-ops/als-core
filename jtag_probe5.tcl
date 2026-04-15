connect
targets -set 9
stop
after 1000
set pc_val [rrd pc]
puts "PC = $pc_val"
set regs [rrd]
puts "REGS = $regs"
set mem0 [mrd 0x00000000 8]
puts "MEM0x0 = $mem0"
set mem1 [mrd 0x00100000 8]
puts "MEM1M = $mem1"
exit
