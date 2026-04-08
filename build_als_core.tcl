# OOC Isolation Synthesis Script for ALS Core
# Target: Xilinx Zynq UltraScale+ XCZU2CG

# 1. Create in-memory project with target chip
create_project -in_memory -part xczu2cg-sfvc784-1-e

# 2. Read source files and timing constraint
read_verilog -sv [glob *.sv]
read_xdc ./als_timing.xdc



# 4. Execute OOC synthesis (isolate pins, preserve internal topology)
synth_design -top als_core_top -part xczu2cg-sfvc784-1-e -mode out_of_context

# 5. Generate timing and resource reports
report_timing_summary -file timing_post_synth.rpt
report_utilization -file util_post_synth.rpt

exit