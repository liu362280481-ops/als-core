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

puts ">>> 2. 斩断增量编译的幻肢，彻底超度丢失的文件..."
# 【防御升级 1】危险属性操作必须加 catch 护体，防止语法严格导致脚本直接崩溃
catch { set_property INCREMENTAL_CHECKPOINT "" [get_runs synth_1] }
catch { set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1] }
catch { set_property INCREMENTAL_CHECKPOINT "" [get_runs impl_1] }
catch { set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs impl_1] }

# 【防御升级 2】物理级超度：彻底从工程资源集中抹除已经被 rm -rf 删掉的 dcp 尸体引用
set missing_files [get_files -quiet -filter {IS_AVAILABLE == 0}]
if {[llength $missing_files] > 0} {
    puts ">>> 发现并清理物理丢失的文件引用: $missing_files"
    catch { remove_files $missing_files }
}

reset_run synth_1
reset_run impl_1

puts ">>> 3. <降维妥协> 启动双核低熵编译，死守 24GB 物理内存边界..."
launch_runs synth_1 -jobs 2
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1

puts ">>> 硅基宇宙物理网表绝对重铸完成！"
exit
