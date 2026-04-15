# 2026-04-12T01:04:12.627570
import vitis

client = vitis.create_client()
client.set_workspace(path="/home/liujiawei/ALS_Silicon_Workspace/als-core/vitis_workspace")

platform = client.get_component(name="als_platform")
status = platform.build()

domain = platform.add_domain(cpu = "psu_pmu_0",os = "standalone",name = "pmu_domain",display_name = "pmu_domain")

comp = client.create_app_component(name="pmufw_real",platform = "/home/liujiawei/ALS_Silicon_Workspace/als-core/vitis_workspace/als_platform/export/als_platform/als_platform.xpfm",domain = "pmu_domain")

status = platform.build()

client.delete_component(name="als_platform")

platform = client.create_platform_component(name = "als_platform",hw_design = "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_sys_project/als_system_wrapper.xsa",os = "standalone",cpu = "psu_cortexa53_0",domain_name = "standalone_psu_cortexa53_0")

status = platform.build()

domain = platform.add_domain(cpu = "psu_pmu_0",os = "standalone",name = "pmu_domain",display_name = "pmu_domain")

status = platform.build()

vitis.dispose()

