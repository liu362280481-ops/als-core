# 2026-04-10T03:45:32.583988
import vitis

client = vitis.create_client()
client.set_workspace(path="/home/liujiawei/ALS_Silicon_Workspace/als-core/vitis_workspace")

platform = client.create_platform_component(name = "als_platform",hw_design = "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_system_wrapper.xsa",os = "standalone",cpu = "psu_cortexa53_0",domain_name = "standalone_psu_cortexa53_0")

platform = client.get_component(name="als_platform")
status = platform.build()

comp = client.create_app_component(name="als_app",platform = "/home/liujiawei/ALS_Silicon_Workspace/als-core/vitis_workspace/als_platform/export/als_platform/als_platform.xpfm",domain = "standalone_psu_cortexa53_0")

status = platform.build()

comp = client.get_component(name="als_app")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = comp.clean()

status = comp.clean()

status = platform.build()

comp.build()

status = comp.clean()

status = platform.build()

comp.build()

status = platform.update_hw(hw_design = "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_system_wrapper.xsa")

status = platform.build()

status = comp.clean()

status = platform.build()

comp.build()

status = comp.clean()

status = platform.build()

comp.build()

status = comp.clean()

status = platform.build()

comp.build()

vitis.dispose()

