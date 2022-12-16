class driver;

    virtual vga_intf.DRIV vga_vif;
    mailbox vga_mail;

    //used to count the number of transactions
    int no_transactions = 1;
    logic driver_rstn = 1'b1;
    event ended_1mil;

    function new(virtual vga_intf.DRIV vga_vif, mailbox vga_mail, event ended_1mil);
        this.vga_vif = vga_vif;
        this.vga_mail = vga_mail;
        this.ended_1mil = ended_1mil;
    endfunction

    //Reset task, reset the Interface signals and assert reset for vga
    //n indicated the number of cycles reset is held before deassering it, default value is 2
    task reset(int n=2);

        vga_vif.HRESETn = 0; //assert reset
        driver_rstn = 1'b0;

        $display("--------- [DRIVER] Reset Started --------- at %0t", $time);
        vga_vif.cb_DRIV.HTRANS  <= 'b0;
        vga_vif.cb_DRIV.HWRITE  <= 'b0;
        vga_vif.cb_DRIV.HSEL    <= 'b0;
        vga_vif.cb_DRIV.HREADY  <= 'b0;
        vga_vif.cb_DRIV.HADDR   <= 'b0; 
        vga_vif.cb_DRIV.HWDATA  <= 'b0;
        @vga_vif.cb_DRIV;
        driver_rstn = 1'b1;
        
        $display("--------- [DRIVER] Reset driver end --------- at %0t", $time);
        //hold reset for n cycles
        repeat (n-1) @vga_vif.cb_DRIV;
        #1
        vga_vif.HRESETn = 'b1; //deassert reset
        $display("--------- [DRIVER] Reset Ended --------- at %0t", $time);
    endtask

    task random_reset();
        int rand_delay;
        int reset_cycles;
        forever begin
            assert (std::randomize(rand_delay, reset_cycles) with {
                rand_delay < 500;
                rand_delay > 20;
                rand_delay dist {[0:100]:/45, [101:200]:/30, [201:300]:/20, [301:500]:/10};
                reset_cycles < 16;
                reset_cycles > 1;
                reset_cycles dist {[1:5]:/45, [6:8]:/30, [9:12]:/20, [13:15]:/10};
            }) else $fatal("Driver:: reset randomization failed");
            
            $display("[Reset in %0d ns", rand_delay);
            $display("[Reset for %0d cycles", reset_cycles);
            # (rand_delay*1ns);
            reset(reset_cycles);
        end
    endtask

    task drive(bit rand_rst);
        fork
            vga_drive();
            if(rand_rst==1) random_reset();
        join_none

    endtask

    //drive the transaction items to interface signals
    task vga_drive();
        reset();
        
        vga_vif.cb_DRIV.HREADY <= 'b1;
        @vga_vif.cb_DRIV;
        vga_vif.cb_DRIV.HTRANS <= 'd2;
        vga_vif.cb_DRIV.HWRITE <= 'b1;
        vga_vif.cb_DRIV.HSEL <= 'b1;
        vga_vif.cb_DRIV.HADDR <= 32'h5200_0000; 
        @vga_vif.cb_DRIV;
        forever begin
            transaction trans;
            
            vga_mail.get(trans);
            $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
            if(trans.inject_wrong_address) begin
                vga_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
                @vga_vif.cb_DRIV;
            end else if(vga_vif.cb_DRIV.HADDR != 32'h5200_0000) begin
                vga_vif.cb_DRIV.HADDR <= 32'h5200_0000; 
                @vga_vif.cb_DRIV;
            end
            if(no_transactions<899) begin
                vga_vif.cb_DRIV.HWDATA <= {trans.HWDATA_upper_bits, trans.HWDATA};
                @vga_vif.cb_DRIV;
            end 

            $display("----------[DRIVER-END-OF-TRANSFER]----------");
            no_transactions++;
        end
    endtask

    task stop_drive();
        vga_vif.cb_DRIV.HWDATA <= 'h00;
        vga_vif.cb_DRIV.HSEL <= 'b0;
        vga_vif.cb_DRIV.HWRITE <= 'b0;
        vga_vif.cb_DRIV.HTRANS[1] <= 'b0;
        vga_vif.cb_DRIV.HREADY <= 'b0;
    endtask


    task initial_check();// Initial check of vga
	begin
        $display("----------[DRIVER-INITIAL-CHECK-START]----------");
        //-------Check Write command--------
        reset();
        
        vga_vif.cb_DRIV.HREADY <= 'b1;
        @vga_vif.cb_DRIV;
        vga_vif.cb_DRIV.HTRANS <= 'd2;
        vga_vif.cb_DRIV.HWRITE <= 'b1;
        vga_vif.cb_DRIV.HSEL <= 'b1;
        vga_vif.cb_DRIV.HADDR <= 32'h5200_0000; 
        @vga_vif.cb_DRIV;

        //Write value
        vga_vif.cb_DRIV.HWDATA <= 'h0e;

        repeat(10) @vga_vif.cb_DRIV;

        vga_vif.cb_DRIV.HWDATA <= 'h00;
        vga_vif.cb_DRIV.HSEL <= 'b0;

        repeat(1750000) @vga_vif.cb_DRIV;

        -> ended_1mil;
        
	end
	endtask

endclass