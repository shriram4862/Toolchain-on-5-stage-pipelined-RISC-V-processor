#ifndef INPUT_H
#define INPUT_H

typedef enum {
    DIR_UP,
    DIR_RIGHT,
    DIR_DOWN,
    DIR_LEFT,
    DIR_NONE
} Direction;

Direction get_input();

#endif
