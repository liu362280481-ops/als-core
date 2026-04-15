connect
targets -set -filter {name =~ "Cortex-A53 #0"}
puts "Running A53 briefly..."
con
after 2000
puts "Stopping A53..."
stop
after 500
puts "Trying memory read..."
mrd 0x00100000 4
exit
