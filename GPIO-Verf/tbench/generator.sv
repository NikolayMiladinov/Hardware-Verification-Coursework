class generator;

    rand transaction trans;

    //declaring mailbox
    mailbox gpio_mail;

    //if not specified, only one transaction will be generated
    int trans_count = 1;

    event ended_gen;

    //constructor
    function new(mailbox gpio_mail, event ended_gen);
        //getting the mailbox handle from env
        this.gpio_mail = gpio_mail;
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