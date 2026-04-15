import vitis
import sys

try:
    client = vitis.create_client()
    client.set_workspace('./pmu_isolated_ws')
    xsa_path = "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_system_wrapper.xsa"
    print("-> 创建 PMU 平台...")
    plat = client.create_platform_component(name="pmu_plat", hw=xsa_path, os="standalone", cpu="psu_pmu_0")
    plat.build()
    print("-> 创建 PMU 应用...")
    app = client.create_app_component(name="pmu_app", platform="pmu_plat", domain="standalone_psu_pmu_0", template="zynqmp_pmufw")
    app.build()
    print("-> 物理 PMUFW 编译成功！")
except Exception as e:
    print(f"[致命错误] Vitis 脚本异常: {e}")
    sys.exit(1)
