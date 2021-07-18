target extended-remote | /opt/openocd/bin/openocd -c "gdb_port pipe; log_output openocd.log" -f openocd_zynqmp_bscane2.cfg
set pagination off
#layout split
load
#break *0x100080
#break reset_handler
#cont
