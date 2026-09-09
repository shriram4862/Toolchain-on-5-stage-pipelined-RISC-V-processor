`timescale 1ns / 1ps

module soc_top (
    input wire clk_100m,        // 100MHz from Genesys 2
    input wire ext_reset_n,     // External reset button
    input wire [3:0] btn,       // Physical buttons
    // HDMI Output
     output wire hdmi_clk,
    output wire [23:0] hdmi_data,  // Changed from [2:0]
    output wire hdmi_vsync,
    output wire hdmi_hsync,
    output wire hdmi_de
);

    // --- Clock and Reset Signals ---
    wire clk_100m_sys;
    wire clk_100m_hdmi;
      wire pll_locked;
    wire system_reset_n;
    wire video_reset_n;

    // --- Clock Generation ---
    // Use the exact name of your generated clock wizard IP
    clk_wiz_0 clocks (
    .clk_in1(clk_100m),         // 100MHz input
    .resetn(ext_reset_n),       // Active low reset
    .clk_100m_sys(clk_100m_sys),  // 100MHz system clock
    .clk_100m_hdmi(clk_100m_hdmi),// 100MHz HDMI clock
    .locked(pll_locked)
);


    // --- Reset Controller ---
    reset_controller reset_ctrl (
        .clk(clk_100m_sys),
        .ext_reset_n(ext_reset_n),
        .pll_locked(pll_locked),
        .system_reset_n(system_reset_n),
        .video_reset_n(video_reset_n)
    );

    // --- CPU and Memory Signals ---
    wire        mem_valid;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;
    wire        mem_ready;

    // Separate data paths
    wire [31:0] imem_rdata;
    wire [31:0] mmio_rdata;
    wire        imem_ready;
    wire        mmio_ready;

    // --- Framebuffer Signals ---
    wire        fb_we;
    wire [16:0] fb_cpu_addr;
    wire [7:0]  fb_cpu_data;
    wire [16:0] fb_hdmi_addr;
    wire [7:0]  fb_hdmi_data;

    // --- Instruction Memory ---
    instruction_memory imem (
        .clk(clk_100m_sys),
        .addr(mem_addr),
        .rdata(imem_rdata)
    );

    assign imem_ready = 1'b1; // Instruction memory always ready

    // --- PicoRV32 CPU ---
    picorv32 cpu (
        .clk(clk_100m_sys),
        .resetn(system_reset_n),
        .mem_valid(mem_valid),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    // --- Memory-Mapped I/O ---
    mmio_interface mmio (
        .clk(clk_100m_sys),
        .reset_n(system_reset_n),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_valid(mem_valid),
        .mem_rdata(mmio_rdata),
        .mem_ready(mmio_ready),
        .fb_we(fb_we),
        .fb_addr(fb_cpu_addr),
        .fb_wdata(fb_cpu_data),
        .buttons_in(btn)
    );

    // --- Arbiter for memory responses ---
    // Example address decoding:
    // 0x0000_0000 - 0x0FFF_FFFF : Instruction memory
    // 0x1000_0000 - 0x1FFF_FFFF : MMIO
    assign mem_rdata = (mem_addr[31:28] == 4'h0) ? imem_rdata :
                       (mem_addr[31:28] == 4'h1) ? mmio_rdata : 32'hDEADBEEF;

    assign mem_ready = (mem_addr[31:28] == 4'h0) ? imem_ready :
                       (mem_addr[31:28] == 4'h1) ? mmio_ready : 1'b0;

    // --- Framebuffer Memory ---
    framebuffer fb_ram (
        .clk(clk_100m_sys),
        .we(fb_we),
        .addr_a(fb_cpu_addr),
        .data_a(fb_cpu_data),
        .addr_b(fb_hdmi_addr),
        .data_b(fb_hdmi_data)
    );

    // --- HDMI Controller ---
    hdmi_controller hdmi (
    .clk_pixel(clk_100m_hdmi),     // 100MHz from clock wizard
    .reset_n(video_reset_n),
    .pixel_data(fb_hdmi_data),     // 8-bit from framebuffer
    .pixel_addr(fb_hdmi_addr),
    .hdmi_clk(hdmi_clk),
    .hdmi_data(hdmi_data),         // Now 24-bit
    .hdmi_vsync(hdmi_vsync),
    .hdmi_hsync(hdmi_hsync),
    .hdmi_de(hdmi_de)
);


endmodule