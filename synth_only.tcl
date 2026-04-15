# synth_only.tcl - 只运行综合
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr
reset_run synth_1
launch_runs synth_1 -jobs 1
wait_on_run synth_1
puts "synth_1 完成!"
exit
