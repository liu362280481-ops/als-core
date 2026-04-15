open_project ./als_sys_project/als_sys_project.xpr
update_compile_order -fileset sources_1

puts ">>> 1. 粉碎旧有物理形态..."
reset_run synth_1
reset_run impl_1

puts ">>> 2. 启动逻辑综合 (Synthesis)..."
launch_runs synth_1 -jobs 8
wait_on_run synth_1

puts ">>> 3. 启动布局布线与网表生成 (Implementation & Bitstream)..."
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

puts "[SUCCESS] 硅基宇宙物理网表锻造完成！"
exit
