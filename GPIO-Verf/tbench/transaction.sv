class transaction;

    localparam WIDTH = 16;
    parameter max_val = (2**WIDTH) - 1;
    rand logic PARITYSEL;
    rand logic inject_parity_error; // inject if high 
    rand logic write_cycle; //0 is for input cycle, 1 is for output cycle
    rand logic [2:0] command_signals; //[0]->HREADY, [1]->HSEL, [2]->HTRANS[1]

    rand logic [WIDTH-1:0] HWDATA_data; //only first 16 bits are used for HWDATA
    rand logic [WIDTH-1:0] HWDATA_data_upper_bits; //those are the unused bits, most of the time they will be 0
    rand logic [WIDTH-1:0] HWDATA_dir_inject; //inject wrong direction 
    rand logic dir_inject;

    rand logic [WIDTH-1:0] GPIOIN_data;
    logic      [WIDTH:0]   GPIOIN;

    rand logic [1:0] inject_wrong_address; //first bit for direction phase, second bit for data phase
    rand logic [2*WIDTH-1:0] HADDR_inject;

    rand int delay_bn_cycles;

    int count_iter = 1;

    constraint commands{command_signals dist {7:=90, [0:6]:/10};}
    constraint parity_error{inject_parity_error dist {0:=95, 1:=5};}

    constraint dir_injection{dir_inject dist {0:=97, 1:=3};}
    constraint wrong_address{inject_wrong_address dist {0:=80, 1:=10, 2:=10};}
    constraint address{HADDR_inject dist{32'h5300_0000:=20, 32'h5300_0004:=20, [32'h5300_0000:32'h53FF_FFFF]:/60};}

    constraint GPIOIN_max{(count_iter%50==0) -> GPIOIN_data=='hFFFF;}
    constraint GPIOIN_max{(count_iter%50==0) -> write_cycle==1'b0;}
    constraint GPIOIN_min{soft (count_iter%51==0) -> GPIOIN_data==0;}

    constraint HWDATA_max{(count_iter%55==0) -> HWDATA_data==max_val;}
    constraint GPIOIN_max{(count_iter%55==0) -> write_cycle==1'b1;}
    constraint HWDATA_min{soft (count_iter%56==0) -> HWDATA_data==0;}
    constraint HWDATA_upper_bits{HWDATA_data_upper_bits dist {0:=95, [1:'hFFFF]:/5};}

    constraint max_delay{delay_bn_cycles<16;}
    constraint weighted_delay{delay_bn_cycles dist {[0:3]:/40, [4:7]:/30, [8:11]:/20, [12:15]:/10};}

    function void post_randomize();
        if(inject_parity_error && !write_cycle) begin
            GPIOIN = {!PARITYSEL ? ~^GPIOIN_data : ^GPIOIN_data, GPIOIN_data};
            $display("[Transaction] Parity error injection: GPIOIN = %0h, transaction = %0d", GPIOIN, count_iter);
        end else begin
            GPIOIN = {PARITYSEL ? ~^GPIOIN_data : ^GPIOIN_data, GPIOIN_data};
        end
        count_iter++;
    endfunction

    function transaction copy();
        copy = new();
        copy.PARITYSEL = this.PARITYSEL;
        copy.inject_parity_error = this.inject_parity_error;
        copy.write_cycle = this.write_cycle;
        copy.command_signals = this.command_signals;
        copy.HWDATA_data = this.HWDATA_data;
        copy.HWDATA_data_upper_bits = this.HWDATA_data_upper_bits;
        copy.HWDATA_dir_inject = this.HWDATA_dir_inject;
        copy.dir_inject = this.dir_inject;
        copy.GPIOIN_data = this.GPIOIN_data;
        copy.GPIOIN = this.GPIOIN;
        copy.inject_wrong_address = this.inject_wrong_address;
        copy.HADDR_inject = this.HADDR_inject;
        copy.delay_bn_cycles = this.delay_bn_cycles;
        copy.count_iter = this.count_iter;

    endfunction

endclass