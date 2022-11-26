program test(gpio_intf.DRIV intf);
  
    //declaring environment instance
    Environment env;

    initial begin
    //creating environment
    env = new(intf);

    //setting the repeat count of generator as 10, means to generate 10 packets
    env.gen.trans_count = 10;
    env.reset_test();
    env.initial_check();
    
    env.run();
    end
endprogram