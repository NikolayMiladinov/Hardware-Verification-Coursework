class mon_trans;
    localparam WIDTH = 16;
    logic [2*WIDTH-1:0] HWDATA, HRDATA;
endclass


class monitor;

    virtual vga_intf.MON vga_vif;
    mailbox vga_mon_mail;

    //Variables to know when to sample
    localparam WIDTH = 16;

    function new(virtual vga_intf.MON vga_vif, mailbox vga_mon_mail);
        this.vga_vif = vga_vif;
        this.vga_mon_mail = vga_mon_mail;
    endfunction

    task run();
        $display("------[MONITOR STARTED]------");
        forever begin @(posedge vga_vif.HCLK or negedge vga_vif.HRESETn) begin
            if(vga_vif.cb_MON.RGB!=0) $display("RGB = %0h, time = %0t", vga_vif.cb_MON.RGB, $time);

        end end 
    endtask
    

endclass