class Environment;

    generator gen;
    driver driv;
    mailbox gpio_mail;
    event ended_gen;
    virtual gpio_intf.DRIV gpio_vif;

    function new(virtual gpio_intf.DRIV gpio_vif);
        this.gpio_vif = gpio_vif;
        gpio_mail = new();

        gen = new(gpio_mail, ended_gen);
        driv = new(gpio_vif, gpio_mail);
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