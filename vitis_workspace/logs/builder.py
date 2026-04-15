# 2026-04-12T15:48:09.342155
import vitis

client = vitis.create_client()
client.set_workspace(path="/home/liujiawei/ALS_Silicon_Workspace/als-core/vitis_workspace")

comp = client.get_component(name="als_app")
status = comp.clean()

platform = client.get_component(name="als_platform")
status = platform.build()

comp.build()

vitis.dispose()

