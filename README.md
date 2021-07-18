# An Embedded Rust program for RISC-V from scratch

This is an non-Rust-idiomic way to get acquinted with the
startup sequence for embedded Rust on bare-metal RISC-V.

This application is targeting the Ibex RISC-V "super-system-gpio" design.

Based on a combination of

https://docs.rust-embedded.org/embedonomicon/memory-layout.html
https://github.com/tock/tock/blob/master/doc/Startup.md


$ rustup target add thumbv7m-none-eabi

$ # cargo-binutils
$ cargo install cargo-binutils

$ rustup component add llvm-tools-preview

cargo objdump --bin app -- -d --no-show-raw-insn

cargo objdump --bin app -- -s --section .vectors

cargo objdump --bin app -- -d

Disassembly of section .text:

00100084 <exception_handler>:
  100084: 41 11         addi    sp, sp, -16
  100086: 13 05 a0 02   addi    a0, zero, 42
  10008a: 2a c6         sw      a0, 12(sp)
  10008c: 09 a0         j       0x10008e <exception_handler+0xa>
  10008e: 01 a0         j       0x10008e <exception_handler+0xa>

00100090 <timer_handler>:
  100090: 41 11         addi    sp, sp, -16
  100092: 13 05 a0 02   addi    a0, zero, 42
  100096: 2a c6         sw      a0, 12(sp)
  100098: 09 a0         j       0x10009a <timer_handler+0xa>
  10009a: 01 a0         j       0x10009a <timer_handler+0xa>

0010009c <reset_handler>:
  10009c: 41 11         addi    sp, sp, -16
  10009e: 13 05 a0 02   addi    a0, zero, 42
  1000a2: 2a c6         sw      a0, 12(sp)
  1000a4: 09 a0         j       0x1000a6 <reset_handler+0xa>
  1000a6: 01 a0         j       0x1000a6 <reset_handler+0xa>



tock$ less arch/rv32i/src/lib.rs
less boards/kernel_layout.ld

# debug

/opt/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/riscv32-unknown-elf-gdb -x openocd_pipe.gdb target/riscv32imc-unknown-none-elf/debug/app