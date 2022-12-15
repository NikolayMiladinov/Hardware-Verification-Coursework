program test(vga_intf.DRIV intf_driv, vga_intf.MON intf_mon);
  
    //declaring environment instance
    environment env;

    initial begin
    //creating environment
    env = new(intf_driv, intf_mon);

    env.gen.trans_count = 1000;
    env.reset_test();
    env.initial_check();
    // env.reset_test();
    // env.run(1);
    end
endprogram