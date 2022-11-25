class driver;

    virtual gpio_intf.DRIV gpio_vif;
    mailbox gpio_mail;

    //used to count the number of transactions
    int no_transactions;

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

        //hold reset for n cycles
        repeat (n) @gpio_vif.cb_DRIV;

        gpio_vif.HRESETn = 1; //deassert reset
        $display("--------- [DRIVER] Reset Ended ---------");
    endtask


    //drive the transaction items to interface signals
    task drive();
        forever begin
            transaction trans;

            if(gpio_vif.cb_DRIV.HREADY!=1'b1) begin
                gpio_vif.cb_DRIV.HREADY <= 1'b1;
                @gpio_vif.cb_DRIV;
            end

            gpio_mail.get(trans);
            $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
            //prepare to write to direction register
            gpio_vif.cb_DRIV.HTRANS <= 'd2;
            gpio_vif.cb_DRIV.HWRITE <= 'b1;
            gpio_vif.cb_DRIV.HSEL <= 'b1;
            gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004; 
            @gpio_vif.cb_DRIV; 

            gpio_vif.cb_DRIV.HWDATA <= {15'b0, trans.write_cycle};
            gpio_vif.cb_DRIV.HADDR <= 32'h53000000;
            @gpio_vif.cb_DRIV;
            
            if(trans.write_cycle == 1'b1) gpio_vif.cb_DRIV.HWDATA <= trans.HWDATA;
            else gpio_vif.cb_DRIV.GPIOIN <= trans.GPIOIN;

            $display("----------[DRIVER-END-OF-TRANSFER]----------");
            no_transactions++;
        end
    endtask

    task initial_check();                         // Initial check of gpioiplier
	begin
        $display("----------[DRIVER-INITIAL-CHECK-START]----------");
        //-------Check Write command--------
        
        //Setup variables for write cycle
        gpio_vif.cb_DRIV.HREADY <= 'b1;
        @gpio_vif.cb_DRIV;
        gpio_vif.cb_DRIV.HTRANS <= 'd2;
        gpio_vif.cb_DRIV.HWRITE <= 'b1;
        gpio_vif.cb_DRIV.HSEL <= 'b1;
        gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004; 
        @gpio_vif.cb_DRIV;

        //Write 1 to direction register for output direction and indicate data cycle will follow
        gpio_vif.cb_DRIV.HWDATA <= 'b1;
        gpio_vif.cb_DRIV.HADDR <= 32'h53000000;
        @gpio_vif.cb_DRIV;

        //Write value to output register, should appear on GPIOOUT next cycle
        gpio_vif.cb_DRIV.HWDATA <= 'hBEEF;

        @gpio_vif.cb_DRIV;
        @gpio_vif.cb_DRIV;
        assert (gpio_vif.cb_DRIV.GPIOOUT == 'hBEEF)
	    else $fatal ("Initial check of gpio write failed. GPIOOUT = %0h, expected result is 32'hBEEF", gpio_vif.cb_DRIV.GPIOOUT);
        
        @gpio_vif.cb_DRIV;
        assert (gpio_vif.cb_DRIV.HRDATA == 'hBEEF)
	    else $fatal ("Initial check of gpio write failed. GPIOOUT = %0h, HRDATA = %0h, expected result is 32'hBEEF", gpio_vif.cb_DRIV.GPIOOUT, gpio_vif.cb_DRIV.HRDATA);
        $display ("Initial check of GPIO write successful. GPIOOUT = %0h, HRDATA = %0h, expected result is 32'hBEEF", gpio_vif.cb_DRIV.GPIOOUT, gpio_vif.cb_DRIV.HRDATA);

        //Setup variables for read cycle
        gpio_vif.cb_DRIV.HADDR <= 32'h5300_0004;

        @gpio_vif.cb_DRIV;

        //Write 0 to direction register for input direction and indicate data cycle will follow
        gpio_vif.cb_DRIV.HWDATA <= 'b0;
        gpio_vif.cb_DRIV.HADDR <= 32'h53000000;
        @gpio_vif.cb_DRIV;

        gpio_vif.cb_DRIV.GPIOIN <= 'hFAB;

        @gpio_vif.cb_DRIV;
        @gpio_vif.cb_DRIV;
        assert (gpio_vif.cb_DRIV.HRDATA == 'hFAB)
	    else $fatal ("Initial check of gpio read failed. HRDATA = %0d, expected result is 32'hFAB", gpio_vif.cb_DRIV.HRDATA);
        $display ("Initial check of GPIO read successful. HRDATA = %0d, expected result is 32'hFAB", gpio_vif.cb_DRIV.HRDATA);
        @gpio_vif.cb_DRIV;
        $display("----------[DRIVER-INITIAL-CHECK-END]----------");
        
	end
	endtask

endclass