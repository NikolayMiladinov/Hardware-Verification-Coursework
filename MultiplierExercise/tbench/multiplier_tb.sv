class Transaction;

    localparam WIDTH = 5;
    rand logic [WIDTH-1:0] i,j;

endclass

class Generator;

    rand Transaction trans;

    //declaring mailbox
    mailbox mult_mail;

    //if not specified, only one transaction will be generated
    int trans_count = 1;

    event ended_gen;

    //constructor
    function new(mailbox mult_mail, event ended_gen);
        //getting the mailbox handle from env
        this.mult_mail = mult_mail;
        this.ended_gen = ended_gen;
    endfunction

    task gen();

        repeat(trans_count) begin
            trans = new();
            if( !trans.randomize() ) $fatal("Gen:: trans randomization failed");
            mult_mail.put(trans);
        end
        -> ended_gen;
    endtask

endclass


interface mult_if  
   #(parameter WIDTH = 5) 
       (input logic clk, rst_n);

        logic req, rdy, done;
 	logic [WIDTH-1:0]	a, b;
	logic [2*WIDTH-1:0]  	ab;

// Declare clocking block


   //driver clocking block
   clocking driver_cb @(posedge clk);
      default input #1 output #1;
      output req;
      output rst_n;
      output a;
      output b;
      input  ab;
      input  rdy;
      input  done;  
   endclocking
  
   //monitor clocking block
   clocking monitor_cb @(posedge clk);
      default input #1 output #1;
      input req;
      input rst_n;
      input a;
      input b;
      input ab;
      input rdy;
      input done;  
   endclocking

   //DUT clocking block
   clocking dut_cb @(posedge clk);
      default input #1 output #1;
      input req;
      input rst_n;
      input a;
      input b;
      output ab;
      output rdy;
      output done;  
   endclocking

// Define modports for TEST (the testbench) and DUT (the multiplier)

    modport DRIVER (input ab, rdy, done, clk, output rst_n, req, a, b,
                 clocking driver_cb);

    modport MONITOR (input a , b, rst_n, ab, done, req, rdy, clk,
                 clocking monitor_cb);

    modport DUT (output ab, rdy, done, input req, a, b, clk, rst_n,
                 clocking dut_cb);
endinterface

class Driver;

    virtual mult_if mult_vif;
    mailbox mult_mail;

    //used to count the number of transactions
    int no_transactions;

    function new(virtual mult_if mult_vif, mailbox mult_mail);
        this.mult_vif = mult_vif;
        this.mult_mail = mult_mail;
    endfunction

    //Reset task, Reset the Interface signals to default/initial values
    task reset();
        mult_vif.rst_n = 0;
        $display("--------- [DRIVER] Reset Started ---------");
        mult_vif.DRIVER.driver_cb.a <= 0;
        mult_vif.DRIVER.driver_cb.b <= 0;
        mult_vif.DRIVER.driver_cb.req  <= 0;   
        @mult_vif.driver_cb;
        @mult_vif.driver_cb;
        mult_vif.rst_n = 1;
        $display("--------- [DRIVER] Reset Ended ---------");
    endtask


    //drive the transaction items to interface signals
    task drive();
        //forever begin
        Transaction trans;
        mult_vif.DRIVER.driver_cb.req <= 0;
        mult_mail.get(trans);
        $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
        @(posedge mult_vif.DRIVER.clk) begin
            mult_vif.DRIVER.driver_cb.a <= trans.i;
            mult_vif.DRIVER.driver_cb.b <= trans.j;
        end

        mult_vif.DRIVER.driver_cb.req <= 1;
        wait (mult_vif.DRIVER.driver_cb.done == 1);
        mult_vif.DRIVER.driver_cb.req <= 0;

        $display("-----------------------------------------");
        no_transactions++;
        //end
    endtask

    task initial_check();                         // Initial check of multiplier
	begin
        wait (multif.cb.rdy);		      // Wait for multiplier to be idle
        mult_vif.DRIVER.driver_cb.a = 5;
        mult_vif.DRIVER.driver_cb.b = 6;
        mult_vif.DRIVER.driver_cb.req <= 1;		      // Initiate the multiplication

        wait (mult_vif.DRIVER.driver_cb.done == 1);           // And wait for it to finish

        assert (mult_vif.DRIVER.driver_cb.ab == 30)
	    else $fatal ("Initial check of multiplier failed. Multiplier result = %0d, expected result is 30", mult_vif.DRIVER.driver_cb.ab);
	    $display ("Initial check of multiplier passed. Multiplier result = %0d, expected result is 30", mult_vif.DRIVER.driver_cb.ab);

        mult_vif.DRIVER.driver_cb.req <= 0;
	end
	endtask

endclass



class Environment;

    Generator gen;
    Driver driv;
    mailbox mult_mail;
    event ended_gen;
    virtual mult_if mult_vif;

    function new(virtual mult_if mult_vif);
        this.mult_vif = mult_vif;
        mult_mail = new();

        gen = new(mult_mail, ended_gen);
        driv = new(mult_vif, mult_mail);
    endfunction

    task reset_test();
        driv.reset();
    endtask

    task test();
        fork
            gen.gen();
            driv.drive();
        join_none
    endtask

    task wait_test_end();
        wait(gen.ended_gen.triggered);
        wait(gen.trans_count == driv.no_transactions); 
    endtask

    task run_reset();
        reset_test();
        test();
        wait_test_end();
    endtask

    task run();
        test();
        wait_test_end();
    endtask

endclass

program test(mult_if intf);
  
    //declaring environment instance
    Environment env;

    initial begin
    //creating environment
    env = new(intf);

    //setting the repeat count of generator as 10, means to generate 10 packets
    env.gen.trans_count = 10;
    env.reset_test();
    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
    end
endprogram



module tbench_top;
  
    //clock and reset signal declaration
    bit clk;
    bit reset;

    //clock generation
    always #10 clk = ~clk;

    //reset Generation
    // initial begin
    //     test.env.reset_test();
    // end

    //creatinng instance of interface, inorder to connect DUT and testcase
    mult_if intf(clk,reset);

    //DUT instance, interface signals are connected to the DUT ports
    multiplier DUT (intf);

    //Testcase instance, interface handle is passed to test as an argument
    test t1(intf);
  
endmodule