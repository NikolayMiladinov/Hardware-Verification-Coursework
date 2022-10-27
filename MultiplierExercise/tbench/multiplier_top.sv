interface multif
    #parameter (WIDTH = 5);
    (input bit clk);

    logic req, rdy, done, rst_n;
    logic [WIDTH-1:0]       a,b;
    logic [WIDTH-1:0]       ab;

    clocking cb @(posedge clk);
        input rdy;
        output req;
    endclocking

    modport TEST (input a, b, output rst_n, ab, done, clocking cb);
    modport DUT (input clk, rst_n, a, b, req, output ab, rdy, done)
endinterface
    
module multiplier_top
    #parameter (WIDTH = 5);
    bit                         clk;

    inital begin
        clk = 0;
        foreer #100 clk = !clk;
    end

    mult_if multif(clk);
    multiplier mul1 (multif);
    multiplier_tb mul1_tb (multif);
endmodule

