disconnect
after 1000
puts "Reconnecting..."
connect
after 1000
targets -set -filter {name =~ "Cortex-A53 #0"}
puts "Trying to stop..."
stop
after 500
mrd 0x00100000 4
exit
