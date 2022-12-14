log -r /*
coverage exclude -code c -srcfile AHBGPIO.sv tb_top/DUT/HRDATA[31:16] toggle disable tb_top/DUT/HREADYOUT toggle disable tb_top/DUT/HTRANS[0] toggle disable tb_top/intf/HTRANS[0] toggle disable tb_top/intf/HRDATA[31:16] toggle disable tb_top/intf/HREADYOUT toggle disable tb_top/DUT/HADDR[31:24] toggle disable tb_top/DUT/last_HADDR[31:24] toggle disable tb_top/intf/HADDR[31:24] toggle disable
run -all

