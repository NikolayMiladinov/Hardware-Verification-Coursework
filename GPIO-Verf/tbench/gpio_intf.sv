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
        inout HREADY; 
        input  HREADYOUT;
        input  HRDATA;
        
        output GPIOIN;
        input GPIOOUT;
        // Parity checking interface
        inout PARITYSEL;
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

    modport DRIV (clocking cb_DRIV, input HCLK, output HRESETn);
    modport MON (clocking cb_MON, input HCLK, HRESETn);


    // Always at clock edge, save last values of the following signals
    logic last_PARITYSEL;
    logic [WIDTH:0]     last_GPIOIN;
    
    // Track dir_reg of GPIO
    logic change_dir, sample_parity_inj;
    logic [WIDTH-1:0] gpio_dir;

    // Cover reset in all situations
    // covergroup reset
    //     coverpoint HRESETn{
    //         bins active = {0};
    //         bins inactive = {1};
    //     }
    // endgroup

    // Checks whether PARITYERR is (not) flagged correctly
    function bit gpio_in_parity_flag_check(input logic PARITYSEL, PARITYERR, input logic[16:0] GPIOIN);
        if (GPIOIN[16]!=(PARITYSEL ? ~^GPIOIN[15:0] : ^GPIOIN[15:0])) begin
            return (PARITYERR==1'b1);
        end else begin
            return (PARITYERR==1'b0);
        end
    endfunction

    // Checks whether there is a parity error in GPIOIN
    function bit gpio_in_parity_error(input logic PARITYSEL, input logic[16:0] GPIOIN);
        if (GPIOIN[16]!=(PARITYSEL ? ~^GPIOIN[15:0] : ^GPIOIN[15:0])) begin
            return 1'b1;
        end else begin
            return 1'b0;
        end
    endfunction

    // Returns the parity bit of any input <= 32 bits wide
    function bit parity_bit(input logic[31:0] INPUT);
        return INPUT[16];
    endfunction

    // Cover parity error functionality
    covergroup parity_injection;
        PARITYERR: coverpoint PARITYERR{
            bins no_err = {0};
            bins error = {1};
        }
        PARITYSEL: coverpoint last_PARITYSEL{
            bins even = {0};
            bins odd = {1};
        }
        FLAG_CHECK: coverpoint gpio_in_parity_flag_check(last_PARITYSEL, PARITYERR, last_GPIOIN){
            bins correct_flag = {1};
            illegal_bins incorrect_flag_error = {0};
        }
        cross_flag_err: cross PARITYSEL, PARITYERR, FLAG_CHECK;
    endgroup

    covergroup parity_injection_in_reset;
        // Checks whether parity error was injected during a reset
        IN_PARITY: coverpoint gpio_in_parity_error(PARITYSEL, GPIOIN){
            bins no_err = {0};
            bins error = {1};
        }
        RESET: coverpoint HRESETn{
            bins active = {0};
            bins inactive = {1};
        }
        cross_err_in_reset: cross RESET, IN_PARITY;
    endgroup

    // Cover scenarios of parity generation and checking
    covergroup parity_gen_and_check;
        PARITYSEL: coverpoint last_PARITYSEL{
            bins even = {0};
            bins odd = {1};
        }
        GPIOOUT: coverpoint parity_bit(GPIOOUT){
            bins zero = {0};
            bins one = {1};
        }
        GPIOIN: coverpoint parity_bit(GPIOIN){
            bins zero = {0};
            bins one = {1};
        }
        cross_sel_out: cross PARITYSEL, GPIOOUT;
        cross_sel_in: cross PARITYSEL, GPIOIN;
    endgroup

    covergroup gpioin;
        coverpoint GPIOIN{
            bins one_par[10] = {['h10000:'h1FFFF]};
            bins zero_par[10] = {['h00000:'h0FFFF]};
            bins min = {0};
            bins max = {'h1FFFF};
        }
    endgroup

    covergroup outputs;
        coverpoint HRDATA{
            bins valid[10] = {['h0000:'hFFFF]};
            bins min = {0};
            bins max = {'hFFFF};
            illegal_bins invalid_hrdata = {['h10000:'hFFFF_FFFF]};
        }
        coverpoint GPIOOUT{
            bins one_par[10] = {['h10000:'h1FFFF]};
            bins zero_par[10] = {['h00000:'h0FFFF]};
            bins min = {0};
            bins max = {'h1FFFF};
        }
    endgroup

    // Cover functionality of addressing, that the only functional addresses are 'h5300_0000 and 'h5300_0004
    // Only bottom 8 bits are used in rtl
    covergroup haddr;
        coverpoint HADDR{
            bins dir_addr = ('h5300_0004[*2:4]);
            bins data_addr = ('h5300_0000[*2:4]);
            bins trans = ('h5300_0004 => 'h5300_0000 => 'h5300_0004 => 'h5300_0000);
            bins others[10] = {['h5300_0000:'h53FF_FFFF]};
            illegal_bins invalid_gpio_addr = {[1:'h52FF_FFFF], ['h5400_0000:'hFFFF_FFFF]};
        }
    endgroup

    covergroup hwdata;
        coverpoint HWDATA{
            bins valid[10] = {['h0000:'hFFFF]};
            bins unregistered[3] = {['h10000:'hFFFF_FFFF]};
            bins min = {0};
            bins max = {'hFFFF};
        }
    endgroup

    covergroup dir_reg;
        coverpoint gpio_dir{
            bins in_dir = {0};
            bins out_dir = {1};
            bins others[3] = default;
        }
    endgroup


    parity_injection parity_inj = new();
    parity_injection_in_reset parity_inj_in_reset = new();
    parity_gen_and_check parity_gc = new();
    gpioin gpioin_inst = new();
    outputs outputs_inst = new();
    haddr addr = new();
    hwdata hwdata_inst = new();
    dir_reg dir_reg_inst = new();

    always @(posedge HCLK) begin
        parity_inj_in_reset.sample();
        if(HRESETn) begin
            outputs_inst.sample();
            gpioin_inst.sample();
            parity_gc.sample();
            dir_reg_inst.sample();
            if(HSEL) addr.sample();
            if(HSEL) hwdata_inst.sample();

            if(gpio_dir=='b0) sample_parity_inj <= 1'b1;
            else sample_parity_inj <= 1'b0;
            
            if(sample_parity_inj) parity_inj.sample();

            if((HADDR == 32'h5300_0004) & HSEL & HWRITE & HTRANS[1] & HREADY) change_dir <= 1'b1;
            else change_dir <= 1'b0;

            if(change_dir) gpio_dir <= HWDATA[15:0];

        end else begin
            gpio_dir   <= 'b0;
            change_dir <= 'b0;
            sample_parity_inj <= 'b0;
        end

        last_GPIOIN    <= GPIOIN;
        last_PARITYSEL <= PARITYSEL;
        
    end


endinterface