class mon_trans;
    localparam WIDTH = 16;
    logic io, PARITYSEL; // io: 0 is for input cycle, 1 is for output cycle
    logic PARITYERR;
    logic [2*WIDTH-1:0] HWDATA, HRDATA; 
    logic [WIDTH:0] GPIOIN, GPIOOUT;
    logic unexpected; // used for when there was an unexpected change in output
endclass


class monitor;

    virtual gpio_intf.MON gpio_vif;
    mailbox gpio_mon_mail;

    //Variables to know when to sample
    localparam WIDTH = 16;
    logic last_HWRITE, last_HSEL, last_PARITYSEL, last_PARITYERR;
    logic [2*WIDTH-1:0] last_HADDR, last_HWDATA, last_HRDATA;
    logic [WIDTH-1:0] last_gpio_dir, cur_gpio_dir;
    logic [WIDTH:0] last_GPIOIN, last_GPIOOUT;
    logic [1:0] last_HTRANS;

    logic state_sample, io;// io: 0 is for input cycle, 1 is for output cycle

    function new(virtual gpio_intf.MON gpio_vif, mailbox gpio_mon_mail);
        this.gpio_vif = gpio_vif;
        this.gpio_mon_mail = gpio_mon_mail;
        state_sample = 1'b0;
    endfunction

    task run();
        $display("------[MONITOR STARTED]------");
        forever begin @(posedge gpio_vif.HCLK or negedge gpio_vif.HRESETn) begin
            if(!gpio_vif.HRESETn) begin
                last_HWRITE    <= 'b0;
                last_HTRANS    <= 'b0;
                last_HSEL      <= 'b0;
                last_HWDATA    <= 'b0;
                last_HADDR     <= 'b0;
                last_GPIOIN    <= 'b0;
                last_GPIOOUT   <= 'b0;
                last_HRDATA    <= 'b0;
                last_PARITYERR <= 'b0;
                last_gpio_dir  <= 'b0;

                state_sample<= 'b0; // when 0, checks whether it will need to sample on next clock cycle
                io          <= 'b0; // used to track whether to sample input or output
            end else begin
                if(gpio_vif.cb_MON.HREADY==1'b1) begin
                    last_HWRITE <= gpio_vif.cb_MON.HWRITE;
                    last_HTRANS <= gpio_vif.cb_MON.HTRANS;
                    last_HSEL   <= gpio_vif.cb_MON.HSEL;
                    last_HADDR  <= gpio_vif.cb_MON.HADDR;
                end

                //Update direction so monitor knows when to sample
                if((last_HADDR[7:0] == 8'h04) & last_HSEL & last_HWRITE & last_HTRANS[1]) cur_gpio_dir <= gpio_vif.cb_MON.HWDATA[15:0];

                case(state_sample)
                    0:  if(cur_gpio_dir=='b0) begin 
                            io <= 1'b0;
                            state_sample <= 1'b1;
                        end
                        else if((cur_gpio_dir=='b1) & (last_HADDR[7:0] == 'b0) & last_HSEL & last_HWRITE & last_HTRANS[1]) begin 
                            io <= 1'b1;
                            state_sample <= 1'b1;
                        end else if(last_GPIOOUT!=gpio_vif.cb_MON.GPIOOUT || last_PARITYERR!=gpio_vif.cb_MON.PARITYERR) begin
                            sample(1);
                            $display("[Monitor] Unexpected change in GPIOOUT or parityerr");
                        end else if(last_HRDATA!=gpio_vif.cb_MON.HRDATA && last_gpio_dir==cur_gpio_dir && gpio_vif.cb_MON.HRDATA[15:0]!=last_GPIOOUT[15:0]) begin
                            sample(1);
                            $display("[Monitor] Unexpected change in HRDATA");
                        end
                    1: begin 
                        sample(0);
                        if(cur_gpio_dir=='b0) begin 
                            io <= 1'b0;
                        end else if((cur_gpio_dir=='b1) & (last_HADDR[7:0] == 'b0) & last_HSEL & last_HWRITE & last_HTRANS[1]) begin 
                            io <= 1'b1;
                        end else state_sample <= 1'b0;
                       end
                endcase
            end

            
            last_HWDATA <= gpio_vif.cb_MON.HWDATA;
            last_GPIOIN <= gpio_vif.cb_MON.GPIOIN;
            last_HRDATA <= gpio_vif.cb_MON.HRDATA;
            last_GPIOOUT <= gpio_vif.cb_MON.GPIOOUT;
            last_PARITYSEL <= gpio_vif.cb_MON.PARITYSEL;
            last_PARITYERR <= gpio_vif.cb_MON.PARITYERR;
            last_gpio_dir <= cur_gpio_dir;

        end end 
    endtask

    task sample(logic unexpected);
        mon_trans trans = new;
        trans.io = io;
        trans.unexpected = unexpected;
        if(io) begin
            trans.HWDATA = last_HWDATA;
            trans.GPIOOUT = gpio_vif.cb_MON.GPIOOUT;
        end else begin 
            trans.HRDATA = gpio_vif.cb_MON.HRDATA;
            trans.GPIOIN = last_GPIOIN;
            trans.PARITYERR = gpio_vif.cb_MON.PARITYERR;
            trans.PARITYSEL = last_PARITYSEL;
        end
        gpio_mon_mail.put(trans);
    endtask
    
endclass