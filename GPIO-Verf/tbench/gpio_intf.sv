interface gpio_intf
    #(parameter WIDTH = 16)
    (input bit HCLK);

    //logic HRESETn, HWRITE, HSEL, HREADY, PARITYSEL, HREADYOUT, PARITYERR;
    logic HRESETn, HWRITE, HSEL, HREADY, HREADYOUT, PARITYSEL, PARITYERR;
    logic [2*WIDTH-1:0]       HADDR, HWDATA, HRDATA;
    logic [WIDTH:0]       GPIOIN, GPIOOUT;
    logic [1:0] HTRANS;

    clocking cb_DRIV @(posedge HCLK);
        default input #1 output #1;
        output HADDR; 
        output HTRANS; 
        output HWDATA; 
        output HWRITE; 
        output HSEL; 
        output HREADY; 
        input  HREADYOUT;
        input  HRDATA;
        
        output GPIOIN;
        input GPIOOUT;
        // Parity checking interface
        output PARITYSEL;
        input  PARITYERR;

    endclocking

    clocking cb_MON @(posedge HCLK);
        default input #1 output #1;
        input HADDR;
        input HTRANS;
        input HWDATA;
        input HWRITE;
        input HSEL;
        input HREADY;
        input HREADYOUT;
        input HRDATA; 

        input GPIOIN;
        input GPIOOUT;
        // Parity checking interface
        input PARITYSEL;
        input PARITYERR;

    endclocking

    modport DRIV (clocking cb_DRIV, input HCLK, HRESETn, output GPIOIN);
    modport MON (clocking cb_MON, input HCLK, HRESETn, GPIOIN);

endinterface