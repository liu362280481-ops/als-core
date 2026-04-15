connect
targets
puts "---"
targets -set -filter {name =~ "Cortex-A53 #0"}
puts "A53 target state:"
state
exit
