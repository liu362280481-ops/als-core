connect
targets -set -filter {name =~ "Cortex-A53 #0"}
stop
after 200
con
after 500
puts "CPU running - watching UART"
exit
