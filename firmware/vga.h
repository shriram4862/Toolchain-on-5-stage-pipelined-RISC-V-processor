#ifndef VGA_H
#define VGA_H

#include <stdint.h>

// Color definitions (3-3-2 RGB format)
#define COLOR_BLACK     0x00
#define COLOR_BLUE      0x03
#define COLOR_GREEN     0x1C
#define COLOR_RED       0xE0
#define COLOR_WHITE     0xFF
#define COLOR_YELLOW    0xFC
#define COLOR_CYAN      0x1F
#define COLOR_MAGENTA   0xE3
#define COLOR_DARK_BLUE 0x01
#define COLOR_DARK_GRAY 0x24
#define COLOR_LIGHT_BLUE 0x07

void vga_clear_screen(uint8_t color);
void vga_draw_pixel(int x, int y, uint8_t color);
void vga_draw_rect(int x, int y, int width, int height, uint8_t color);
void vga_draw_line(int x1, int y1, int x2, int y2, uint8_t color);

#endif
