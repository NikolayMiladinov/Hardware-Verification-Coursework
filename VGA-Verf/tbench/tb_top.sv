`include "transaction.sv"
`include "generator.sv"
`include "vga_intf.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "env.sv"
`include "test.sv"

module tb_top;
  
    //clock and reset signal declaration
    bit clk;

    //clock generation
    always #10 clk = ~clk;

    //creatinng instance of interface, inorder to connect DUT and testcase
    vga_intf intf(clk);

    //DUT instance, interface signals are connected to the DUT ports
    AHBVGA DUT(
        .HCLK(intf.HCLK),
        .HRESETn(intf.HRESETn),
        .HADDR(intf.HADDR),
        .HTRANS(intf.HTRANS),
        .HWDATA(intf.HWDATA),
        .HWRITE(intf.HWRITE),
        .HSEL(intf.HSEL),
        .HREADY(intf.HREADY),
        .HREADYOUT(intf.HREADYOUT),
        .HRDATA(intf.HRDATA),
        .HSYNC(intf.HSYNC),
        .VSYNC(intf.VSYNC),
        .RGB(intf.RGB)
    );

    //Testcase instance, interface handle is passed to test as an argument
    test t1(intf.DRIV, intf.MON);
  
endmodule