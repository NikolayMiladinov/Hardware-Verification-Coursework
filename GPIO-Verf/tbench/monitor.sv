class mon_trans;
    localparam WIDTH = 16;
    logic io, PARITYSEL; // io: 0 is for input cycle, 1 is for output cycle
    logic [2*WIDTH-1:0] HWDATA, HRDATA; 
    logic [WIDTH:0] GPIOIN, GPIOOUT;
endclass


class monitor;

    virtual gpio_intf.MON gpio_vif;

    //Variables to know when to sample
    logic last_HWRITE, last_HSEL, last_PARITYSEL;
    logic [2*WIDTH-1:0] last_HADDR, last_HWDATA;
    logic [15:0] cur_gpio_dir;
    logic [WIDTH:0] last_GPIOIN;
    logic [1:0] last_HTRANS;

    function new(virtual gpio_intf.MON gpio_vif, mailbox gpio_mon_mail);
        this.gpio_vif = gpio_vif;
        this.gpio_mon_mail = gpio_mon_mail;
    endfunction

    task run();
        $display("------[MONITOR STARTED]------");
        always @(posedge gpio_vif.HCLK or negedge gpio_vif.HRESETn) begin
            if(!gpio_vif.HRESETn) begin
                last_HWRITE <= 'b0;
                last_HTRANS <= 'b0;
                last_HSEL   <= 'b0;
                last_HWDATA <= 'b0;
                last_HADDR  <= 'b0;
                last_GPIOIN <= 'b0;
            end else begin
                if(gpio_vif.HREADY==1'b1) begin
                    last_HWRITE <= gpio_vif.HWRITE;
                    last_HTRANS <= gpio_vif.HTRANS;
                    last_HSEL   <= gpio_vif.HSEL;
                    last_HWDATA <= gpio_vif.HWDATA;
                    last_HADDR  <= gpio_vif.HADDR;
                    last_GPIOIN <= gpio_vif.GPIOIN;
                    last_PARITYSEL <= gpio_vif.PARITYSEL;
                end

                //Update direction so monitor knows when to sample
                if((last_HADDR[7:0] == 8'h04) & last_HSEL & last_HWRITE & last_HTRANS[1]) cur_gpio_dir <= gpio_vif.HWDATA[15:0];

                if(cur_gpio_dir=='b0) sample(0);
                else if((cur_gpio_dir=='b1) & (last_HADDR[7:0] == 'b0) & last_HSEL & last_HWRITE & last_HTRANS[1]) sample(1);
            end
        end 
    endtask

    task sample(bit io);
        mon_trans trans = new;
        trans.io = io;
        if(io) begin
            trans.HWDATA = last_HWDATA;
            trans.GPIOOUT = gpio_vif.GPIOOUT;
            trans.PARITYSEL = last_PARITYSEL;
        end else begin 
            trans.HRDATA = gpio_vif.HRDATA;
            trans.GPIOIN = last_GPIOIN;
        end
        gpio_mon_mail.put(trans);
    endtask
    
endclass