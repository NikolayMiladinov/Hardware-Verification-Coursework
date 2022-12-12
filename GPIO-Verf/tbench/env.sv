class environment;

    generator gen;
    driver driv;
    monitor mon;
    scoreboard scor;

    mailbox gpio_mail;
    mailbox gpio_mon_mail;
    event ended_gen;
    virtual gpio_intf.DRIV gpio_driv_vif;
    virtual gpio_intf.MON gpio_mon_vif;

    function new(virtual gpio_intf.DRIV gpio_driv_vif, virtual gpio_intf.MON gpio_mon_vif);
        this.gpio_driv_vif = gpio_driv_vif;
        this.gpio_mon_vif = gpio_mon_vif;
        gpio_mail = new();
        gpio_mon_mail = new();

        gen = new(gpio_mail, ended_gen);
        driv = new(gpio_driv_vif, gpio_mail);
        mon = new(gpio_mon_vif, gpio_mon_mail);
        scor = new(gpio_mon_mail);
    endfunction

    task reset_test();
        driv.reset();
    endtask

    task initial_check();
        driv.initial_check();
    endtask

    task test();
        fork
            gen.gen();
            driv.drive(1);
            mon.run();
            scor.run();
        join_none
    endtask

    task wait_test_end();
        wait(gen.ended_gen.triggered);
        wait(gen.trans_count == driv.no_transactions);
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

endclass