class mon_trans;
    localparam WIDTH = 16;
    logic [2*WIDTH-1:0] HWDATA, HRDATA;
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

    function new(virtual vga_intf.MON vga_vif, mailbox vga_mon_mail);
        this.vga_vif = vga_vif;
        this.vga_mon_mail = vga_mon_mail;
    endfunction

    task print_out();
        if(!vga_vif.cb_MON.HSYNC && last_HSYNC) $fwrite(fd, "\n");
        if(!vga_vif.cb_MON.VSYNC && last_VSYNC) begin
            $display("VSYNC t = %0t", $time);
        end

        if(vga_vif.cb_MON.RGB == 'h1C) $fwrite(fd, "*");
        else if(vga_vif.cb_MON.RGB == 0) $fwrite(fd, " ");
        else $fwrite(fd, "!");
        
        last_HSYNC = vga_vif.cb_MON.HSYNC;
        last_VSYNC = vga_vif.cb_MON.VSYNC;
    endtask

    task run();
        $display("------[MONITOR STARTED]------");
        forever begin @(posedge vga_vif.HCLK or negedge vga_vif.HRESETn) begin
            mon_trans trans = new();

            print_out();

        end end 
    endtask
    

endclass