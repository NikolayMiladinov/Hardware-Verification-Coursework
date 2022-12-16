class mon_trans;
    localparam WIDTH = 16;
    logic [2*WIDTH-1:0] HRDATA, HRDATA_redundant;
    logic               HREADYOUT, HREADYOUT_redundant, HSYNC, HSYNC_redundant, VSYNC, VSYNC_redundant;
    logic [WIDTH/2-1:0] RGB, RGB_redundant;
endclass


class monitor;

    virtual vga_intf.MON vga_vif;
    mailbox vga_mon_mail;

    int fd;
    // fd = $fopen("./out.txt","w");
    // if(fd) $display("File opened successfully");
    // else $display("File could not be found or opened");

    //Variables to know when to sample
    localparam WIDTH = 16;
    logic last_HSYNC, last_VSYNC;
    logic clock_div = 1;

    int row = 0;
    int column = 0;
    string col_string;
    int pixel_x = 0;
    int pixel_y = 0;
    int page = 0;
    logic sync_column = 1'b0;
    logic start_col = 1'b0;

    function new(virtual vga_intf.MON vga_vif, mailbox vga_mon_mail);
        this.vga_vif = vga_vif;
        this.vga_mon_mail = vga_mon_mail;
    endfunction

    task print_out();
        if(!vga_vif.cb_MON.HSYNC && last_HSYNC) $fwrite(fd, "\n");
        if(!vga_vif.cb_MON.VSYNC && last_VSYNC) begin
            $display("VSYNC t = %0t", $time);
        end

        //Only print the first page
        if(clock_div && page==0) begin
            if(vga_vif.cb_MON.RGB == 'h1C) $fwrite(fd, "*");
            else if(vga_vif.cb_MON.RGB == 0) $fwrite(fd, " ");
            else if(vga_vif.cb_MON.RGB === 8'hx || vga_vif.cb_MON.RGB === 8'hz) $fwrite(fd, "!");
            else $fwrite(fd, "X");
        end
        
    endtask

    task track_position();
        if(clock_div & start_col) begin
            if(row==3 && pixel_x==25) begin
                // $display("[Monitor] Pixel_x is %0d at time %0t", pixel_x, $time);
                // $display("[Monitor] Column is %0d at time %0t", column, $time);
            end
            column++;
            if(column==783) pixel_x = 0;
            else if(column>143 && column<783) pixel_x++;
            
        end

        if(!vga_vif.cb_MON.HSYNC && last_HSYNC) begin
            // $display("[Monitor] [Monitor] [Monitor] Row is %0d at time %0t", row, $time);
            // $display("[Monitor] [Monitor] [Monitor] Pixel_y is %0d at time %0t", pixel_y, $time);
            start_col = 1'b1;
            column = 0;
            row++;
            if(row==511) pixel_y = 0;
            else if(row>31 && row<511) pixel_y++;
        end

        if(!vga_vif.cb_MON.VSYNC && last_VSYNC) begin
            row = 0;
            page++;
            $display("Reset row t = %0t", $time);
        end

    endtask

    task sample();
        mon_trans trans = new;
        trans.HREADYOUT = vga_vif.cb_MON.HREADYOUT;
        trans.HREADYOUT_redundant = vga_vif.cb_MON.HREADYOUT_redundant;
        
        trans.HSYNC = vga_vif.cb_MON.HSYNC;
        trans.HSYNC_redundant = vga_vif.cb_MON.HSYNC_redundant;
        trans.VSYNC = vga_vif.cb_MON.VSYNC;
        trans.VSYNC_redundant = vga_vif.cb_MON.VSYNC_redundant;
        
        trans.RGB = vga_vif.cb_MON.RGB;
        trans.RGB_redundant = vga_vif.cb_MON.RGB_redundant;
        
        trans.HRDATA = vga_vif.cb_MON.HRDATA;
        trans.HRDATA_redundant = vga_vif.cb_MON.HRDATA_redundant;

        vga_mon_mail.put(trans);
    endtask

    task run();
        $display("------[MONITOR STARTED]------");
        forever begin @(posedge vga_vif.HCLK) begin
            mon_trans trans = new();
            track_position();
            print_out();
            sample();
            clock_div = ~clock_div;
            last_HSYNC = vga_vif.cb_MON.HSYNC;
            last_VSYNC = vga_vif.cb_MON.VSYNC;
        end end 
    endtask
    

endclass