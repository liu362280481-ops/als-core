connect
targets -set -nocase -filter {name =~ "PSU"}
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 1000
puts "PL programmed"
source ./vitis_workspace/als_platform/hw/sdt/psu_init.tcl
psu_init
after 1000
psu_ps_pl_isolation_removal
after 1000
psu_ps_pl_reset_config
after 1000
targets -set -filter {name =~ "Cortex-A53 #0"}
dow ./vitis_workspace/als_app/build/als_app.elf
after 1000
con
after 500
puts "ELF running - monitor UART"
exit
