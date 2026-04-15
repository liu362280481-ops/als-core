connect
targets -set -filter {name =~ "Cortex-A53 #0"}
puts "Attempting to stop CPU..."
stop
after 1000
puts "CPU stopped or already stopped"
puts "Reading PC..."
rrd pc
exit
