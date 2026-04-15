connect
targets -set -filter {name =~ "Cortex-A53 #0"}
puts "Checking A53 state..."
state
puts "Reading PC..."
rrd pc
exit
