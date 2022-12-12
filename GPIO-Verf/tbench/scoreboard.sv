class scoreboard;

    mailbox gpio_mon_mail;

    function new(mailbox gpio_mon_mail);
        this.gpio_mon_mail = gpio_mon_mail;
    endfunction

    task run();
        $display("------[SCOREBOARD STARTED]------");
        forever begin
            mon_trans trans;
            gpio_mon_mail.get(trans);
            if(trans.io) begin
                if(trans.GPIOOUT[15:0]!=trans.HWDATA[15:0])
                    $display("[Scoreboard] ERROR during output cycle: GPIOOUT = %0h, HWDATA = %0h", trans.GPIOOUT[15:0], trans.HWDATA[15:0]);
                if(trans.GPIOOUT[16]!=(trans.PARITYSEL ? ~^trans.GPIOOUT[15:0] : ^trans.GPIOOUT[15:0]))
                    $display("[Scoreboard] ERROR in parity gen: GPIOOUT = %0h", trans.GPIOOUT[16:0]);
            end else begin
                if(trans.GPIOIN[16]!=(trans.PARITYSEL ? ~^trans.GPIOIN[15:0] : ^trans.GPIOIN[15:0])) begin
                    if(trans.PARITYERR!=1'b1) $display("[Scoreboard] PARITYERR incorrectly flagged: PARITYERR = %0b, GPIOIN = %0h, PARITYSEL = %0b", trans.PARITYERR, trans.GPIOIN, trans.PARITYSEL);
                end else begin
                    if(trans.PARITYERR!=1'b0) $display("[Scoreboard] PARITYERR incorrectly flagged: PARITYERR = %0b, GPIOIN = %0h, PARITYSEL = %0b", trans.PARITYERR, trans.GPIOIN, trans.PARITYSEL);
                end

                if(trans.GPIOIN[15:0]!=trans.HRDATA[15:0]) $display("[Scoreboard] ERROR during input cycle: GPIOIN = %0h, HRDATA = %0h", trans.GPIOIN, trans.HRDATA[16:0]);
            end
        end
    endtask

endclass