GDB = /opt/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/riscv32-unknown-elf-gdb
OPENOCD = /opt/openocd/bin/openocd

.PHONY:
debug-build:
	cargo build
	#cargo-objdump -S -l -d target/riscv32imc-unknown-none-elf/debug/app > app.S
	/opt/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/riscv32-unknown-elf-objdump -S -l -d target/riscv32imc-unknown-none-elf/debug/app > src/main.S

.PHONY:
release-build:
	cargo build --release
	#cargo-objdump -S -l -d target/riscv32imc-unknown-none-elf/debug/app > app.S
	/opt/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/riscv32-unknown-elf-objdump -S -l -d target/riscv32imc-unknown-none-elf/debug/app > src/main.S


# Upload the program using GDB, which starts OpenOCD (0.11.0+ required) with GDB pipe
upload-debug-build: debug-build
	$(GDB) -batch -q \
	-ex "set remotetimeout 3" \
	-ex "set pagination off" \
	-ex "set remote hardware-breakpoint-limit 2" \
	-ex "set print asm-demangle on" \
	-ex "target extended-remote | $(OPENOCD) -c \"gdb_port pipe; log_output openocd.log\" -f openocd_zynqmp_bscane2.cfg" \
	-ex "load" \
	target/riscv32imc-unknown-none-elf/debug/app

# Upload the program using GDB, which starts OpenOCD (0.11.0+ required) with GDB pipe
debug: debug-build
	$(GDB) -q \
	-ex "set remotetimeout 3" \
	-ex "set pagination off" \
	-ex "set remote hardware-breakpoint-limit 2" \
	-ex "set print asm-demangle on" \
	-ex "target extended-remote | $(OPENOCD) -c \"gdb_port pipe; log_output openocd.log\" -f openocd_zynqmp_bscane2.cfg" \
	-ex "load" \
	-ex "cont" \
	target/riscv32imc-unknown-none-elf/debug/app

issue: release-build
	$(GDB) -q \
	-ex "set remotetimeout 3" \
	-ex "set pagination off" \
	-ex "set remote hardware-breakpoint-limit 2" \
	-ex "set print asm-demangle on" \
	-ex "target extended-remote | $(OPENOCD) -c \"gdb_port pipe; log_output openocd.log\" -f openocd_zynqmp_bscane2.cfg" \
	-ex "load" \
	-ex "layout split" \
  -ex "break *0x100060" \
	target/riscv32imc-unknown-none-elf/release/app