class transaction;

    localparam WIDTH = 16;
    rand logic PARITYSEL;
    rand logic inject_parity_error; // inject if high
    rand logic write_cycle; //0 is for input cycle, 1 is for output cycle
    rand logic [2:0] command_signals; //[0]->HREADY, [1]->HSEL, [2]->HTRANS[1]

    rand logic [WIDTH-1:0] HWDATA_data; //only first 16 bits are used for HWDATA
    rand logic [WIDTH-1:0] HWDATA_dir_inject; //inject wrong direction 
    rand logic dir_inject;

    rand logic [WIDTH-1:0] GPIOIN_data;
    logic      [WIDTH:0]   GPIOIN;

    rand logic [1:0] inject_wrong_address; //first bit for direction phase, second bit for data phase
    rand logic [2*WIDTH-1:0] HADDR_inject;

    rand int delay_bn_cycles;

    int count_iter;

    constraint commands{command_signals dist {7:=90, [0:6]:/10};}
    constraint parity_error{inject_parity_error dist {0:=95, 1:=5};}

    constraint dir_injection{dir_inject dist {0:=97, 1:=3};}
    constraint wrong_address{inject_wrong_address dist {0:=80, 1:=10, 2:=10};}
    constraint address{HADDR_inject dist{32'h5300_0000:=20, 32'h5300_0004:=20, [32'h5300_0000:32'h53FF_FFFF]:/60};}

    constraint GPIOIN_max{count%50 -> GPIOIN_data=='hFFFF;}
    constraint GPIOIN_min{count%51 -> GPIOIN_data==0;}

    constraint HWDATA_max{count%55 -> GPIOIN_data=='hFFFF;}
    constraint HWDATA_min{count%56 -> GPIOIN_data==0;}

    constraint max_delay{delay_bn_cycles<16;}
    constraint weighted_delay{delay_bn_cycles dist {[0:3]:/40, [4:7]:/30, [8:11]:/20, [12:15]:/10};}

    function void post_randomize();
        if(inject_parity_error) GPIOIN = {!PARITYSEL ? ~^GPIOIN_data : ^GPIOIN_data, GPIOIN_data};
        else GPIOIN = {PARITYSEL ? ~^GPIOIN_data : ^GPIOIN_data, GPIOIN_data};

        count_iter++;
    endfunction

endclass