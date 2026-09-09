
#include <stdint.h>

// Memory-mapped peripherals
volatile uint8_t* vga_framebuffer = (volatile uint8_t*)0x20000000;
volatile uint32_t* buttons = (volatile uint32_t*)0x30000000;

// Screen dimensions
#define WIDTH 320
#define HEIGHT 240

// Memory barrier for RISC-V
static inline void memory_barrier() {
    asm volatile ("fence iorw, iorw" ::: "memory");
}

void vga_clear_screen(uint8_t color) {
    for (int i = 0; i < WIDTH * HEIGHT; i++) {
        vga_framebuffer[i] = color;
        memory_barrier();
    }
}

void vga_draw_pixel(int x, int y, uint8_t color) {
    if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
        vga_framebuffer[y * WIDTH + x] = color;
        memory_barrier();
    }
}

void vga_draw_rect(int x, int y, int width, int height, uint8_t color) {
    for (int dy = 0; dy < height; dy++) {
        for (int dx = 0; dx < width; dx++) {
            if ((x + dx) < WIDTH && (y + dy) < HEIGHT) {
                vga_framebuffer[(y + dy) * WIDTH + (x + dx)] = color;
            }
        }
    }
    memory_barrier();
}

void vga_draw_line(int x1, int y1, int x2, int y2, uint8_t color) {
    int dx = abs(x2 - x1), sx = x1 < x2 ? 1 : -1;
    int dy = -abs(y2 - y1), sy = y1 < y2 ? 1 : -1;
    int err = dx + dy, e2;

    for(;;) {
        vga_draw_pixel(x1, y1, color);
        if (x1 == x2 && y1 == y2) break;
        e2 = 2 * err;
        if (e2 >= dy) { err += dy; x1 += sx; }
        if (e2 <= dx) { err += dx; y1 += sy; }
    }
}
