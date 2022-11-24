interface gpio_intf
    #(parameter WIDTH = 16)
    (input bit HCLK);

    //logic HRESETn, HWRITE, HSEL, HREADY, PARITYSEL, HREADYOUT, PARITYERR;
    logic HRESETn, HWRITE, HSEL, HREADY, HREADYOUT;
    logic [2*WIDTH-1:0]       HADDR, HWDATA, HRDATA;
    logic [WIDTH-1:0]       GPIOIN, GPIOOUT;
    logic [1:0] HTRANS;

    clocking cb_DRIV @(posedge HCLK);
        default input #1 output #1;
        output HADDR; // input
        output HTRANS; // input
        output HWDATA; // input
        output HWRITE; // input
        output HSEL; // input
        output HREADY; // input
        input  HREADYOUT; // output
        input  HRDATA; // output

        // Parity checking interface
        // output PARITYSEL; // input
        // input  PARITYERR; // output
        output GPIOIN;
        input GPIOOUT;

    endclocking

    clocking cb_MON @(posedge HCLK);
        default input #1 output #1;
        input HADDR; // input
        input HTRANS; // input
        input HWDATA; // input
        input HWRITE; // input
        input HSEL; // input
        input HREADY; // input
        input HREADYOUT; // output
        input HRDATA; // output

        // Parity checking interface
        // input PARITYSEL; // input
        // input PARITYERR; // output
        input GPIOIN;
        input GPIOOUT;

    endclocking

    modport DUT (input HCLK, HRESETn, HWRITE, HSEL, HREADY, HADDR, HWDATA, HTRANS, GPIOIN 
                output HRDATA, GPIOOUT, HREADYOUT);

    modport DRIV (clocking cb_DRIV, input HCLK, HRESETn, output GPIOIN, PARITYSEL);
    modport MON (clocking cb_MON, input HCLK, HRESETn, GPIOIN, PARITYSEL);

endinterface