#include <stdint.h>

// Button register - memory mapped to 0x30000000
volatile uint32_t* buttons = (volatile uint32_t*)0x30000000;

typedef enum {
    DIR_UP,
    DIR_RIGHT,
    DIR_DOWN,
    DIR_LEFT,
    DIR_NONE
} Direction;

Direction get_input() {
    uint32_t btn_state = *buttons;

    if (btn_state & 0x1) return DIR_UP;
    if (btn_state & 0x2) return DIR_RIGHT;
    if (btn_state & 0x4) return DIR_DOWN;
    if (btn_state & 0x8) return DIR_LEFT;

    return DIR_NONE;
}
