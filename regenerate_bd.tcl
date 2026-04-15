# regenerate_bd.tcl
open_project /home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_sys_project.xpr

puts "\n=== 打开 BD (触发输出产物重新生成) ==="
open_bd_design [get_files als_system.bd]
save_bd_design
puts "BD 已保存"

puts "\n=== 重新生成 BD 输出产物 ==="
set bd_file [get_files als_system.bd]
generate_target all $bd_file
puts "输出产物生成完成"

puts "\n=== 验证 ==="
validate_bd_design
puts "验证完成"

exit
