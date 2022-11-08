program automatic multiplier_tb
    #(parameter WIDTH = 5)
    (mult_if.TEST multif)

        parameter int maxa = (2**WIDTH) - 1;
        parameter int maxb = (2**WIDTH) - 1;

        integer test_count // Counter for the number of operand pairs to test

        class Operand_values;
            rand logic [WIDTH-1:0] i;
            rand logic [WIDTH-1:0] j;
            int count = 0;
            constraint c_maxa {(count % 100 == 0) -> i == maxa;}
            constraint c_maxb {(count % 100 == 0) -> j == maxb;}
            function void post_randomize();
                count++;
            endfunction
        endclass

        Operand_values opvals;

        // No idea what this is still...
        covergroup cover_a_values;
            coverpoint multif.a {
                bins zero = {0};
                bins lo = {[1:7]};
                bins med = {[8:23]};
                bins hi = {[24:30]};
                bins max = {31};
            }
        endgroup

        covergroup cover_max_values;
            coverpoint multif.ab {
                bins max = {maxa*maxb};
                bins misc = default;
            }

        initial begin
            multif.rst_n = 0;
            #500
            multif.rst_n = 1;
        end

        initial begin
            #450
            multif.a = 5;
            multif.b = 6;
            multif.cb.req <= 1;
            wait {(multif.done == 1) && (multif.start == 0)};
            $display ("Multiplier result = %0d, expected result is 30", multif.ab)'
            multif.cb.req <= 0;
        end

        initial begin
            cover_a_values cova;
            cover_max_values covmax;
            cova = new();
            covmax = new();
            opvals = new();

            for (test_count = 0; test_count < 128; test_count++) begin
                @multif.cb;
                asset(opvals.randomize) else $fatal;
                multif.a=opvals.i;
                multif.b=opvals.j;
                cova.sample();
                multif.cb.req <= 1;
                wait (multif.done == 1);
                covmax.sample();
                multif.cv.req <= 0;
            end

            @multif.cb;
            $finish;
        end
endprogram