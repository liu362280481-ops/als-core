open_project [lindex $argv 0]

puts ">>> 1. 重建全局 IP 目录，粉碎缓存..."
update_ip_catalog -rebuild
config_ip_cache -clear_local_cache

set bds [get_files *.bd]
if {[llength $bds] > 0} {
    open_bd_design $bds
    catch {upgrade_ip [get_bd_cells *]}
    catch {update_module_reference [get_bd_cells *]}
    save_bd_design
    reset_target all $bds
    generate_target all $bds
}

puts ">>> 2. 清空一切历史综合废气..."
reset_run synth_1
reset_run impl_1

puts ">>> 3. <降维妥协> 启动双核低熵编译，死守 24GB 物理内存边界..."
# 将 jobs 严格限制为 2，用时间换取内存与操作系统的绝对生存权
launch_runs synth_1 -jobs 2
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1

puts ">>> <SUCCESS> 硅基宇宙物理网表低熵求稳版锻造完成！"
exit
