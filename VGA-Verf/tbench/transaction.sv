class transaction;

    localparam WIDTH = 16;
    rand logic [2:0] command_signals; //[0]->HREADY, [1]->HSEL, [2]->HTRANS[1]

    rand logic [WIDTH/2-1:0] HWDATA_data; //only first 16 bits are used for HWDATA
    rand logic [WIDTH*3/2-1:0] HWDATA_data_upper_bits; //those are the unused bits, most of the time they will be 0

    rand logic inject_wrong_address; 
    rand logic [2*WIDTH-1:0] HADDR_inject;

    rand int delay_bn_cycles;

    int count_iter = 1;

    constraint commands{command_signals dist {7:=90, [0:6]:/10};}

    constraint wrong_address{inject_wrong_address dist {0:=90, 1:=10};}
    constraint address{HADDR_inject dist{32'h5200_0000:=40, [32'h5200_0001:32'h52FF_FFFF]:/60};}

    constraint HWDATA_max{(count_iter%55==0) -> HWDATA_data=='h7F;}
    constraint HWDATA_min{soft (count_iter%56==0) -> HWDATA_data==0;}
    constraint HWDATA_byte{HWDATA_data dist {[0:'h7F]:/95, ['h80:'hFF]:/5};}
    constraint HWDATA_upper_bits{HWDATA_data_upper_bits dist {0:=95, [1:'hFFFFFF]:/5};}

    constraint max_delay{delay_bn_cycles<16;}
    constraint weighted_delay{delay_bn_cycles dist {[0:3]:/40, [4:7]:/30, [8:11]:/20, [12:15]:/10};}

    function void post_randomize();
        count_iter++;
    endfunction

    function transaction copy();
        copy = new();
        copy.command_signals = this.command_signals;
        copy.HWDATA_data = this.HWDATA_data;
        copy.HWDATA_data_upper_bits = this.HWDATA_data_upper_bits;
        copy.inject_wrong_address = this.inject_wrong_address;
        copy.HADDR_inject = this.HADDR_inject;
        copy.delay_bn_cycles = this.delay_bn_cycles;
        copy.count_iter = this.count_iter;

    endfunction

endclass