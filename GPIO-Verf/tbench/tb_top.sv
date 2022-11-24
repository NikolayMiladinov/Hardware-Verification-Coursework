module tb_top;
  
    //clock and reset signal declaration
    bit clk;

    //clock generation
    always #10 clk = ~clk;

    //reset Generation
    // initial begin
    //     test.env.reset_test();
    // end

    //creatinng instance of interface, inorder to connect DUT and testcase
    gpio_intf intf(clk);

    //DUT instance, interface signals are connected to the DUT ports
    AHBGPIO DUT(
        .HCLK(intf.DUT.HCLK),
        .HRESETn(intf.DUT.HRESETn),
        .HADDR(intf.DUT.HADDR),
        .HTRANS(intf.DUT.HTRANS),
        .HWDATA(intf.DUT.HWDATA),
        .HWRITE(intf.DUT.HWRITE),
        .HSEL(intf.DUT.HSEL),
        .HREADY(intf.DUT.HREADY),
        .GPIOIN(intf.DUT.GPIOIN),
        .PARITYSEL(intf.DUT.PARITYSEL),
        .HREADYOUT(intf.DUT.HREADYOUT),
        .HRDATA(intf.DUT.HRDATA),
        .GPIOOUT(intf.DUT.GPIOOUT),
        .PARITYERR(intf.DUT.PARITYERR)
    );

    //Testcase instance, interface handle is passed to test as an argument
    test t1(intf.DRIV);
  
endmodule