# rebuild_v19.tcl - V19 (flush_mode + ILA debug)
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr

puts "=== 删除旧 runs ==="
catch {reset_runs [get_runs synth_1]}
catch {reset_runs [get_runs impl_1]}

puts "=== synth_1 ==="
launch_runs synth_1 -jobs 1
wait_on_run synth_1
puts "synth_1 done: [get_property PROGRESS [get_runs synth_1]]"

puts "=== impl_1 ==="
launch_runs impl_1 -jobs 1
wait_on_run impl_1
puts "impl_1 done: [get_property PROGRESS [get_runs impl_1]]"

puts "=== bitstream ==="
open_checkpoint [get_property DIRECTORY [get_runs impl_1]]/als_system_wrapper_routed.dcp
write_bitstream -force /home/liujiawei/ALS_Silicon_Workspace/als-core/als_system_wrapper.bit
puts "V19 done!"
exit
