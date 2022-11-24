class driver;

    virtual gpio_if gpio_vif;
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
        gpioif.cb_DRIV.HADDR <= 'b0; 
        gpioif.cb_DRIV.HWDATA <= 'b0;
        gpioif.cb_DRIV.GPIOIN <= 'b0;

        //hold reset for n cycles
        repeat (n) @gpio_vif.cb_DRIV;

        gpio_vif.HRESETn = 1; //deassert reset
        $display("--------- [DRIVER] Reset Ended ---------");
    endtask


    //drive the transaction items to interface signals
    task drive();
        //forever begin
        Transaction trans;
        // gpio_vif.cb_DRIV.req <= 0;
        // gpio_mail.get(trans);
        // $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
        // @(posedge gpio_vif.clk) begin
        //     gpio_vif.cb_DRIV.a <= trans.i;
        //     gpio_vif.cb_DRIV.b <= trans.j;
        // end

        // gpio_vif.cb_DRIV.req <= 1;
        // wait (gpio_vif.cb_DRIV.done == 1);
        // gpio_vif.cb_DRIV.req <= 0;

        $display("----------[DRIVER-END-OF-TRANSFER]----------");
        no_transactions++;
        //end
    endtask

    task initial_check();                         // Initial check of gpioiplier
	begin
        //-------Check Write command--------

        //Setup variables for write cycle
        gpio_vif.cb_DRIV.HTRANS <= 'd2;
        gpio_vif.cb_DRIV.HWRITE <= 'b1;
        gpio_vif.cb_DRIV.HSEL <= 'b1;
        gpio_vif.cb_DRIV.HREADY <= 'b1;
        gpioif.cb_DRIV.HADDR <= 32'h5300_0004; 
        @gpio_vif.cb_DRIV;

        //Write 1 to direction register for output direction and indicate data cycle will follow
        gpioif.cb_DRIV.HWDATA <= 'b1;
        gpioif.cb.HADDR <= 32'h53000000;
        @gpio_vif.cb_DRIV;

        //Write value to output register, should appear on GPIOOUT next cycle
        gpioif.cb_DRIV.HWDATA <= 32'hBEEF;
        $display ("Initial check of GPIO write. GPIOOUT = %0d, expected result is 32'hBEEF", gpioif.cb_DRIV.GPIOUT);

        @gpio_vif.cb_DRIV;
        $display ("Initial check of GPIO write. GPIOOUT = %0d, expected result is 32'hBEEF", gpioif.cb_DRIV.GPIOUT);
        
	end
	endtask

endclass