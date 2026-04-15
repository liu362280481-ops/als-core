connect
targets -set -filter {name =~ "Cortex-A53 #0"}
after 200
puts "CPU running, checking state..."
con
after 5000
stop
after 500
puts "CPU stopped at:"
exit
