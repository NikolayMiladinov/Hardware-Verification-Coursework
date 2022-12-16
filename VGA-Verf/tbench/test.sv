program test(vga_intf.DRIV intf_driv, vga_intf.MON intf_mon);
  
    //declaring environment instance
    environment env;

    initial begin
    //creating environment
    env = new(intf_driv, intf_mon);
    $display("This is test 1 for VGA");
    env.gen.trans_count = 800;
    env.reset_test();
    // env.initial_check();
    // env.reset_test();
    env.run();
    end
endprogram