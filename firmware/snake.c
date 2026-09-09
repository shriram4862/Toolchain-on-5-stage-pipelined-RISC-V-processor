#include <stdint.h>
#include "vga.h"
#include "input.h"

// Game configuration
#define SNAKE_MAX_LENGTH 100
#define GRID_SIZE 10
#define GRID_WIDTH (320 / GRID_SIZE)   // 32 cells
#define GRID_HEIGHT (240 / GRID_SIZE)  // 24 cells
#define INITIAL_SPEED 300000
#define MIN_SPEED 50000
#define SPEED_INCREMENT 5000
#define SCORE_PER_FOOD 10

// Game state structure
typedef struct {
    int x;
    int y;
} Point;

typedef struct {
    Point snake[SNAKE_MAX_LENGTH];
    int length;
    Direction direction;
    Point food;
    uint32_t score;
    uint32_t high_score;
    uint32_t game_speed;
    uint8_t game_state; // 0=playing, 1=game over, 2=paused
} GameState;

GameState game;

// Optimized pseudo-random number generator
static uint32_t rng_state = 42;

uint32_t fast_rand(void) {
    rng_state = (rng_state * 1103515245) + 12345;
    return rng_state;
}

void place_food(void) {
    uint8_t attempts = 0;
    uint8_t valid = 0;

    while (!valid && attempts < 50) {
        game.food.x = fast_rand() % GRID_WIDTH;
        game.food.y = fast_rand() % GRID_HEIGHT;

        valid = 1;
        // Check if food overlaps with snake
        for (int i = 0; i < game.length; i++) {
            if (game.food.x == game.snake[i].x && game.food.y == game.snake[i].y) {
                valid = 0;
                break;
            }
        }
        attempts++;
    }

    // Fallback: place food at a safe position
    if (!valid) {
        game.food.x = (GRID_WIDTH / 4) + (fast_rand() % (GRID_WIDTH / 2));
        game.food.y = (GRID_HEIGHT / 4) + (fast_rand() % (GRID_HEIGHT / 2));
    }
}

void init_game() {
    // Reset game state
    game.length = 3;
    game.direction = DIR_RIGHT;
    game.score = 0;
    game.game_speed = INITIAL_SPEED;
    game.game_state = 0;

    // Initialize snake in the middle
    for (int i = 0; i < game.length; i++) {
        game.snake[i].x = (GRID_WIDTH / 2) - i;
        game.snake[i].y = GRID_HEIGHT / 2;
    }

    place_food();
}

void reset_game() {
    if (game.score > game.high_score) {
        game.high_score = game.score;
    }
    init_game();
}

void update_game() {
    if (game.game_state == 1 || game.game_state == 2) {
        return; // Don't update if game over or paused
    }

    // Get input with priority handling
    Direction new_dir = get_input();
    if (new_dir != DIR_NONE) {
        // Prevent 180-degree turns with immediate response
        if ((game.direction == DIR_UP && new_dir != DIR_DOWN) ||
            (game.direction == DIR_DOWN && new_dir != DIR_UP) ||
            (game.direction == DIR_LEFT && new_dir != DIR_RIGHT) ||
            (game.direction == DIR_RIGHT && new_dir != DIR_LEFT)) {
            game.direction = new_dir;
        }
    }

    // Move snake body (optimized loop)
    for (int i = game.length - 1; i > 0; i--) {
        game.snake[i] = game.snake[i - 1];
    }

    // Move snake head
    switch (game.direction) {
        case DIR_UP:    game.snake[0].y--; break;
        case DIR_DOWN:  game.snake[0].y++; break;
        case DIR_LEFT:  game.snake[0].x--; break;
        case DIR_RIGHT: game.snake[0].x++; break;
        default: break;
    }

    // Check wall collision with wrap-around option (comment out for classic mode)
    /*
    game.snake[0].x = (game.snake[0].x + GRID_WIDTH) % GRID_WIDTH;
    game.snake[0].y = (game.snake[0].y + GRID_HEIGHT) % GRID_HEIGHT;
    */

    // Classic wall collision (uncomment above and comment this for wrap-around)
    if (game.snake[0].x < 0 || game.snake[0].x >= GRID_WIDTH ||
        game.snake[0].y < 0 || game.snake[0].y >= GRID_HEIGHT) {
        game.game_state = 1; // Game over
        return;
    }

    // Check self collision (optimized: only check if length > 4)
    if (game.length > 4) {
        for (int i = 4; i < game.length; i++) {
            if (game.snake[0].x == game.snake[i].x && game.snake[0].y == game.snake[i].y) {
                game.game_state = 1; // Game over
                return;
            }
        }
    }

    // Check food collision
    if (game.snake[0].x == game.food.x && game.snake[0].y == game.food.y) {
        if (game.length < SNAKE_MAX_LENGTH) {
            // Grow snake by copying the tail
            game.snake[game.length] = game.snake[game.length - 1];
            game.length++;

            // Increase score and speed
            game.score += SCORE_PER_FOOD;
            if (game.game_speed > MIN_SPEED) {
                game.game_speed -= SPEED_INCREMENT;
            }
        }
        place_food();
    }
}

void draw_border() {
    // Draw border around play area
    vga_draw_rect(0, 0, GRID_WIDTH * GRID_SIZE, 1, 0x38); // Top
    vga_draw_rect(0, GRID_HEIGHT * GRID_SIZE - 1, GRID_WIDTH * GRID_SIZE, 1, 0x38); // Bottom
    vga_draw_rect(0, 0, 1, GRID_HEIGHT * GRID_SIZE, 0x38); // Left
    vga_draw_rect(GRID_WIDTH * GRID_SIZE - 1, 0, 1, GRID_HEIGHT * GRID_SIZE, 0x38); // Right
}

void draw_score() {
    // Simple score display (could be enhanced with proper font)
    for (int i = 0; i < (game.score / SCORE_PER_FOOD) % 10; i++) {
        vga_draw_rect(300 + i * 2, 5, 2, 2, 0x1C); // Green dots for score
    }
}

void draw_game() {
    // Clear screen with dark blue background
    vga_clear_screen(0x03);

    // Draw play area background
    vga_draw_rect(1, 1, GRID_WIDTH * GRID_SIZE - 2, GRID_HEIGHT * GRID_SIZE - 2, 0x01);

    // Draw border
    draw_border();

    // Draw food (pulsating red effect)
    static uint8_t food_pulse = 0;
    uint8_t food_color = 0xE0 | ((food_pulse++ & 0x04) ? 0x08 : 0x00);
    vga_draw_rect(game.food.x * GRID_SIZE, game.food.y * GRID_SIZE,
                 GRID_SIZE, GRID_SIZE, food_color);

    // Draw snake with gradient effect
    for (int i = 0; i < game.length; i++) {
        // Calculate color gradient from head to tail
        uint8_t intensity = 0x1F - (i * 0x10 / game.length);
        if (intensity < 0x0C) intensity = 0x0C;

        uint8_t color = (intensity << 2) | 0x03; // Green with blue tint

        // Head is brighter and larger
        if (i == 0) {
            vga_draw_rect(game.snake[i].x * GRID_SIZE - 1, game.snake[i].y * GRID_SIZE - 1,
                         GRID_SIZE + 2, GRID_SIZE + 2, 0x1F);
        } else {
            vga_draw_rect(game.snake[i].x * GRID_SIZE, game.snake[i].y * GRID_SIZE,
                         GRID_SIZE, GRID_SIZE, color);
        }
    }

    // Draw score
    draw_score();

    // Game over screen
    if (game.game_state == 1) {
        // Semi-transparent overlay
        for (int y = 70; y < 170; y += 2) {
            for (int x = 80; x < 240; x += 2) {
                vga_draw_rect(x, y, 2, 2, 0xE3);
            }
        }
        // You could add "GAME OVER" text here with a simple font
    }
}

// Optimized delay function with frame skipping
void adaptive_delay(uint32_t cycles) {
    static uint32_t frame_count = 0;
    static uint8_t skip_frame = 0;

    frame_count++;

    // Skip every 3rd frame if game is too slow (adjust based on performance)
    if (frame_count % 3 == 0 && game.length > 20) {
        skip_frame = 1;
    }

    if (!skip_frame) {
        for (volatile uint32_t i = 0; i < cycles; i++) {
            asm volatile ("nop");
        }
    }

    skip_frame = 0;
}

int main() {
    init_game();
    game.high_score = 0;

    while (1) {
        // Handle input even when game is over/paused
        Direction input = get_input();

        if (game.game_state == 1) { // Game over
            if (input != DIR_NONE) {
                reset_game();
            }
        } else if (game.game_state == 0) { // Playing
            update_game();
        }
        // Paused state would go here

        draw_game();
        adaptive_delay(game.game_speed);
    }

    return 0;
}
