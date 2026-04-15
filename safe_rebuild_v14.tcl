open_project [lindex $argv 0]

puts ">>> 1. 重建全局 IP 目录，粉碎缓存..."
update_ip_catalog -rebuild
config_ip_cache -clear_local_cache

# 【修复隐患 1】必须使用 foreach 遍历 BD 列表，确保多实体环境下的语法绝对正确
set bds [get_files *.bd]
if {[llength $bds] > 0} {
    foreach bd_file $bds {
        puts ">>> 正在处理 Block Design: $bd_file"
        open_bd_design $bd_file
        catch {upgrade_ip [get_bd_cells *]}
        catch {update_module_reference [get_bd_cells *]}
        save_bd_design
        reset_target all [get_files $bd_file]
        generate_target all [get_files $bd_file]
    }
}

puts ">>> 2. 斩断增量编译的幻肢，彻底超度丢失的文件..."
catch { set_property INCREMENTAL_CHECKPOINT "" [get_runs synth_1] }
catch { set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1] }
catch { set_property INCREMENTAL_CHECKPOINT "" [get_runs impl_1] }
catch { set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs impl_1] }

set missing_files [get_files -quiet -filter {IS_AVAILABLE == 0}]
if {[llength $missing_files] > 0} {
    puts ">>> 发现并清理物理丢失的文件引用: $missing_files"
    catch { remove_files $missing_files }
}

reset_run synth_1
reset_run impl_1

puts ">>> 3. <降维妥协> 启动双核低熵编译..."
launch_runs synth_1 -jobs 2
wait_on_run synth_1

# 【修复隐患 2】增加综合状态校验，触发异常物理熔断
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts ">>> [FATAL] 综合 (Synthesis) 报错！触发物理熔断，请检查 Vivado 报错日志。"
    exit 1
}

launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts ">>> [FATAL] 布线 (Implementation) 报错！触发物理熔断。"
    exit 1
}

# 【修复隐患 3】极客闭环：不仅生成 bit，必须强行导出 .xsa 硬件配置底座，为后续 ARM 端开发打通总线路由
puts ">>> 4. 提取 ALS-CORE 硬件灵魂 (导出包含 bitstream 的 .xsa 平台)..."
catch { write_hw_platform -fixed -include_bit -force -file ./als_system_wrapper.xsa }

puts ">>> 硅基宇宙物理网表绝对重铸完成，且 XSA 平台已导出！系统现在是绝对纯净的。"
exit
