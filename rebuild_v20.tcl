# rebuild_v20.tcl - V20 (HP1 + BD ILA + flush_mode)
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr

puts "=== synth_1 ==="
reset_run synth_1
launch_runs synth_1 -jobs 1
wait_on_run synth_1
puts "synth_1: [get_property PROGRESS [get_runs synth_1]]"

puts "=== impl_1 ==="
reset_run impl_1
launch_runs impl_1 -jobs 1
wait_on_run impl_1
puts "impl_1: [get_property PROGRESS [get_runs impl_1]]"

puts "=== bitstream ==="
open_checkpoint [get_property DIRECTORY [get_runs impl_1]]/als_system_wrapper_routed.dcp
write_bitstream -force /home/liujiawei/ALS_Silicon_Workspace/als-core/als_system_wrapper.bit
puts "V20 done!"
exit
