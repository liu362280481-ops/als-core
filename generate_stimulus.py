import os
import numpy as np

# 建立物理结界
os.makedirs("sim", exist_ok=True)

GRID_SIZE = 128
TOTAL_CELLS = GRID_SIZE * GRID_SIZE

print("正在坍缩物理场，生成 input_q8_8.hex...")
with open("sim/input_q8_8.hex", "w") as f_in, open("sim/golden_q8_8.hex", "w") as f_gd:
    for i in range(TOTAL_CELLS):
        # 随机生成 Q8.8 格式的 16-bit 整数
        s_val = np.random.randint(0, 65535)
        p_val = np.random.randint(0, 65535)
        m_val = np.random.randint(0, 65535)

        s_hex = f"{s_val:04X}"
        p_hex = f"{p_val:04X}"
        m_hex = f"{m_val:04X}"

        # 48-bit 绝对物理连线拼接
        f_in.write(f"{s_hex}{p_hex}{m_hex}\n")
        # 占位 Golden 数据
        f_gd.write("000000000000\n")

print("创世物理数据生成完毕。")
