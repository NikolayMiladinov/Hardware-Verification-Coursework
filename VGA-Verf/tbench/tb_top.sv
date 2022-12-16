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
    logic [31:0] HWDATA_primary;

    //clock generation
    always #10 clk = ~clk;

    //creatinng instance of interface, inorder to connect DUT and testcase
    vga_intf intf(clk);


    assign HWDATA_primary = (intf.HWDATA=='h07) ? 'h17 : intf.HWDATA;
    // initial begin
    //     if(intf.HWDATA=='h07) HWDATA_primary='h08;
    //     else HWDATA_primary = intf.HWDATA;
    // end

    //DUT instance, interface signals are connected to the DUT ports
    AHBVGA DUT_primary(
        .HCLK(intf.HCLK),
        .HRESETn(intf.HRESETn),
        .HADDR(intf.HADDR),
        .HTRANS(intf.HTRANS),
        .HWDATA(HWDATA_primary),
        .HWRITE(intf.HWRITE),
        .HSEL(intf.HSEL),
        .HREADY(intf.HREADY),
        .HREADYOUT(intf.HREADYOUT),
        .HRDATA(intf.HRDATA),
        .HSYNC(intf.HSYNC),
        .VSYNC(intf.VSYNC),
        .RGB(intf.RGB)
    );

    AHBVGA DUT_redundant(
        .HCLK(intf.HCLK),
        .HRESETn(intf.HRESETn),
        .HADDR(intf.HADDR),
        .HTRANS(intf.HTRANS),
        .HWDATA(intf.HWDATA),
        .HWRITE(intf.HWRITE),
        .HSEL(intf.HSEL),
        .HREADY(intf.HREADY),
        .HREADYOUT(intf.HREADYOUT_redundant),
        .HRDATA(intf.HRDATA_redundant),
        .HSYNC(intf.HSYNC_redundant),
        .VSYNC(intf.VSYNC_redundant),
        .RGB(intf.RGB_redundant)
    );

    //Testcase instance, interface handle is passed to test as an argument
    test t1(intf.DRIV, intf.MON);
  
endmodule