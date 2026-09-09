MEMORY {
    ram (wxa!ri) : ORIGIN = 0x00000000, LENGTH = 64K
    vga_fb (wxa!ri) : ORIGIN = 0x20000000, LENGTH = 76800
    buttons (wxa!ri) : ORIGIN = 0x30000000, LENGTH = 4
}

SECTIONS {
    .text : {
        *(.text.startup)
        *(.text .text.*)
    } >ram

    .data : { *(.data .data.*) } >ram
    .bss : {
        __bss_start = .;
        *(.bss .bss.*)
        __bss_end = .;
    } >ram

    .stack : {
        . = ALIGN(8);
        _stack_start = .;
        . += 0x2000;
        _stack_end = .;
    } >ram
}
