connect
targets -set -filter {name =~ "Cortex-A53 #0"}
puts "Reading UART0 registers..."
puts "UART0 CR at 0xFF010000:"
mrd 0xFF010000 1
puts "UART0 SR at 0xFF010014:"
mrd 0xFF010014 1
puts "UART0 RHR at 0xFF010000:"
mrd 0xFF010000 1
exit
