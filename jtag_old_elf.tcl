connect
targets -set -filter {name =~ "Cortex-A53 #0"}
puts "Attempting dow with old ELF (DDR at 0x0)..."
dow ./vitis_workspace/als_app/build/als_app_old_addr.elf
after 1000
con
after 500
puts "Done"
exit
