/* Copyright lowRISC contributors.
   Licensed under the Apache License, Version 2.0, see LICENSE for details.
   SPDX-License-Identifier: Apache-2.0 */

OUTPUT_ARCH(riscv)

MEMORY
{
    /* note that the ROM currently is a writable BRAM */
    rom         : ORIGIN = 0x00100000, LENGTH = 0xE000 /* 56 kB */
    ram         : ORIGIN = 0x0010E000, LENGTH = 0x1000 /*  4 kB */
    stack       : ORIGIN = 0x0010F000, LENGTH = 0x1000  /* 4 kB */
}

/* Stack information variables */
_min_stack      = 0x800;   /* 4K - minimum stack space to reserve */
_stack_len     = LENGTH(stack);
_stack_bottom  = ORIGIN(stack);
_stack_top     = ORIGIN(stack) + LENGTH(stack);

_entry_point = ORIGIN(rom) + 0x80;
ENTRY(_entry_point)

/* The tohost address is used by Spike for a magic "stop me now" message. This
   is set to equal SIM_CTRL_CTRL (see simple_system_regs.h), which has that
   effect in simple_system simulations. Note that it must be 8-byte aligned.

   We don't read data back from Spike, so fromhost is set to some dummy value:
   we place it just above the top of the stack.
 */
tohost   = 0x20008;
fromhost = _stack_top + 0x10;

SECTIONS
{
    .riscv.ibex.trampoline ORIGIN(rom) :
    {
        KEEP(*(.riscv.ibex.trampoline));
        /*. = ALIGN(4);*/
    } > rom

    .riscv.ibex.start (ORIGIN(rom) + 0x80) :
    {
        KEEP(*(.riscv.ibex.start));
        . = ALIGN(4);
    } > rom

    .text : {
        . = ALIGN(4);
        _stext = .;
        KEEP(*(.riscv.start));
        *(.text)
        *(.text.*)
    }  > rom

    .rodata : {
        . = ALIGN(4);
        /* Small RO data before large RO data */
        *(.srodata)
        *(.srodata.*)
        *(.rodata)
        *(.rodata.*)

    . = ALIGN(4);
    _etext = .;

    } > rom


    /*The .data section contains static variables which have an initial value at boot. */
    /* load address (LMA) and its virtual address (VMA). */
    /* You can think of the LMA as the address “at rest” and the VMA the address during
    /* execution i.e. when the device is on and the program is running. */

    /* } > ram AT > rom */
    /* "> ram" is the VMA, "> rom" is the LMA */
    /* similar, more explicit: */
    /* .data ORIGIN(ram): AT(ORIGIN(rom))
    */

    .data : {
        . = ALIGN(4);
        _sdata = .;

        PROVIDE(__global_pointer$ = . + 0x800);

        /* Small data before large data */
        *(.ramfunc .ramfunc.*)
        *(.sdata .sdata.* .gnu.linkonce.r.*)
        *(.data .data.*)
        . = ALIGN(4);
        _edata = .;
    } > ram AT > rom

    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        _bss_start = .;
        /* Small BSS before large BSS */
        *(.sbss)
        *(.sbss.*)
        *(.bss)
        *(.bss.*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > ram

    /* ensure there is enough room for stack */
    .stack (NOLOAD): {
        . = ALIGN(4);
        . = . + _min_stack ;
        . = ALIGN(4);
        stack = . ;
        _stack = . ;
    } > stack

    /* Discard RISC-V relevant .eh_frame, we are not doing unwind on panic
    so it is not needed. */
    /DISCARD/ :
    {
      *(.eh_frame);
      *(.ARM.exidx .ARM.exidx.*);
    }

    /* https://microchipsupport.force.com/s/article/How-to-fill-unused-Flash-locations-with-known-values-while-building-a-project */
}
