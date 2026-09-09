.section .text.startup
.global _start

_start:
    # Initialize stack pointer
    la sp, _stack_start

    # Clear BSS section
    la a0, __bss_start
    la a1, __bss_end
clear_bss:
    beq a0, a1, done_bss
    sw zero, 0(a0)
    addi a0, a0, 4
    j clear_bss
done_bss:

    # Call main function
    call main

    # If main returns, hang
    j .
