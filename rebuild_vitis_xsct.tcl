# rebuild_vitis_xsct.tcl (XSCT 绝对防死锁版)

set WORKSPACE "/home/liujiawei/ALS_Silicon_Workspace/als_vitis_v14_xsct"
set XSA_FILE "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_system_wrapper.xsa"
set SRC_DIR "/home/liujiawei/ALS_Silicon_Workspace/als-core/vitis_workspace/als_app/src"

puts "\[架构师指令\] 切断失效的 gRPC 链路，执行 L0 级物理净空..."
catch {file delete -force $WORKSPACE}
file mkdir $WORKSPACE
setws $WORKSPACE

puts "\[架构师指令\] 正在基于 16nm 纯净底物熔铸硬件平台..."
platform create -name als_platform_pure -hw $XSA_FILE -os standalone -proc psu_cortexa53_0
platform generate

puts "\[架构师指令\] 采用【借壳生蛋】战术生成应用域（强制系统生成完美的 lscript.ld 内存映射）..."
app create -name als_app_pure -platform als_platform_pure -os standalone -proc psu_cortexa53_0 -template "Hello World"

puts "\[架构师指令\] 抹除默认占位符，执行精确的探针源码注射..."
set app_src_path "$WORKSPACE/als_app_pure/src"
catch {file delete -force "$app_src_path/helloworld.c"}
catch {file delete -force "$app_src_path/platform.c"}
catch {file delete -force "$app_src_path/platform.h"}
catch {file delete -force "$app_src_path/platform_config.h"}

# 使用底层 Tcl 文件操作进行绝对物理拷贝，拒绝 Xilinx API 可能存在的路径嵌套 BUG
set user_files [glob -nocomplain -directory $SRC_DIR *]
foreach f $user_files {
 file copy -force $f $app_src_path
}

puts "\[架构师指令\] 探针融合完毕！启动跨维度流片 (Building ELF)..."
app build -name als_app_pure

puts "======================================================================="
puts "\[SUCCESS\] XSCT 创世完成！新的 ELF 探针绝对路径为："
puts "$WORKSPACE/als_app_pure/Debug/als_app_pure.elf"
puts "======================================================================="
