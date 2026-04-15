connect
puts "Connecting to PSU..."
targets -set -nocase -filter {name =~ "PSU"}
puts "Programming FPGA..."
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 1000
puts "Running PSU init..."
source ./vitis_workspace/als_platform/hw/sdt/psu_init.tcl
psu_init
after 1000
puts "Removing PS-PL isolation..."
psu_ps_pl_isolation_removal
after 500
psu_ps_pl_reset_config
after 500
puts "Selecting A53 #0 target..."
targets -set -filter {name =~ "Cortex-A53 #0"}
after 200
puts "A53 target selected"
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000
con
after 500
puts "ELF running - check UART"
exit
