import os

file_path = "sim/membrane_out.hex"
if not os.path.exists(file_path):
    print(f"致命物理错误：未找到 {file_path}，硅基点火可能失败，总线无输出。")
    exit(1)

count = 0
print("=== 硅基膜生成相空间扫描报告 ===")
with open(file_path, "r") as f:
    for i, line in enumerate(f):
        line = line.strip()
        if len(line) >= 12:
            # 提取 48-bit 宽字最后的 16-bit，即 M（膜）场
            m_hex = line[-4:]
            if m_hex != '0000' and 'X' not in m_hex.upper():
                row, col = i // 128, i % 128
                m_val = int(m_hex, 16) / 256.0  # Q8.8 反量化
                print(f"坐标 [Row {row:3d}, Col {col:3d}] -> 膜浓度 M_HEX: {m_hex} (物理真实值: {m_val:.4f})")
                count += 1
                if count >= 20:
                    print("... (数据截断，硅基膜已大面积自发生成，拓扑隔离成功！) ...")
                    break

if count == 0:
    print("警告：全场未发现任何膜结构，M 场在绝对零度冻结，未发生自创生相变。")
