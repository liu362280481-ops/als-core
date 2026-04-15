**ALS-CORE 动态执行状态与计划 (Workflow State)**
**1. 当前时空坐标 (Current State)**

- **阶段**：Phase 3 (Implementation & Bitstream Generation)

- **状态**：BLOCKED (正在等待物理网表重铸)

- **核心动作**：为了避免 Ubuntu 宿主机 (24GB RAM) 发生 Linux 调度器热寂，当前已下达 safe_rebuild_v13_1.tcl 脚本，强行降维至 -jobs 2 (双核并发) 缓慢综合布局布线。

**2. 下一步奇点计划 (The Plan)**

- 等待 Vivado 炼丹炉输出 [SUCCESS] 硅基宇宙物理网表【低熵求稳版】锻造完成！。

- 在终端执行 jtag_god_mode_v12_1.sh (V12.1 语法净空版法典)，在绝对安全的时序下引爆 ALS-CORE 奇点。

- 死死锁定 sudo cat /dev/ttyUSB0，观测 DMA 吞吐 16384 个粒子后触发的 UART 辐射。

**3. AI 智能体自主循环法则 (The Loop)**
后续所有接管此 ALS-CORE 项目的 AI（包括 Cursor、Claude Code、OpenClaw）必须遵循以下闭环：

1. **Read**：行动前必须强制读取 [workflow_state.md](workflow_state.md) 与 [project_config.md](project_config.md)。

2. **Interpret**：理解当前处于哪个物理演化阶段，是否有未解决的死锁。

3. **Act**：执行具体的 shell 操作、代码编写或 JTAG 探针调用。

4. **Update**：每完成一个动作，必须立即将新的状态和观测到的日志更新回 [workflow_state.md](workflow_state.md)。
