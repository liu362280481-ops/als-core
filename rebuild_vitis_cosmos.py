import vitis
import os

# 1. Create client
print("[STEP 1] Creating Vitis client...")
client = vitis.create_client()
print("[STEP 1] Client created.")

# 2. Set workspace
workspace_path = "/home/liujiawei/ALS_Silicon_Workspace/als_vitis_v14_pure"
if not os.path.exists(workspace_path):
    os.makedirs(workspace_path)
client.set_workspace(path=workspace_path)
print(f"[STEP 2] Workspace set: {workspace_path}")

# 3. Define params
xsa_path = "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_system_wrapper.xsa"
plat_name = "als_platform_pure"
app_name = "als_app_pure"
domain_name = "standalone_psu_cortexa53_0"

print(f"[STEP 3] Params defined")
print(f"  XSA: {xsa_path}")

# 4. Create platform
print(f"[STEP 4] Creating platform: {plat_name}")
platform_obj = client.create_platform_component(
    name=plat_name,
    hw_design=xsa_path,
    os="standalone",
    cpu="psu_cortexa53_0"
)
platform_obj.build()
print("[STEP 4] Platform built successfully.")

# 5. Create app
print(f"[STEP 5] Creating application: {app_name}")
platform_xpfm = client.find_platform_in_repos(plat_name)
app_comp = client.create_app_component(
    name=app_name,
    platform=platform_xpfm,
    domain=domain_name,
    template="empty"
)
print("[STEP 5] Application created successfully.")

# 6. Import sources
print("[STEP 6] Importing sources...")
old_src_path = "/home/liujiawei/ALS_Silicon_Workspace/als-core/vitis_workspace/als_app/src"
c_files = [f for f in os.listdir(old_src_path) if f.endswith('.c')]
h_files = [f for f in os.listdir(old_src_path) if f.endswith('.h')]
all_files = c_files + h_files
print(f"  Files found: {all_files}")
app_comp.import_files(from_loc=old_src_path, files=all_files, dest_dir_in_cmp="src")
print("[STEP 6] Sources imported successfully.")

# 7. Build
print("[STEP 7] Building application (this may take a while)...")
app_comp.build()
print("[STEP 7] Build complete.")

print("\n" + "="*70)
print("[SUCCESS] ALS-CORE 软件域重建完毕！")
print(f"[SUCCESS] 新工作空间: {workspace_path}")
print("="*70)

vitis.dispose()
