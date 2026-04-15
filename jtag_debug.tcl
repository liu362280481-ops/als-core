connect
puts "JTAG connected"
targets
puts "---"
targets -set -filter {name =~ "Cortex-A53 #0"}
puts "A53#0 selected"
stop
after 500
puts "A53 stopped"
targets
exit
