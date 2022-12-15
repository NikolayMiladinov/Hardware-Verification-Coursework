interface vga_intf
    #(parameter WIDTH = 16)
    (input bit HCLK);

    //logic HRESETn, HWRITE, HSEL, HREADY, PARITYSEL, HREADYOUT, PARITYERR;
    logic HRESETn, HWRITE, HSEL, HREADY, HREADYOUT, HSYNC, VSYNC;
    logic [WIDTH/2-1:0]       RGB;
    logic [2*WIDTH-1:0]       HADDR, HWDATA, HRDATA;
    logic [1:0] HTRANS;

    clocking cb_DRIV @(posedge HCLK);
        default input #1 output #1;
        output HADDR; 
        inout HTRANS; 
        output HWDATA; 
        output HWRITE; 
        inout HSEL; 
        inout HREADY; 

        input  HREADYOUT;
        input  HRDATA;
        input RGB;
        input VSYNC;
        input HSYNC;
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

        input RGB;
        input HSYNC;
        input VSYNC;
    endclocking

    modport DRIV (clocking cb_DRIV, input HCLK, output HRESETn);
    modport MON (clocking cb_MON, input HCLK, HRESETn);


    covergroup outputs;
        coverpoint HRDATA{
            bins valid[10] = {['h0000:'hFFFF]};
            bins min = {0};
            bins max = {'hFFFF};
            illegal_bins invalid_hrdata = {['h10000:'hFFFF_FFFF]};
        }
    endgroup

    // Cover functionality of addressing, that the only functional addresses are 'h5300_0000 and 'h5300_0004
    // Only bottom 8 bits are used in rtl
    covergroup haddr;
        coverpoint HADDR{
            bins data_addr = ('h5200_0000[*2:4]);
            bins others[10] = {['h5200_0000:'h52FF_FFFF]};
            illegal_bins invalid_vga_addr = {[1:'h51FF_FFFF], ['h5300_0000:'hFFFF_FFFF]};
        }
    endgroup

    covergroup hwdata;
        coverpoint HWDATA{
            bins valid[10] = {['h00:'h7F]};
            bins unused[3] = {['h80:'hFFFF_FFFF]};
            bins min = {0};
            bins max = {'h7F};
        }
    endgroup

    outputs outputs_inst = new();
    haddr addr = new();
    hwdata hwdata_inst = new();

    always @(posedge HCLK) begin
        if(HRESETn) begin
            outputs_inst.sample();
            if(HSEL) addr.sample();
            if(HSEL) hwdata_inst.sample();

        end else begin
            
        end
        
    end


endinterface