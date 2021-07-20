# An Embedded Rust program for RISC-V from scratch

This is an non-Rust-idiomic way to get acquinted with the
startup sequence for embedded Rust on bare-metal RISC-V.

This application is targeting the Ibex RISC-V "super-system-gpio" design.

Based on a combination of

https://docs.rust-embedded.org/embedonomicon/memory-layout.html
https://github.com/tock/tock/blob/master/doc/Startup.md

https://docs.rs/svd2rust/0.19.0/svd2rust/

From the Rust RTOS called "Tock":

Rust initial run-time (also known as "r0") in assembly:
https://github.com/tock/tock/blob/master/arch/rv32i/src/lib.rs
which has an interdependency on the linker script:
https://github.com/tock/tock/blob/master/boards/kernel_layout.ld

$ rustup target add riscv32imc-unknown-none-elf

$ # cargo-binutils
$ cargo install cargo-binutils

$ rustup component add llvm-tools-preview

cargo objdump --bin app -- -d --no-show-raw-insn

cargo objdump --bin app -- -s --section .vectors

cargo objdump --bin app -- -d

### Dump contents of rodata

cargo objdump --release -- -s -j .rodata

# debug

/opt/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/riscv32-unknown-elf-gdb -x openocd_pipe.gdb target/riscv32imc-unknown-none-elf/debug/app