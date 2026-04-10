# 1. Create in-memory project for IP packaging
create_project -in_memory -part xczu2cg-sfvc784-1-e

# 2. Read all validated RTL sources and OOC timing constraint
read_verilog -sv [glob *.sv]
add_files [glob *.hex]
read_xdc ./als_timing.xdc

# 3. Absolute isolation law: lock XDC in OOC sandbox to prevent SoC clock tree pollution
set_property USED_IN {out_of_context} [get_files ./als_timing.xdc]

# 4. Launch Vivado IP Packager, output to als_core_ip directory
ipx::package_project -root_dir ./als_core_ip -vendor user.org -library user -taxonomy /ALS_Core -import_files
set core [ipx::current_core]

# 5. Set IP core metadata properties
set_property name als_core_v1 $core
set_property display_name {ALS Autopoietic Core v1.0} $core
set_property description {ALS V2 Hardware Accelerator Engine} $core
set_property core_revision 1 $core

# 6. Spacetime topology binding: associate aclk with s_axis/m_axis and aresetn reset
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces aclk -of_objects $core]
set_property value s_axis:m_axis [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces aclk -of_objects $core]]

ipx::add_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces aclk -of_objects $core]
set_property value aresetn [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects [ipx::get_bus_interfaces aclk -of_objects $core]]

# 7. Freeze physical form, generate GUI files and save
ipx::create_xgui_files $core
ipx::update_checksums $core
ipx::save_core $core

puts "================================================="
puts "IP PACKAGING COMPLETE. SILICON ORGAN IS READY."
puts "================================================="