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

    modport DRIV (clocking cb_DRIV, input HCLK, HRESETn, output GPIOIN);
    modport MON (clocking cb_MON, input HCLK, HRESETn, GPIOIN);


    // Always at clock edge, save last values of the following signals
    logic last_PARITYSEL;
    logic [2*WIDTH-1:0] last_HADDR, last_HWDATA, last_HRDATA;
    logic [WIDTH:0]     last_GPIOIN, last_GPIOOUT;
    // Cover reset in all situations
    // covergroup reset
    //     coverpoint HRESETn{
    //         bins active = {0};
    //         bins inactive = {1};
    //     }
    // endgroup


    function bit gpio_in_parity_flag_check(input logic PARITYSEL, PARITYERR, input logic[16:0] GPIOIN)
        if (GPIOIN[16]!=(PARITYSEL ? ~^GPIOIN[15:0] : ^GPIOIN[15:0])) begin
            return (PARITYERR==1'b1);
        end else begin
            return (PARITYERR==1'b0);
        end
    endfunction

    function bit gpio_in_parity_error(input logic PARITYSEL, input logic[16:0] GPIOIN)
        if (GPIOIN[16]!=(PARITYSEL ? ~^GPIOIN[15:0] : ^GPIOIN[15:0])) begin
            return 1'b1;
        end else begin
            return 1'b0;
        end
    endfunction

    function bit parity_bit(input logic[31:0] INPUT)
        return INPUT[16];
    endfunction

    // Cover parity error functionality
    covergroup parity_injection
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
        IN_PARITY: coverpoint gpio_in_parity_error(PARITYSEL, GPIOIN){
            bins no_err = {0};
            bins error = {1};
        }
        RESET: coverpoint HRESETn{
            bins active = {0};
            bins inactive = {1};
        }
        cross_flag_err: cross PARITYSEL, PARITYERR, FLAG_CHECK;
        cross_err_in_reset: cross RESET, IN_PARITY;
    endgroup

    // Cover scenarios of parity generation and checking
    covergroup parity_gen_and_check
        PARITYSEL: coverpoint last_PARITYSEL{
            bins even = {0};
            bins odd = {1};
        }
        GPIOOUT: coverpoint parity_bit(GPIOOUT){
            bins null = {0};
            bins one = {1};
        }
        GPIOIN: coverpoint parity_bit(GPIOIN){
            bins null = {0};
            bins one = {1};
        }
        HRDATA: coverpoint parity_bit(HRDATA){
            bins null = {0};
            bins one = {1};
        }
        cross_sel_out: cross PARITYSEL, GPIOOUT;
        cross_sel_in: cross PARITYSEL, GPIOIN;
        cross_sel_in: cross PARITYSEL, HRDATA;
    endgroup

    // Cover scenarios of HREADY, HTRANS, HWRITE, HSEL
    covergroup command_signals

    endgroup

    // Cover important cases when direction is input
    covergroup input_stage
        coverpoint GPIOIN{
            bins one_par[10] = {'h10000:'h1FFFF};
            bins zero_par[10] = {'h00000:'h0FFFF};
            bins min = {0};
            bins max = {'h1FFFF};
        }
        coverpoint HRDATA{
            bins one_par[10] = {'h10000:'h1FFFF};
            bins zero_par[10] = {'h00000:'h0FFFF};
            bins min = {0};
            bins max = {'h1FFFF};
            illegal_bins zero_par[10] = {'h20000:'hFFFF_FFFF};
        }
    endgroup

    // Cover important cases when direction is output
    covergroup output_stage
        coverpoint HWDATA{
            bins valid[10] = {'h0000:'hFFFF};
            bins unregistered[3] = {'h10000:'hFFFF_FFFF};
            bins min = {0};
            bins max = {'hFFFF};
        }
        coverpoint GPIOOUT{
            bins one_par[10] = {'h10000:'h1FFFF};
            bins zero_par[10] = {'h00000:'h0FFFF};
            bins min = {0};
            bins max = {'h1FFFF};
        }
    endgroup

    // Cover functionality of addressing, that the only functional addresses are 'h00 and 'h04
    // Only bottom 8 bits are used in rtl
    covergroup addressing
        coverpoint HADDR{
            bins dir_addr = {'h04[*2:4]};
            bins data_addr = {'h00[*2:4]};
            bins trans = {'h04 => 'h00 => 'h04 => 'h00};
            bins others[10] = default;
        }
    endgroup


    task sample_coverage();

        parity_injection parity_inj = new();
        parity_gen_and_check parity_gc = new();
        input_stage inp_stage = new();
        output_stage outp_stage = new();
        addressing addr = new();

        always @(posedge HCLK) begin
            parity_inj.sample();
            if(HRESETn) begin
                if(GPIOOUT!=last_GPIOOUT || HWDATA!=last_HWDATA) begin
                    outp_stage.sample();
                end
                if(GPIOIN!=last_GPIOIN || HRDATA!=last_HRDATA) begin
                    inp_stage.sample();
                end
                if(HADDR!=last_HADDR) begin
                    outp_stage.sample();
                end
                
                if(GPIOOUT!=last_GPIOOUT || GPIOIN!=last_GPIOIN || HRDATA!=last_HRDATA) begin
                    parity_gc.sample();
                end

            end else begin

            end

            
            last_GPIOOUT   <= GPIOOUT;
            last_HWDATA    <= HWDATA;
            last_GPIOIN    <= GPIOIN;
            last_HRDATA    <= HRDATA;
            last_HADDR     <= HADDR;
            last_PARITYSEL <= PARITYSEL;
        end

    endtask

endinterface