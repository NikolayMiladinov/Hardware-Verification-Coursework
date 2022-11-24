class transaction;

    localparam WIDTH = 16;
    rand logic write_cycle; //0 is for read cycle, 1 is for write cycle
    rand logic [2*WIDTH-1:0] HWDATA;
    rand logic [WIDTH-1:0] GPIOIN;

endclass