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
        forever begin
            transaction trans;
            
            vga_mail.get(trans);
            $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);

            // if(driver_rstn) begin
            //     if(trans.inject_parity_error && !trans.write_cycle) $display("[Driver] Parity error injection in transaction %0d, vgaIN: %0h", no_transactions, trans.vgaIN);
            //     // first if HREADY needs to change because it needs an additional clock cycle
            //     if(vga_vif.cb_DRIV.HREADY!=trans.command_signals[0]) begin
            //         vga_vif.cb_DRIV.HREADY <= trans.command_signals[0];
            //         @vga_vif.cb_DRIV;
            //     end
            // end else begin
            //     $display("[DRIVER] Driver is being reset");
            // end

            // if(driver_rstn) begin
            //     //start address phase
            //     vga_vif.cb_DRIV.HSEL <= trans.command_signals[1];
            //     vga_vif.cb_DRIV.HTRANS <= {trans.command_signals[2],1'b0};
            //     vga_vif.cb_DRIV.HWRITE <= 'b1;

            //     if(trans.inject_wrong_address[0]) begin
            //         vga_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
            //         $display("[Driver] Wrong HADDR injection in address phase: transaction %0d", no_transactions);
            //     end else vga_vif.cb_DRIV.HADDR <= 32'h5300_0004; 
            // end else begin
            //     $display("[DRIVER] Driver is being reset");
            // end
            
            // @vga_vif.cb_DRIV; 

            // if(driver_rstn) begin
            //     //write to direction register, direction determined by write_cycle variable
            //     if(trans.dir_inject) begin
            //         vga_vif.cb_DRIV.HWDATA <= trans.HWDATA_dir_inject;
            //         $display("[Driver] Wrong direction injection in transaction %0d", no_transactions);
            //     end else vga_vif.cb_DRIV.HWDATA <= {31'b0, trans.write_cycle};

            //     if(trans.inject_wrong_address[1]) begin 
            //         vga_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
            //         $display("[Driver] Wrong HADDR injection in data phase: transaction %0d", no_transactions);
            //     end else vga_vif.cb_DRIV.HADDR <= 32'h5300_0000; //start data phase

            //     if(trans.write_cycle == 1'b0) vga_vif.cb_DRIV.HWRITE <= 'b0; //write signal can be low during data phase of input direction
            // end else begin
            //     $display("[DRIVER] Driver is being reset");
            // end

            // @vga_vif.cb_DRIV;
            

            // if(driver_rstn) begin
            //     //transfer data
            //     if(trans.write_cycle == 1'b1) vga_vif.cb_DRIV.HWDATA <= {trans.HWDATA_data_upper_bits,trans.HWDATA_data};
            //     else begin 
            //         vga_vif.cb_DRIV.PARITYSEL <= trans.PARITYSEL;
            //         vga_vif.cb_DRIV.vgaIN <= trans.vgaIN;
            //     end
            // end else begin
            //     $display("[DRIVER] Driver is being reset");
            // end

            $display("----------[DRIVER-END-OF-TRANSFER]----------");
            no_transactions++;
        end
    endtask


    task initial_check();// Initial check of vga
	begin
        $display("----------[DRIVER-INITIAL-CHECK-START]----------");
        //-------Check Write command--------
        
        //Setup variables for address phase
        vga_vif.cb_DRIV.HREADY <= 'b1;
        @vga_vif.cb_DRIV;
        vga_vif.cb_DRIV.HTRANS <= 'd2;
        vga_vif.cb_DRIV.HWRITE <= 'b1;
        vga_vif.cb_DRIV.HSEL <= 'b1;
        vga_vif.cb_DRIV.HADDR <= 32'h5200_0000; 
        @vga_vif.cb_DRIV;

        //Write value
        vga_vif.cb_DRIV.HWDATA <= 'h0e;

        repeat(1000000) @vga_vif.cb_DRIV;

        -> ended_1mil;
        
	end
	endtask

endclass