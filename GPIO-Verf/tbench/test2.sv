program test2(gpio_intf.DRIV intf_driv, gpio_intf.MON intf_mon);
  
    //declaring environment instance
    environment env;

    initial begin
    //creating environment
    env = new(intf_driv, intf_mon);

    //setting the repeat count of generator as 10, means to generate 10 packets
    env.gen.trans_count = 1000;
    env.reset_test();
    env.initial_check();
    env.reset_test();
    env.run(2);
    end
endprogram