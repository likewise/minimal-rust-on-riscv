GDB = /opt/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/riscv32-unknown-elf-gdb
OPENOCD = /opt/openocd/bin/openocd

.PHONY:
debug-build:
	cargo build
	#cargo-objdump -C -S -l -d target/riscv32imc-unknown-none-elf/debug/app > app.S
	/opt/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/riscv32-unknown-elf-objdump -S -l -d target/riscv32imc-unknown-none-elf/debug/app > src/main.S

.PHONY:
release-build:
	cargo build --release
	#cargo-objdump -C -S -l -d target/riscv32imc-unknown-none-elf/debug/app > app.S
	/opt/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/riscv32-unknown-elf-objdump -S -l -d target/riscv32imc-unknown-none-elf/release/app > src/main.S


# Upload the program using GDB, which starts OpenOCD (0.11.0+ required) with GDB pipe
upload-debug-build: debug-build
	$(GDB) -batch -q \
	-ex "set remotetimeout 3" \
	-ex "set pagination off" \
	-ex "set remote hardware-breakpoint-limit 2" \
	-ex "set remote hardware-watchpoint-limit 0" \
	-ex "set print asm-demangle on" \
	-ex "target extended-remote | $(OPENOCD) -c \"gdb_port pipe; log_output openocd.log\" -f openocd_zynqmp_bscane2.cfg" \
	-ex "load" \
	target/riscv32imc-unknown-none-elf/debug/app

# Upload the program using GDB, which starts OpenOCD (0.11.0+ required) with GDB pipe
debug: debug-build
	RUST_GDB=$(GDB) rust-gdb -q \
	-ex "set remotetimeout 3" \
	-ex "set pagination off" \
	-ex "skip -gfile **/library/core/src/*/*.rs" \
	-ex "skip -rfunction .*core.*" \
	-ex "skip -rfunction ^core.*" \
	-ex "set remote hardware-breakpoint-limit 2" \
	-ex "set remote hardware-watchpoint-limit 0" \
	-ex "set print asm-demangle on" \
	-ex "target extended-remote | $(OPENOCD) -c \"gdb_port pipe; log_output openocd.log\" -f openocd_zynqmp_bscane2.cfg" \
	-ex "load" \
	-ex "cont" \
	target/riscv32imc-unknown-none-elf/debug/app

issue: release-build
	$(GDB) -q --tui \
	-ex "set remotetimeout 3" \
	-ex "set pagination off" \
	-ex "set remote hardware-breakpoint-limit 2" \
	-ex "set print asm-demangle on" \
	-ex "target extended-remote | $(OPENOCD) -c \"gdb_port pipe; log_output openocd.log\" -f openocd_zynqmp_bscane2.cfg" \
	-ex "load" \
	-ex "layout split" \
	-ex "focus cmd" \
	-ex "hbreak *0x1000d8" \
	-ex "cont" \
	-ex "info var" \
	target/riscv32imc-unknown-none-elf/release/app



size:
	cargo size --release -- -A
