setws ./vitis_workspace
domain active zynqmp_fsbl
bsp config -append compiler_flags -DFSBL_DEBUG_INFO
bsp regenerate
platform generate
