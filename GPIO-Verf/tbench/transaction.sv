class transaction;

    localparam WIDTH = 16;
    rand logic PARITYSEL;
    rand logic write_cycle; //0 is for read cycle, 1 is for write cycle
    rand logic [WIDTH-1:0] HWDATA; //only first 16 bits are used for HWDATA
    rand logic [WIDTH-1:0] a;
    logic [WIDTH:0] GPIOIN = {PARITYSEL ? ~^a : ^a, a};

endclass