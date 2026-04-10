# 1. Create real physical project (not in-memory sandbox), specify chip model
create_project als_sys_project ./als_sys_project -part xczu2cg-sfvc784-1-e -force

# 2. Import our silicon heart IP
set_property ip_repo_paths ./als_core_ip [current_project]
update_ip_catalog

# 3. Create Block Design blueprint
create_bd_design "als_system"

# 4. Summon the main brain: Zynq UltraScale+ MPSoC
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0

# 5. Summon the memory mover: AXI DMA (disable Scatter-Gather for simplified driver dev)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_dma_0
set_property -dict [list CONFIG.c_include_sg {0} CONFIG.c_sg_length_width {26}] [get_bd_cells axi_dma_0]

# 6. Summon the core organ: ALS Autopoietic Core
create_bd_cell -type ip -vlnv user.org:user:als_core_v1:1.0 als_core_0

# 7. Physical pipeline connection (AXI4-Stream因果链)
# Memory read -> DMA -> ALS engine input
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins als_core_0/s_axis]
# ALS engine output -> DMA -> Memory write
connect_bd_intf_net [get_bd_intf_pins als_core_0/m_axis] [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]

# 8. Enable PS high-speed memory channel (HP0), prepare throughput port for DMA
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP2 {1}] [get_bd_cells zynq_ultra_ps_e_0]

# 9. Save base skeleton, stop dangerous global connection automation
save_bd_design
puts "===================================================================="
puts "BLOCK DESIGN BASELINE CREATED. PROJECT SAVED IN ./als_sys_project/"
puts "STOPPING AUTOMATION FOR HUMAN GUI VERIFICATION OF DDR TIMINGS."
puts "===================================================================="