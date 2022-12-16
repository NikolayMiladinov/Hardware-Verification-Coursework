log -r /*
toggle disable tb_top/DUT_primary/HTRANS[0]
toggle disable tb_top/intf/HTRANS[0]
toggle disable tb_top/intf/HRDATA[31:0]
toggle disable tb_top/DUT_primary/HRDATA[31:0]
toggle disable tb_top/intf/HADDR[31:24]
toggle disable tb_top/DUT_primary/HADDR[31:24]
toggle disable tb_top/DUT_primary/uvga_image/*
run -all
coverage save -du work.tb_top -onexit test_coverage.ucdb