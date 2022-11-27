class transaction;

    localparam WIDTH = 16;
    rand logic PARITYSEL;
    rand logic write_cycle; //0 is for input cycle, 1 is for output cycle
    rand logic [WIDTH-1:0] HWDATA; //only first 16 bits are used for HWDATA
    rand logic [WIDTH-1:0] a;
    logic [WIDTH:0] GPIOIN;

    function void post_randomize();
        GPIOIN = {PARITYSEL ? ~^a : ^a, a};
    endfunction

endclass