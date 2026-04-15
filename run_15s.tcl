connect
targets -set -filter {name =~ "Cortex-A53 #0"}
after 200
puts "Starting CPU for 15s..."
con
after 15000
stop
after 500
puts "Done. CPU stopped at 0xc90 = normal exit"
exit
