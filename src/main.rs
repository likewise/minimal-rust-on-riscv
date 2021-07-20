
/* this program does have a main() but not one that fulfills Rust's
 * expectations, such as command line arguments ; use no_main*/
#![no_main]
#![no_std]
#![feature(asm, const_fn_trait_bound, naked_functions)]

use core::panic::PanicInfo;

/* ! means this is a divergent function; it will never return */
#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}

/* use the function name as its symbol name */
#[no_mangle] // not required, see https://rust-lang.github.io/rfcs/2873-inline-asm.html
pub unsafe extern "C" fn exception_handler() -> () {
    let _x = 42;
    // can't return so we go into an infinite loop here
    loop {}
    
}

#[no_mangle] // not required, see https://rust-lang.github.io/rfcs/2873-inline-asm.html
pub unsafe extern "C" fn timer_handler() -> () {
    let _x = 43;
    // can't return so we go into an infinite loop here
    loop {}
}

#[no_mangle]
pub unsafe extern "C" fn reset_handler() -> () {
    let _x = 44;
    // can't return so we go into an infinite loop here
    loop {}
}

// The reset vector, a pointer into the reset handler

/* places the symbol in a section named .vectors */
//#[link_section = ".vectors"]
//#[no_mangle]
//#[used]
//pub static RESET_VECTOR: unsafe extern "C" fn() -> () = reset_handler;

//#[used]
//pub static mut my_data: &'static str = "long_string";
//#[used]
//pub static my_rodata: &'static str = "long_string2";

extern "C" {
    // Where the end of the stack region is (and hence where the stack should
    // start).
    static _stack_top: usize;
    static _stack_bottom: usize;

    // first and last address of .bss section in linker script
    static mut _bss_start: usize;
    static mut _bss_end: usize;

    // Where the .data section is stored in flash.
    static mut _etext: usize;

    // Boundaries of the .data section.
    static mut _sdata: usize;
    static mut _edata: usize;

    // The global pointer, value set in the linker script
    static __global_pointer: usize;
}

#[cfg(all(target_arch = "riscv32", target_os = "none"))]
#[link_section = ".riscv.ibex.trampoline"]
#[export_name = "_trampoline"]
#[naked]
/* The only way to make a symbol external in Rust is to make its corresponding item public (pub)
 * and reachable (no private module between the item and the root of the crate). */
pub extern "C" fn _trampoline() {
    unsafe {
        /* the following instructions should not be RISC-V compressed */
        asm! ("
            j exception_handler
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {timer_handler_address}
            j {exception_handler_address} // 1
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address}
            j {exception_handler_address} // 23
        ",
        exception_handler_address = sym exception_handler,
        timer_handler_address = sym timer_handler,
        options(noreturn)
        );
    }
}

#[cfg(all(target_arch = "riscv32", target_os = "none"))]
#[link_section = ".riscv.ibex.start"]
#[export_name = "_start"]
#[naked]
/* The only way to make a symbol external in Rust is to make its corresponding item public (pub)
 * and reachable (no private module between the item and the root of the crate). */
pub extern "C" fn _start() {
    unsafe {
        /* in naked functions only one asm! block may appear -- use GDB with assembler view to debug this */
        asm! ("
            mv  x1, zero // x1 == ra (return address)
            mv  x2, zero // x2 == sp (stack pointer)
            mv  x3, zero // x3 == gp (global pointer)
            mv  x4, zero // x4 == tp (thread pointer)
            mv  x5, zero // x5 == t0 (temporary register)
            mv  x6, zero // x6 == t1 (temporary register)
            mv  x7, zero // x7 == t2 (temporary register)
            mv  x8, zero // x8 == s0 (saved register == frame pointer)
            mv  x9, zero // x9 == s1 (saved register)
            mv x10, zero
            mv x11, zero
            mv x12, zero
            mv x13, zero
            mv x14, zero
            mv x15, zero
            mv x16, zero
            mv x17, zero
            mv x18, zero
            mv x19, zero
            mv x20, zero
            mv x21, zero
            mv x22, zero
            mv x23, zero
            mv x24, zero
            mv x25, zero
            mv x26, zero
            mv x27, zero
            mv x28, zero // x28 == t3 (temporary register)
            mv x29, zero // x29 == t4 (temporary register)
            mv x30, zero // x30 == t5 (temporary register)
            mv x31, zero // x31 == t6 (temporary register) 

            /* initialize stack pointer initialization */
            lui  sp, %hi({estack})
            addi sp, sp, %lo({estack})
            //la x2, {estack}

            // Set s0 (the frame pointer) to the start of the stack.
            add  s0, sp, zero

            la a0, {sbss}               // a0 = first address of .bss
            la a1, {ebss}               // a1 = first address after .bss

            bss_init_loop:
            beq  a0, a1, bss_init_done  // If a0 == a1, we are done.
            sw   zero, 0(a0)            // *a0 = 0. Write 0 to the memory location in a0.
            addi a0, a0, 4              // a0 = a0 + 4. Increment pointer to next word.
            j bss_init_loop             // Continue the loop.
            bss_init_done:

            // Now initialize .data memory. This involves coping the values right at the
            // end of the .text section (in flash) into the .data section (in RAM).
            la a0, {sdata}              // a0 = first address of data section in RAM
            la a1, {edata}              // a1 = first address after data section in RAM
            la a2, {etext}              // a2 = address of stored data initial values

            data_init_loop:
            beq  a0, a1, data_init_done // If we have reached the end of the .data
                                        // section then we are done.
            lw   a3, 0(a2)              // a3 = *a2. Load value from initial values into a3.
            sw   a3, 0(a0)              // *a0 = a3. Store initial value into
                                        // next place in .data.
            addi a0, a0, 4              // a0 = a0 + 4. Increment to next word in memory.
            addi a2, a2, 4              // a2 = a2 + 4. Increment to next word in flash.
            j data_init_loop            // Continue the loop.

            data_init_done:

            j main
            ",
        //gp = sym __global_pointer,
        estack = sym _stack_top,
        sbss = sym _bss_start,
        ebss = sym _bss_end,
        sdata = sym _sdata,
        edata = sym _edata,
        etext = sym _etext,
        options(noreturn)
        );
    }
}

//#[used] /* ends up in .data section */
//static mut outer: u32 = 53;

#[no_mangle]
pub unsafe fn main() -> ! {

    //let peripherals = ibex_supersystem::Peripherals::take().unwrap();
    //let mut outer = 0;
    let mut counter = 0;
    let mut outer: u32 = 0;
    loop {
        // if we do not have peripherals, make main unsafe and write volatile to the GPIO peripheral
        core::ptr::write_volatile(0x80000000 as *mut u32, counter);

        // if we have peripherals 
        //peripherals.GPIO0.out.write(|w| unsafe { w.bits(counter) });

//        if (counter % 2) == 1 {
//            peripherals.GPIO0.out.write(|w| w.led0().clear_bit());
//        } else {
//            peripherals.GPIO0.out.write(|w| w.led0().set_bit());
//        }
        outer += 1;
        if outer == 1000000 {
            outer = 0;
            counter += 1;
        }
    }
    /* make sure we never return, together with -> ! optimizes out a call to the panic_handler */
    loop {}
}

pub fn other(x: usize, y: usize) -> usize {
    let mut z: usize;
    z = x * y;
    z += 1;
    z
}

