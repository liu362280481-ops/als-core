# 2026-04-10T22:29:50.968075
import vitis

client = vitis.create_client()
client.set_workspace(path="/home/liujiawei/ALS_Silicon_Workspace/als-core/vitis_workspace")

comp = client.get_component(name="als_app")
status = comp.clean()

platform = client.get_component(name="als_platform")
status = platform.build()

status = platform.build()

comp.build()

status = comp.clean()

status = platform.build()

comp.build()

status = comp.clean()

status = platform.build()

comp.build()

status = comp.clean()

status = platform.build()

comp.build()

status = comp.clean()

status = comp.clean()

status = platform.build()

comp.build()

status = comp.clean()

status = comp.clean()

status = platform.build()

comp.build()

status = comp.clean()

status = platform.build()

comp.build()

status = comp.clean()

status = comp.clean()

status = platform.build()

comp.build()

status = platform.build()

status = comp.clean()

status = platform.build()

comp.build()

status = platform.update_hw(hw_design = "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_system_wrapper.xsa")

status = platform.build()

status = comp.clean()

status = platform.build()

comp.build()

vitis.dispose()

