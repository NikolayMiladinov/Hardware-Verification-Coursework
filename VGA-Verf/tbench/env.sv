class environment;

    generator gen;
    driver driv;
    monitor mon;
    // scoreboard scor;

    mailbox vga_mail;
    mailbox vga_mon_mail;
    event ended_gen;
    event ended_1mil;
    virtual vga_intf.DRIV vga_driv_vif;
    virtual vga_intf.MON vga_mon_vif;

    function new(virtual vga_intf.DRIV vga_driv_vif, virtual vga_intf.MON vga_mon_vif);
        this.vga_driv_vif = vga_driv_vif;
        this.vga_mon_vif = vga_mon_vif;
        vga_mail = new();
        vga_mon_mail = new();

        gen = new(vga_mail, ended_gen);
        driv = new(vga_driv_vif, vga_mail, ended_1mil);
        mon = new(vga_mon_vif, vga_mon_mail);
        // scor = new(vga_mon_mail);
    endfunction

    task reset_test();
        driv.reset();
    endtask

    task initial_check();
        mon.fd = $fopen("./out.txt","w");
        if(mon.fd) $display("Opened the file");
        fork
            driv.initial_check();
            mon.run();
        join_none
        wait(driv.ended_1mil.triggered);
        $fclose(mon.fd);
        $display("Closed the file");
        $stop;
    endtask

    task test();
        fork
            gen.gen();
            driv.drive(1'b0);
            mon.run();
            // scor.run();
        join_none
    endtask

    task test_rand_reset();
        fork
            gen.gen();
            driv.drive(1'b1);
            // mon.run();
            // scor.run();
        join_none
    endtask

    task wait_test_end();
        wait(gen.ended_gen.triggered);
        wait(gen.trans_count == driv.no_transactions);
        // mon.print_error();
        // scor.print_error();
        $stop;
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

    task run_rst_rand();
        test_rand_reset();
        wait_test_end();
    endtask

endclass