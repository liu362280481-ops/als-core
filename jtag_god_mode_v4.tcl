connect
targets -set -nocase -filter {name =~ "PSU"}
mask_write 0xFFCA0038 0x1C0 0x1C0
after 500
fpga ./vitis_workspace/als_platform/hw/sdt/als_system_wrapper.bit
after 1000
puts "PL programmed OK"
source ./vitis_workspace/als_platform/hw/sdt/psu_init.tcl
psu_init
after 1000
psu_ps_pl_isolation_removal
after 1000
psu_ps_pl_reset_config
after 1000
targets -set -filter {name =~ "Cortex-A53 #0"}
rst -processor
after 500
dow ./vitis_workspace/als_app/build/als_app.elf
con
puts "DONE - ELF downloaded and running!"
exit
