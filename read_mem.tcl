connect
targets -set -filter {name =~ "Cortex-A53 #0"}
stop
after 500
puts "PC="
rrd pc
puts "SP="
rrd sp
puts "Reading DDR at 0x10000000:"
mrd 0x10000000 4
puts "Reading DDR at 0x00000000:"
mrd 0x0 4
exit
