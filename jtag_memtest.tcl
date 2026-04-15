connect
targets -set -nocase -filter {name =~ "PSU"}
puts "Testing memory at 0x00100000..."
mask_read 0x00100000 4
puts "Reading some ARM registers..."
rrd sctlr_el3
exit
