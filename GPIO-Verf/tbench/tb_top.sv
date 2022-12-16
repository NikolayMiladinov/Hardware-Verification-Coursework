`include "transaction.sv"
`include "generator.sv"
`include "gpio_intf.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "env.sv"
`include "test1.sv"
`include "test2.sv"
`include "test3.sv"
`include "test4.sv"
`include "test5.sv"

module tb_top;
  
    //clock and reset signal declaration
    bit clk;

    //clock generation
    always #10 clk = ~clk;

    //creatinng instance of interface, inorder to connect DUT and testcase
    gpio_intf intf(clk);
    // initial begin
    //     intf.parity_injection parity_inj = new();
    //     intf.parity_gen_and_check parity_gc = new();
    //     intf.input_stage gpioin = new();
    //     intf.output_stage outputs = new();
    //     intf.addressing addr = new();
    //     intf.hwdata hwdata = new();
    //     intf.dir_reg dir_reg = new();
    //     intf.sample_coverage();    
    // end

    //DUT instance, interface signals are connected to the DUT ports
    AHBGPIO DUT(
        .HCLK(intf.HCLK),
        .HRESETn(intf.HRESETn),
        .HADDR(intf.HADDR),
        .HTRANS(intf.HTRANS),
        .HWDATA(intf.HWDATA),
        .HWRITE(intf.HWRITE),
        .HSEL(intf.HSEL),
        .HREADY(intf.HREADY),
        .GPIOIN(intf.GPIOIN),
        .HREADYOUT(intf.HREADYOUT),
        .HRDATA(intf.HRDATA),
        .GPIOOUT(intf.GPIOOUT),
        .PARITYSEL(intf.PARITYSEL),
        .PARITYERR(intf.PARITYERR)
    );

    //Testcase instance, interface handle is passed to test as an argument
    // test1 t1(intf.DRIV, intf.MON);
    test2 t1(intf.DRIV, intf.MON);
  
endmodule