set logfile [open /tmp/xsdb_pmu.log w]

connect
after 1000

puts $logfile "Select PMU..."
targets -set 2

puts $logfile "Read PMU registers..."
rrd
after 200

puts $logfile "Read PMU memory at 0xFF990000..."
mrd 0xFF990000 8

close $logfile
exit
