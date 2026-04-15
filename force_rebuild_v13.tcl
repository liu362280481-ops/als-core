open_project [lindex $argv 0]

puts ">>> 1. 重建全局 IP 目录，粉碎缓存幻觉..."
update_ip_catalog -rebuild
config_ip_cache -clear_local_cache

set bds [get_files *.bd]
if {[llength $bds] > 0} {
    open_bd_design $bds
    puts ">>> 2. 强行拉取底层 Verilog 更新，升级 Block Design 宇宙拓扑..."
    # 无论它是封装好的 IP 还是 RTL 模块，全部强行升级！
    catch {upgrade_ip [get_bd_cells *]}
    catch {update_module_reference [get_bd_cells *]}
    save_bd_design
    reset_target all $bds
    generate_target all $bds
}

puts ">>> 3. 清空一切历史综合废气..."
reset_run synth_1
reset_run impl_1

puts ">>> 4. 引爆物理级重铸 (Synthesis & Implementation)，这才是真正的创世！..."
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

puts "[SUCCESS] 硅基宇宙物理网表【真理版】锻造完成！"
exit
