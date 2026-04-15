# launch_impl.tcl - 创建并运行 impl_1
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr

# 创建 impl_1（如果不存在）
set runs [get_runs impl_1]
if {[llength $runs] == 0} {
  puts "创建 impl_1..."
  create_run -name impl_1 -flow {Vivado Implementation 2024} -parent_run synth_1
}

puts "启动 impl_1..."
launch_runs impl_1 -jobs 1
wait_on_run impl_1

puts "impl_1 完成!"
exit
