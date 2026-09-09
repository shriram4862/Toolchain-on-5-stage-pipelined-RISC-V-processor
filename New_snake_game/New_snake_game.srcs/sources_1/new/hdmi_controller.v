`timescale 1ns / 1ps

module hdmi_controller (
    input wire clk_pixel,       // 100MHz pixel clock
    input wire reset_n,
    input wire [7:0] pixel_data, // 8-bit color from framebuffer
    output reg [16:0] pixel_addr, // Address to framebuffer
    output wire hdmi_clk,       // 100MHz to ADV7511
    output wire [23:0] hdmi_data, // CORRECTED: 24-bit RGB to ADV7511
    output wire hdmi_vsync,
    output wire hdmi_hsync,
    output wire hdmi_de
);

    // 640x480 @ 60Hz timing (25.175MHz ideal, but we'll run at 100MHz)
    parameter H_DISPLAY = 640;
    parameter H_FP = 16;
    parameter H_SYNC = 96;
    parameter H_BP = 48;
    parameter H_TOTAL = H_DISPLAY + H_FP + H_SYNC + H_BP;
    
    parameter V_DISPLAY = 480;
    parameter V_FP = 10;
    parameter V_SYNC = 2;
    parameter V_BP = 33;
    parameter V_TOTAL = V_DISPLAY + V_FP + V_SYNC + V_BP;

    // Framebuffer is 320x240 (2x scaling)
    parameter FB_WIDTH = 320;
    parameter FB_HEIGHT = 240;

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;
    wire display_active;
    reg [23:0] pixel_rgb;

    // Horizontal and vertical counters
    always @(posedge clk_pixel or negedge reset_n) begin
        if (!reset_n) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                v_count <= (v_count == V_TOTAL - 1) ? 0 : v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // Timing signals
    assign display_active = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
    assign hdmi_hsync = (h_count >= H_DISPLAY + H_FP) && (h_count < H_DISPLAY + H_FP + H_SYNC);
    assign hdmi_vsync = (v_count >= V_DISPLAY + V_FP) && (v_count < V_DISPLAY + V_FP + V_SYNC);
    assign hdmi_de = display_active;

    // Framebuffer addressing with 2x scaling
    always @(posedge clk_pixel) begin
        if (display_active) begin
            // Scale coordinates down to framebuffer size (320x240)
            pixel_addr <= (v_count[9:1] * FB_WIDTH) + h_count[9:1];
        end else begin
            pixel_addr <= 17'b0;
        end
    end

    // Convert 8-bit color to 24-bit RGB for ADV7511
    always @(posedge clk_pixel) begin
        if (display_active) begin
            // 3-3-2 to 24-bit RGB conversion (expand to full range)
            pixel_rgb[23:16] <= {pixel_data[7:5], 5'b00000}; // R: 3 bits -> 8 bits
            pixel_rgb[15:8]  <= {pixel_data[4:2], 5'b00000}; // G: 3 bits -> 8 bits  
            pixel_rgb[7:0]   <= {pixel_data[1:0], 6'b000000}; // B: 2 bits -> 8 bits
        end else begin
            pixel_rgb <= 24'h000000; // Black during blanking
        end
    end

    // ADV7511 interface - SIMPLE PARALLEL RGB!
    assign hdmi_clk = clk_pixel;     // Same as pixel clock (100MHz)
    assign hdmi_data = pixel_rgb;    // 24-bit RGB data

endmodule