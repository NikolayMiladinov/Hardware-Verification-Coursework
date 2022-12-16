class scoreboard;

    mailbox vga_mon_mail;
    logic DLS_ERROR = 1'b0;
    int error = 0;

    function new(mailbox vga_mon_mail);
        this.vga_mon_mail = vga_mon_mail;
    endfunction

    task comparator();
        mon_trans trans;
        vga_mon_mail.get(trans);
        if(trans.HRDATA!=trans.HRDATA_redundant) DLS_ERROR = 1'b1;
        else if(trans.RGB!=trans.RGB_redundant) DLS_ERROR = 1'b1;
        else if(trans.HSYNC!=trans.HSYNC_redundant) DLS_ERROR = 1'b1;
        else if(trans.VSYNC!=trans.VSYNC_redundant) DLS_ERROR = 1'b1;
        else if(trans.HREADYOUT!=trans.HREADYOUT_redundant) DLS_ERROR = 1'b1;
        else DLS_ERROR = 1'b0;
    endtask

    task run();
        $display("------[SCOREBOARD STARTED]------");
        forever begin
            comparator();
            if(DLS_ERROR) error++;
        end
    endtask

    task print_error();
        $display("[SCOREBOARD] Error count: %0d", error);
    endtask

endclass