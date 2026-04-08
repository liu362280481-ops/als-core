# ALS Core Synthesis Script - Industrial Flow
set proj_dir "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_build"
set part "xczu2cg-sfvc784-1-e"
set top_module "als_core_top"
set src_dir "/home/liujiawei/ALS_Silicon_Workspace/als-core"

create_project als_build $proj_dir -part $part -force

read_verilog -sv $src_dir/als_core_top.sv $src_dir/diffusion_engine.sv $src_dir/reaction_engine.sv $src_dir/membrane_update.sv $src_dir/hill_lut.sv $src_dir/axis_skid_buffer.sv

set_property top $top_module [current_fileset]

puts "Starting synth_design..."
synth_design -top $top_module -part $part

report_utilization -file $proj_dir/utilization_synth.txt
report_timing_summary -file $proj_dir/timing_synth.txt

puts "Running impl..."
opt_design
place_design
phys_opt_design
route_design

report_utilization -file $proj_dir/utilization.txt
report_timing_summary -file $proj_dir/timing_summary.txt
report_drc -file $proj_dir/drc.txt

puts "DONE"
exit