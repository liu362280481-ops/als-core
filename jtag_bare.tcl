connect
targets -set -filter {name =~ "Cortex-A53 #0"}
stop
after 500
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000
con
after 500
puts "ELF running?"
exit
