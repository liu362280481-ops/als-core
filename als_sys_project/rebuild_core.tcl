# rebuild_core.tcl - Silicon Forge: RTL Purification → Bitstream
# Usage: vivado -mode batch -source rebuild_core.tcl

set proj_dir [file dirname [glob -nocomplain ./*.xpr]]
if {$proj_dir == ""} {
    puts "FATAL: Cannot determine project directory!"
    exit 1
}
puts "INFO: Project directory: $proj_dir"

# 1. Locate and open the project
set xpr_file [glob -nocomplain $proj_dir/*.xpr]
if {$xpr_file == ""} {
    puts "FATAL: Cannot find .xpr file in $proj_dir"
    exit 1
}
puts "INFO: Opening project: $xpr_file"
open_project $xpr_file

# 2. Refresh RTL source order
puts "INFO: Updating compile order..."
update_compile_order -fileset sources_1

# 3. Reset and launch synthesis
puts "INFO: Resetting synth_1..."
reset_run synth_1

puts "INFO: Launching synth_1..."
launch_runs synth_1 -jobs 8
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%" ||
    [get_property STATUS [get_runs synth_1]] != "synth_design Complete!"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}
puts "INFO: Synthesis complete."

# 4. Launch implementation + bitstream
puts "INFO: Launching impl_1 + bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}
puts "INFO: Implementation complete."

# 5. Export hardware platform (XSA) with bitstream
set xsa_path "./als_system_wrapper.xsa"
write_hw_platform -fixed -include_bit -force -file $xsa_path
puts "SILICON_FORGE_COMPLETE"
exit
