connect
puts "Resetting JTAG chain..."
targets -set -filter {name =~ "PSU"}
puts "Issuing system reset..."
targets -set -filter {name =~ "PS TAP"}
after 200
targets -set -filter {name =~ "APU"}
after 200
targets -set -filter {name =~ "Cortex-A53 #0"}
after 200
stop
after 500
puts "A53 should be stopped now"
exit
