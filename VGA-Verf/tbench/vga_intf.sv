interface vga_intf
    #(parameter WIDTH = 16)
    (input bit HCLK);

    //logic HRESETn, HWRITE, HSEL, HREADY, PARITYSEL, HREADYOUT, PARITYERR;
    logic HRESETn, HWRITE, HSEL, HREADY, HREADYOUT, HREADYOUT_redundant, HSYNC, HSYNC_redundant, VSYNC, VSYNC_redundant;
    logic [WIDTH/2-1:0]       RGB, RGB_redundant;
    logic [2*WIDTH-1:0]       HADDR, HWDATA, HRDATA, HRDATA_redundant;
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
        
        input HREADYOUT_redundant;
        input HRDATA_redundant; 
        input RGB_redundant;
        input HSYNC_redundant;
        input VSYNC_redundant;
    endclocking

    modport DRIV (clocking cb_DRIV, input HCLK, output HRESETn);
    modport MON (clocking cb_MON, input HCLK, HRESETn);


    // Cover functionality of addressing, that the only functional addresses are 'h5300_0000 and 'h5300_0004
    // Only bottom 8 bits are used in rtl
    covergroup haddr;
        coverpoint HADDR{
            bins data_addr = ('h5200_0000[*2:4]);
            bins others[10] = {['h5200_0001:'h52FF_FFFF]};
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

    covergroup rgb;
        coverpoint RGB{
            bins text = ('h1C[*2:4]);
            bins unused[10] = {['h01:'hFF]};
            bins min = {0};
        }
    endgroup

    logic [7:0] console_wdata;
    logic change_char;

    covergroup console;
        coverpoint console_wdata{
            bins min = {0};
            bins other[10] = {['h1:'hFF]};
        }
    endgroup

    function bit rgb_correct(input logic HSYNC, VSYNC, input logic [7:0] rgb);
        if(!HSYNC || !VSYNC) return (rgb=='h0);
        else return 1'b1;
    endfunction

    covergroup sync;
        HSYNC: coverpoint HSYNC{
            bins one = {1'b1};
            bins zero = {1'b0};
        }
        VSYNC: coverpoint VSYNC{
            bins one = {1'b1};
            bins zero = {1'b0};
        }
        RGB_correct: coverpoint rgb_correct(HSYNC, VSYNC, RGB){
            bins valid_rgb = {1};
            illegal_bins incorrect_rgb = {0};
        }
        cross_sync: cross HSYNC, VSYNC, RGB_correct;
    endgroup

    sync sync_inst = new();
    rgb rgb_inst = new();
    console console_inst = new();
    haddr addr = new();
    hwdata hwdata_inst = new();

    always @(posedge HCLK) begin
        if(HRESETn) begin
            sync_inst.sample();
            rgb_inst.sample();
            console_inst.sample();
            if(HSEL) addr.sample();
            if(HSEL) hwdata_inst.sample();

            if((HADDR == 32'h5200_0000) & HSEL & HWRITE & HTRANS[1] & HREADY) change_char <= 1'b1;
            else change_char <= 1'b0;

            if(change_char) console_wdata <= HWDATA[7:0];
            else console_wdata <= 'h0;

        end else begin
            change_char <= 'b0;
            console_wdata <= 'h0;
        end
        
    end


endinterface