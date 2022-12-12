class generator;

    rand transaction trans;
    transaction trans_copy;
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
        trans = new();

        repeat(trans_count) begin
            assert (trans.randomize()) else $fatal("Gen:: trans randomization failed");
            trans_copy = trans.copy();
            gpio_mail.put(trans_copy);
        end
        -> ended_gen;
    endtask

endclass