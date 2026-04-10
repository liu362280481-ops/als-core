// ============================================================================
// ALS Genesis: Phase 3 - Deep Memory Radar (Absolute MMIO Edition)
// ============================================================================

#include "xparameters.h"
#include "xaxidma.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "sleep.h"

#define NUM_CELLS 16384
#define TX_BUFFER_BASE 0x10000000
#define RX_BUFFER_BASE 0x11000000

#ifndef XPAR_XAXIDMA_0_BASEADDR
    #define DMA_BASE_ADDR 0x80000000
#else
    #define DMA_BASE_ADDR XPAR_XAXIDMA_0_BASEADDR
#endif

XAxiDma AxiDma;

int main() {
    int Status;
    XAxiDma_Config *Config;

    // 关闭指令缓存，防止预测执行干扰
    Xil_ICacheDisable();

    xil_printf("\r\n=======================================================\r\n");
    xil_printf("=== ALS Genesis: Phase 3 - Deep Memory Radar ===\r\n");
    xil_printf("=======================================================\r\n");

    Config = XAxiDma_LookupConfig(DMA_BASE_ADDR);
    if (!Config) return XST_FAILURE;
    Status = XAxiDma_CfgInitialize(&AxiDma, Config);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    // 构造测试底物数据与清空接收区
    uint64_t *tx_buffer = (uint64_t *)TX_BUFFER_BASE;
    uint64_t *rx_buffer = (uint64_t *)RX_BUFFER_BASE;
    
    for(int i = 0; i < NUM_CELLS; i++) {
        tx_buffer[i] = 0x00000000DEADBEEF; // 注入签名粒子
        rx_buffer[i] = 0;                  // 绝对清零接收区
    }

    // 强制热力学耗散：刷入物理 DDR4
    Xil_DCacheFlushRange((UINTPTR)tx_buffer, NUM_CELLS * sizeof(uint64_t));
    Xil_DCacheFlushRange((UINTPTR)rx_buffer, NUM_CELLS * sizeof(uint64_t));

    UINTPTR dma_base = AxiDma.RegBase;
    uint32_t transfer_bytes = NUM_CELLS * sizeof(uint64_t);

    // =========================================================================
    // 🌟 架构师的 RX 因果对接：先启动 S2MM 抽水引擎 🌟
    // =========================================================================
    xil_printf("[IGNITION] Activating RX (S2MM) black hole extraction...\r\n");
    XAxiDma_WriteReg(dma_base, 0x30, 0x0001); // 启动 RX
    
    uint64_t rx_phys_addr = (uint64_t)rx_buffer;
    XAxiDma_WriteReg(dma_base, 0x48, (uint32_t)(rx_phys_addr & 0xFFFFFFFF));
    XAxiDma_WriteReg(dma_base, 0x4C, (uint32_t)((rx_phys_addr >> 32) & 0xFFFFFFFF));

    // =========================================================================
    // 🌟 TX 洪流注入 🌟
    // =========================================================================
    xil_printf("[IGNITION] Opening TX (MM2S) Valve to unleash the substrate...\r\n");
    XAxiDma_WriteReg(dma_base, 0x00, 0x0001); // 启动 TX
    
    uint64_t tx_phys_addr = (uint64_t)tx_buffer;
    XAxiDma_WriteReg(dma_base, 0x18, (uint32_t)(tx_phys_addr & 0xFFFFFFFF));
    XAxiDma_WriteReg(dma_base, 0x1C, (uint32_t)((tx_phys_addr >> 32) & 0xFFFFFFFF));

    // =========================================================================
    // 🌟 终极触发：下达接收与发送指令 🌟
    // =========================================================================
    XAxiDma_WriteReg(dma_base, 0x58, transfer_bytes); // RX 准备接客
    XAxiDma_WriteReg(dma_base, 0x28, transfer_bytes); // TX 开闸放水

    // 凝视事件视界
    volatile uint32_t timeout = 50000000;
    uint32_t tx_status = 0;
    uint32_t rx_status = 0;

    while (timeout > 0) {
        tx_status = XAxiDma_ReadReg(dma_base, 0x04);
        rx_status = XAxiDma_ReadReg(dma_base, 0x34);

        if (((tx_status & 0x02) == 0x02) && ((rx_status & 0x02) == 0x02)) {
            break;
        }
        if (((tx_status & 0x10) == 0x10) || ((rx_status & 0x10) == 0x10)) {
            xil_printf("\r\n[FATAL] AXI Bus Internal Error!\r\n");
            break;
        }
        timeout--;
    }

    // 强迫 ARM 遗忘 Cache，去物理内存读取最新结果
    Xil_DCacheInvalidateRange((UINTPTR)rx_buffer, transfer_bytes);

    xil_printf("\r\n[SYS] Final State -> TX_DMASR: 0x%08x | RX_DMASR: 0x%08x\r\n", tx_status, rx_status);

    // =========================================================================
    // 🌟 探针升级：地毯式内存扫描雷达 🌟
    // =========================================================================
    xil_printf("[SCAN] Sweeping the 128KB RX Memory Zone...\r\n");
    int active_particles = 0;

    for(int i = 0; i < NUM_CELLS; i++) {
        if(rx_buffer[i] != 0) { // 只要不是纯 0，就是活的数据！
            if (active_particles == 0) {
                // 打印找到的第一个非零生命体
                xil_printf("[VERIFY] FIRST SIGN OF LIFE found at index %d: 0x%08x%08x\r\n",
                           i, (uint32_t)(rx_buffer[i] >> 32), (uint32_t)(rx_buffer[i] & 0xFFFFFFFF));
            }
            active_particles++;
        }
    }

    xil_printf("[VERIFY] Total active (non-zero) particles found: %d / %d\r\n", active_particles, NUM_CELLS);
    
    // 最终病理诊断
    if (active_particles > 0 && rx_status == 0x00000000) {
        xil_printf("\r\n[DIAGNOSIS] 数据已成功回传！但 RX 仍显示 Busy。这是典型的 TLAST 信号丢失！\r\n");
        xil_printf("-> 结论：ALS-Core 工作正常！只需要修改 HLS 代码补上 TLAST 信号。\r\n");
    } else if (active_particles == 0) {
        xil_printf("\r\n[DIAGNOSIS] 内存死寂。RX 未收到任何数据。\r\n");
        xil_printf("-> 结论：ALS-Core 的输出通道未吐出数据，或者 ap_start 没有被唤醒。\r\n");
    } else if (active_particles == NUM_CELLS && rx_status != 0x00000000) {
        xil_printf("\r\n[SUCCESS] THE CAUSALITY LOOP IS CLOSED! 拓扑闭环完美达成！\r\n");
    }

    return 0;
}