class driver;

    virtual gpio_intf.DRIV gpio_vif;
    mailbox gpio_mail;

    //used to count the number of transactions
    int no_transactions = 1;

    function new(virtual gpio_intf.DRIV gpio_vif, mailbox gpio_mail);
        this.gpio_vif = gpio_vif;
        this.gpio_mail = gpio_mail;
    endfunction

    //Reset task, reset the Interface signals and assert reset for GPIO
    //n indicated the number of cycles reset is held before deassering it, default value is 2
    task reset(int n=2);

        gpio_vif.HRESETn = 0; //assert reset

        $display("--------- [DRIVER] Reset Started ---------");
        gpio_vif.cb_DRIV.HTRANS <= 'b0;
        gpio_vif.cb_DRIV.HWRITE <= 'b0;
        gpio_vif.cb_DRIV.HSEL <= 'b1;
        gpio_vif.cb_DRIV.HREADY <= 'b1;
        gpio_vif.cb_DRIV.HADDR <= 'b0; 
        gpio_vif.cb_DRIV.HWDATA <= 'b0;
        gpio_vif.cb_DRIV.GPIOIN <= 'b0;
        gpio_vif.cb_DRIV.PARITYSEL <= 'b0;

        //hold reset for n cycles
        repeat (n) @gpio_vif.cb_DRIV;

        gpio_vif.HRESETn = 1; //deassert reset
        $display("--------- [DRIVER] Reset Ended ---------");
    endtask

    task drive(int dr);

        if(dr==1) drive2cycles();
        if(dr==2) drive_every_cycle();
        if(dr==3) drive_with_delay();
        if(dr==4) drive_both_inout();
        // if(dr==5) drive_with_reset();

    endtask

    //drive the transaction items to interface signals
    task drive2cycles();
        forever begin
            transaction trans;
            
            gpio_mail.get(trans);
            $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
            if(trans.inject_parity_error && !trans.write_cycle) $display("[Driver] Parity error injection in transaction %0d, GPIOIN: %0h", no_transactions, trans.GPIOIN);
            // first if HREADY needs to change because it needs an additional clock cycle
            if(gpio_vif.cb_DRIV.HREADY!=trans.command_signals[0]) begin
                gpio_vif.cb_DRIV.HREADY <= trans.command_signals[0];
                @gpio_vif.cb_DRIV;
            end

            //start address phase
            gpio_vif.cb_DRIV.HSEL <= trans.command_signals[1];
            gpio_vif.cb_DRIV.HTRANS <= {trans.command_signals[2],1'b0};
            gpio_vif.cb_DRIV.HWRITE <= 'b1;

            if(trans.inject_wrong_address[0]) begin
                gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
                $display("[Driver] Wrong HADDR injection in address phase: transaction %0d", no_transactions);
            end else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004; 
            @gpio_vif.cb_DRIV; 

            //write to direction register, direction determined by write_cycle variable
            if(trans.dir_inject) begin
                gpio_vif.cb_DRIV.HWDATA <= trans.HWDATA_dir_inject;
                $display("[Driver] Wrong direction injection in transaction %0d", no_transactions);
            end else gpio_vif.cb_DRIV.HWDATA <= {31'b0, trans.write_cycle};

            if(trans.inject_wrong_address[1]) begin 
                gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
                $display("[Driver] Wrong HADDR injection in data phase: transaction %0d", no_transactions);
            end else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0000; //start data phase

            if(trans.write_cycle == 1'b0) gpio_vif.cb_DRIV.HWRITE <= 'b0; //write signal can be low during data phase of input direction
            @gpio_vif.cb_DRIV;
            
            //transfer data
            if(trans.write_cycle == 1'b1) gpio_vif.cb_DRIV.HWDATA <= {16'b0,trans.HWDATA_data};
            else begin 
                gpio_vif.cb_DRIV.PARITYSEL <= trans.PARITYSEL;
                gpio_vif.cb_DRIV.GPIOIN <= trans.GPIOIN;
            end

            $display("----------[DRIVER-END-OF-TRANSFER]----------");
            no_transactions++;
        end
    endtask

    task drive_with_delay();
        forever begin
            transaction trans;
            
            gpio_mail.get(trans);
            $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);

            if(trans.inject_parity_error && !trans.write_cycle) $display("[Driver] Parity error injection in transaction %0d, GPIOIN: %0h", no_transactions, trans.GPIOIN);
            // first if HREADY needs to change because it needs an additional clock cycle
            if(gpio_vif.cb_DRIV.HREADY!=trans.command_signals[0]) begin
                gpio_vif.cb_DRIV.HREADY <= trans.command_signals[0];
                @gpio_vif.cb_DRIV;
            end

            //start address phase
            gpio_vif.cb_DRIV.HSEL <= trans.command_signals[1];
            gpio_vif.cb_DRIV.HTRANS <= {trans.command_signals[2],1'b0};
            gpio_vif.cb_DRIV.HWRITE <= 'b1;

            if(trans.inject_wrong_address[0]) begin
                gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
                $display("[Driver] Wrong HADDR injection in address phase: transaction %0d", no_transactions);
            end else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004; 
            @gpio_vif.cb_DRIV; 

            //write to direction register, direction determined by write_cycle variable
            if(trans.dir_inject) begin
                gpio_vif.cb_DRIV.HWDATA <= trans.HWDATA_dir_inject;
                $display("[Driver] Wrong direction injection in transaction %0d", no_transactions);
            end else gpio_vif.cb_DRIV.HWDATA <= {31'b0, trans.write_cycle};

            if(trans.inject_wrong_address[1]) begin 
                gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
                $display("[Driver] Wrong HADDR injection in data phase: transaction %0d", no_transactions);
            end else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0000; //start data phase

            if(trans.write_cycle == 1'b0) gpio_vif.cb_DRIV.HWRITE <= 'b0; //write signal can be low during data phase of input direction
            @gpio_vif.cb_DRIV;
            
            //transfer data
            if(trans.write_cycle == 1'b1) gpio_vif.cb_DRIV.HWDATA <= {16'b0,trans.HWDATA_data};
            else begin 
                gpio_vif.cb_DRIV.PARITYSEL <= trans.PARITYSEL;
                gpio_vif.cb_DRIV.GPIOIN <= trans.GPIOIN;
            end

            repeat (trans.delay_bn_cycles) @gpio_vif.cb_DRIV;

            $display("----------[DRIVER-END-OF-TRANSFER]----------");
            no_transactions++;
        end
    endtask

    task drive_both_inout();
        forever begin
            transaction trans;
            
            gpio_mail.get(trans);
            $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);

            // first if HREADY needs to change because it needs an additional clock cycle
            if(gpio_vif.cb_DRIV.HREADY!=trans.command_signals[0]) begin
                gpio_vif.cb_DRIV.HREADY <= trans.command_signals[0];
                @gpio_vif.cb_DRIV;
            end

            //start address phase
            gpio_vif.cb_DRIV.HSEL <= trans.command_signals[1];
            gpio_vif.cb_DRIV.HTRANS <= {trans.command_signals[2],1'b0};
            gpio_vif.cb_DRIV.HWRITE <= 'b1;

            if(trans.inject_wrong_address[0]) gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
            else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004; 
            @gpio_vif.cb_DRIV; 

            //write to direction register, direction determined by write_cycle variable
            if(trans.dir_inject) gpio_vif.cb_DRIV.HWDATA <= trans.HWDATA_dir_inject;
            else gpio_vif.cb_DRIV.HWDATA <= {31'b0, trans.write_cycle};

            if(trans.inject_wrong_address[1]) gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
            else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0000; //start data phase

            gpio_vif.cb_DRIV.PARITYSEL <= trans.PARITYSEL;
            if(trans.write_cycle == 1'b0) gpio_vif.cb_DRIV.HWRITE <= 'b0; //write signal can be low during data phase of input direction
            @gpio_vif.cb_DRIV;
            
            //transfer data
            // Drive both, only one should be registered since direction is set and hwrite is low during GPIOIN input
            gpio_vif.cb_DRIV.HWDATA <= {16'b0,trans.HWDATA_data};
            gpio_vif.cb_DRIV.GPIOIN <= trans.GPIOIN;

            $display("----------[DRIVER-END-OF-TRANSFER]----------");
            no_transactions++;
        end
    endtask

    task drive_every_cycle();
        forever begin
            transaction trans;
            transaction trans_next;
            
            gpio_mail.get(trans);
            gpio_mail.peek(trans_next);
            $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);

            // initial setup
            if(no_transactions==0) begin
                gpio_vif.cb_DRIV.HREADY <= 1'b1;
                @gpio_vif.cb_DRIV;
                gpio_vif.cb_DRIV.HSEL <= 1'b1;
                gpio_vif.cb_DRIV.HTRANS <= 2'b10;
                gpio_vif.cb_DRIV.HWRITE <= 'b1;
                if(trans.inject_wrong_address[0]) gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
                else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004; 
                @gpio_vif.cb_DRIV;

                //write to direction register, direction determined by write_cycle variable
                if(trans.dir_inject) gpio_vif.cb_DRIV.HWDATA <= trans.HWDATA_dir_inject;
                else gpio_vif.cb_DRIV.HWDATA <= {31'b0, trans.write_cycle};

                if(trans.inject_wrong_address[1]) gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
                else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0000; //start data phase
    
                //if(trans.write_cycle == 1'b0) gpio_vif.cb_DRIV.HWRITE <= 'b0; //write signal can be low during data phase of input direction
                @gpio_vif.cb_DRIV;
            end
            
            //transfer data
            gpio_vif.cb_DRIV.PARITYSEL <= trans.PARITYSEL;
            if(trans.write_cycle == 1'b1) gpio_vif.cb_DRIV.HWDATA <= {16'b0,trans.HWDATA_data};
            else gpio_vif.cb_DRIV.GPIOIN <= trans.GPIOIN;

            if(trans_next.write_cycle!=trans.write_cycle) begin
                if(!trans.write_cycle) begin

                    //write to direction register, direction determined by write_cycle variable
                    if(trans.dir_inject) gpio_vif.cb_DRIV.HWDATA <= trans.HWDATA_dir_inject;
                    else gpio_vif.cb_DRIV.HWDATA <= {31'b0, trans_next.write_cycle};

                    if(trans.inject_wrong_address[1]) gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
                    else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0000; //start data phase

                end else begin 

                    if(trans.inject_wrong_address[0]) gpio_vif.cb_DRIV.HADDR <= trans.HADDR_inject;
                    else gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004; 
                    @gpio_vif.cb_DRIV;

                    //write to direction register, direction determined by write_cycle variable
                    if(trans.dir_inject) gpio_vif.cb_DRIV.HWDATA <= trans.HWDATA_dir_inject;
                    else gpio_vif.cb_DRIV.HWDATA <= {31'b0, trans.write_cycle};
                    gpio_vif.cb_DRIV.HWRITE <= 'b0; //since address will remain 04 during input, HWRITE should be low to not accidentaly drive the dir_reg

                end
            end

            @gpio_vif.cb_DRIV;

            $display("----------[DRIVER-END-OF-TRANSFER]----------");
            no_transactions++;
        end
    endtask

    task initial_check();// Initial check of gpio
	begin
        $display("----------[DRIVER-INITIAL-CHECK-START]----------");
        //-------Check Write command--------
        
        //Setup variables for address phase
        gpio_vif.cb_DRIV.HREADY <= 'b1;
        @gpio_vif.cb_DRIV;
        gpio_vif.cb_DRIV.HTRANS <= 'd2;
        gpio_vif.cb_DRIV.HWRITE <= 'b1;
        gpio_vif.cb_DRIV.HSEL <= 'b1;
        gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004; 
        @gpio_vif.cb_DRIV;

        //Write 1 to direction register for output direction and indicate data phase will follow
        gpio_vif.cb_DRIV.HWDATA <= 'b1;
        gpio_vif.cb_DRIV.HADDR <= 32'h53000000;
        @gpio_vif.cb_DRIV;

        //Write value to output register, should appear on GPIOOUT next cycle
        gpio_vif.cb_DRIV.PARITYSEL <= 1'b0; //generate even parity
        gpio_vif.cb_DRIV.HWDATA <= 'hBEEF;

        @gpio_vif.cb_DRIV;
        @gpio_vif.cb_DRIV;
        assert (gpio_vif.cb_DRIV.GPIOOUT == {gpio_vif.cb_DRIV.PARITYSEL ? ~^16'h0FAB : ^16'h0FAB, 16'hBEEF})
	    else $fatal ("Initial check of gpio write failed. GPIOOUT = %0h, expected result is 17'h1BEEF", gpio_vif.cb_DRIV.GPIOOUT);
        
        @gpio_vif.cb_DRIV;
        assert (gpio_vif.cb_DRIV.HRDATA == {16'b0, 16'hBEEF})
	    else $fatal ("Initial check of gpio write failed. GPIOOUT = %0h, HRDATA = %0h, expected result is 32'hBEEF", gpio_vif.cb_DRIV.GPIOOUT, gpio_vif.cb_DRIV.HRDATA);
        $display ("Initial check of GPIO write successful. GPIOOUT = %0h, HRDATA = %0h, expected result is 'hBEEF", gpio_vif.cb_DRIV.GPIOOUT, gpio_vif.cb_DRIV.HRDATA);

        //Setup variables for address phase
        gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004;

        @gpio_vif.cb_DRIV;

        //Write 0 to direction register for input direction and indicate data phase will follow
        gpio_vif.cb_DRIV.HWDATA <= 'b0;
        gpio_vif.cb_DRIV.HADDR <= 32'h53000000;
        @gpio_vif.cb_DRIV;

        gpio_vif.cb_DRIV.GPIOIN <= {gpio_vif.cb_DRIV.PARITYSEL ? ~^16'h0FAB : ^16'h0FAB, 16'h0FAB};

        @gpio_vif.cb_DRIV;
        @gpio_vif.cb_DRIV;
        assert (gpio_vif.cb_DRIV.HRDATA == {16'b0, 16'h0FAB})
	    else $fatal ("Initial check of gpio read failed. HRDATA = %0h, expected result is 32'hFAB", gpio_vif.cb_DRIV.HRDATA);
        $display ("Initial check of GPIO read successful. HRDATA = %0h, expected result is 32'hFAB", gpio_vif.cb_DRIV.HRDATA);
        @gpio_vif.cb_DRIV;
        $display("----------[DRIVER-INITIAL-CHECK-END]----------");
        
	end
	endtask

endclass