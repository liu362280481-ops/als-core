import os
import numpy as np

# 建立物理结界
os.makedirs("sim", exist_ok=True)

# ==========================================
# 1. 创生 Hill 函数查找表 (hill_lut.hex)
# 公式: P^2 / (P^2 + K_M^2), K_M = 0.08
# ==========================================
K_M = 0.08
with open("sim/hill_lut.hex", "w") as f:
    for i in range(256):
        P_val = i / 256.0
        hill_val = (P_val ** 2) / (P_val ** 2 + K_M ** 2)
        # Q8.8 量化与截断
        hill_q = int(np.clip(hill_val * 256.0, 0, 65535))
        f.write(f"{hill_q:04X}\n")
print("✅ hill_lut.hex 烧录完毕 (深度: 256, 精度: Q8.8)")

# ==========================================
# 2. 创生膜测试极限激励场 (membrane_in.hex)
# 制造极端 P 梯度与 S 充足区域，逼迫膜单向生长
# ==========================================
GRID_SIZE = 128
with open("sim/membrane_in.hex", "w") as f:
    for row in range(GRID_SIZE):
        for col in range(GRID_SIZE):
            # S 充足 (1.0 = 0x0100)
            S_val = 0x0100
            # 制造中心高 P，四周低 P 的人造梯度靶点
            if 60 <= row <= 68 and 60 <= col <= 68:
                P_val = 0x0100  # P=1.0 (中心)
            else:
                P_val = 0x0000  # P=0 (外围)
            M_val = 0x0000  # 初始膜为 0

            # 严格按照 [16-bit S][16-bit P][16-bit M] 的 48-bit 物理连线拼接
            f.write(f"{S_val:04X}{P_val:04X}{M_val:04X}\n")

print("✅ membrane_in.hex 创世数据生成完毕 (尺寸: 16384 x 48-bit)")
