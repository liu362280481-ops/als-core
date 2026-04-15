import vitis
import os

# Create client
client = vitis.create_client()

# Set workspace
workspace_path = "/home/liujiawei/ALS_Silicon_Workspace/als_vitis_v14_pure"
if not os.path.exists(workspace_path):
    os.makedirs(workspace_path)
client.set_workspace(path=workspace_path)

# Define params
xsa_path = "/home/liujiawei/ALS_Silicon_Workspace/als-core/als_system_wrapper.xsa"
plat_name = "als_platform_pure"
app_name = "als_app_pure"
domain_name = "standalone_psu_cortexa53_0"

print(f"Workspace: {workspace_path}")
print(f"XSA: {xsa_path}")

# Create platform
print(f"Creating platform: {plat_name}")
platform_obj = client.create_platform_component(
    name=plat_name,
    hw_design=xsa_path,
    os="standalone",
    cpu="psu_cortexa53_0"
)
platform_obj.build()
print("Platform built.")

# Create app
print(f"Creating application: {app_name}")
platform_xpfm = client.find_platform_in_repos(plat_name)
app_comp = client.create_app_component(
    name=app_name,
    platform=platform_xpfm,
    domain=domain_name,
    template="empty"
)
print("App created.")

# Import sources
print("Importing sources...")
old_src_path = "/home/liujiawei/ALS_Silicon_Workspace/als-core/vitis_workspace/als_app/src"
c_files = [f for f in os.listdir(old_src_path) if f.endswith('.c')]
h_files = [f for f in os.listdir(old_src_path) if f.endswith('.h')]
all_files = c_files + h_files
print(f"Files: {all_files}")
app_comp.import_files(from_loc=old_src_path, files=all_files, dest_dir_in_cmp="src")
print("Sources imported.")

# Build
print("Building application...")
app_comp.build()
print("Build complete!")

print("Done!")
vitis.dispose()
