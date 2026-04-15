set logfile [open /tmp/xsdb_nobit.log w]

connect
after 1000

puts $logfile "Select A53 #0 without loading bitstream..."
targets -set 9

puts $logfile "Stop core..."
stop
after 500

puts $logfile "Read PC..."
set pc [rrd pc]
puts $logfile "PC: $pc"

close $logfile
exit
