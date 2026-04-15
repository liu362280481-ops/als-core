#include "xparameters.h"
#include "xaxidma.h"
#include "xil_printf.h"
#include "xil_cache.h"

#define NUM_CELLS      16384
#define GRID_DIM       128
#define PIPELINE_DELAY 136
#define TOTAL_INPUT    (NUM_CELLS + PIPELINE_DELAY)
#define TX_BUFFER_BASE 0x10000000
#define RX_BUFFER_BASE 0x11000000

#ifndef XPAR_XAXIDMA_0_BASEADDR
#define DMA_BASE_ADDR 0x80000000
#else
#define DMA_BASE_ADDR XPAR_XAXIDMA_0_BASEADDR
#endif

#define CELL_BACKGROUND  (0x0000010000000000ULL)
#define CELL_CENTER_SEED (0x0000010002000100ULL)

XAxiDma AxiDma;

int main(void) {
    int Status;
    XAxiDma_Config *Config;

    Xil_ICacheDisable();
    xil_printf("\r\n=======================================================\r\n");
    xil_printf("=== ALS Genesis: Q8.8 seed + Padded DMA radar ===\r\n");
    xil_printf("=======================================================\r\n");

    Config = XAxiDma_LookupConfig(DMA_BASE_ADDR);
    if (!Config) return XST_FAILURE;
    Status = XAxiDma_CfgInitialize(&AxiDma, Config);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    uint64_t *tx_buffer = (uint64_t *)TX_BUFFER_BASE;
    uint64_t *rx_buffer = (uint64_t *)RX_BUFFER_BASE;

    // 恢复原版密集种子 + 垫片
    for (int i = 0; i < TOTAL_INPUT; i++) {
        if (i < NUM_CELLS) {
            int row = i / GRID_DIM;
            int col = i % GRID_DIM;
            if (row >= 59 && row <= 68 && col >= 59 && col <= 68) {
                tx_buffer[i] = CELL_CENTER_SEED;
            } else {
                tx_buffer[i] = CELL_BACKGROUND;
            }
        } else {
            tx_buffer[i] = 0; // Padding
        }
        if (i < NUM_CELLS) rx_buffer[i] = 0;
    }

    Xil_DCacheFlushRange((UINTPTR)tx_buffer, TOTAL_INPUT * sizeof(uint64_t));
    Xil_DCacheFlushRange((UINTPTR)rx_buffer, NUM_CELLS * sizeof(uint64_t));

    UINTPTR dma_base = AxiDma.RegBase;
    uint32_t tx_bytes = TOTAL_INPUT * sizeof(uint64_t);
    uint32_t rx_bytes = NUM_CELLS * sizeof(uint64_t);

    xil_printf("[IGNITION] Activating RX (S2MM) black hole extraction...\r\n");
    XAxiDma_WriteReg(dma_base, 0x30, 0x0001);
    XAxiDma_WriteReg(dma_base, 0x48, (uint32_t)((uint64_t)rx_buffer & 0xFFFFFFFFU));
    XAxiDma_WriteReg(dma_base, 0x4C, (uint32_t)(((uint64_t)rx_buffer >> 32) & 0xFFFFFFFFU));

    xil_printf("[IGNITION] Opening TX (MM2S) Valve to unleash the substrate...\r\n");
    XAxiDma_WriteReg(dma_base, 0x00, 0x0001);
    XAxiDma_WriteReg(dma_base, 0x18, (uint32_t)((uint64_t)tx_buffer & 0xFFFFFFFFU));
    XAxiDma_WriteReg(dma_base, 0x1C, (uint32_t)(((uint64_t)tx_buffer >> 32) & 0xFFFFFFFFU));

    // 解耦长度设置
    XAxiDma_WriteReg(dma_base, 0x58, tx_bytes);
    XAxiDma_WriteReg(dma_base, 0x28, rx_bytes);

    // 恢复轮询
    volatile uint32_t timeout = 50000000;
    uint32_t tx_status = 0, rx_status = 0;

    while (timeout > 0) {
        tx_status = XAxiDma_ReadReg(dma_base, 0x04);
        rx_status = XAxiDma_ReadReg(dma_base, 0x34);
        if (((tx_status & 0x02U) == 0x02U) && ((rx_status & 0x02U) == 0x02U)) break;
        if (((tx_status & 0x10U) == 0x10U) || ((rx_status & 0x10U) == 0x10U)) {
            xil_printf("\r\n[FATAL] AXI Bus Internal Error!\r\n");
            break;
        }
        timeout--;
    }

    Xil_DCacheInvalidateRange((UINTPTR)rx_buffer, rx_bytes);
    xil_printf("\r\n[SYS] Final State -> TX_DMASR: 0x%08x | RX_DMASR: 0x%08x\r\n", tx_status, rx_status);

    int active_particles = 0;
    for (int i = 0; i < NUM_CELLS; i++) {
        if (rx_buffer[i] != 0) {
            if (active_particles == 0) {
                xil_printf("[VERIFY] FIRST SIGN OF LIFE found at index %d: 0x%08x%08x\r\n",
                           i, (uint32_t)(rx_buffer[i] >> 32), (uint32_t)(rx_buffer[i] & 0xFFFFFFFFU));
            }
            active_particles++;
        }
    }

    xil_printf("[VERIFY] Total active (non-zero) particles found: %d / %d\r\n", active_particles, NUM_CELLS);

    if (active_particles > 0 && rx_status == 0x00000000U) {
        xil_printf("\r\n[DIAGNOSIS] 数据已成功回传！但 RX 仍显示 Busy。TLAST 信号丢失！\r\n");
    } else if (active_particles == 0) {
        xil_printf("\r\n[DIAGNOSIS] 内存死寂。RX 未收到任何数据。\r\n");
    } else if (active_particles == NUM_CELLS && rx_status != 0x00000000U) {
        xil_printf("\r\n[SUCCESS] THE CAUSALITY LOOP IS CLOSED! 拓扑闭环完美达成！\r\n");
    }

    return 0;
}
