puts ">>> 尝试穿透物理层..."
connect
after 2000
puts ">>> 提取 16nm 硅基拓扑结构："
puts "=========================================================="
set t_list [targets]
if {[string length $t_list] == 0} {
 puts "【致命异常】视界内没有任何目标 (Targets Empty)！"
} else {
 puts $t_list
}
puts "=========================================================="
exit
