`timescale 1ns/1ps

module TB_MemPUF;

    /* -----------------------------
       Parameters
       ----------------------------- */
    localparam integer N_CHAL = 8;
    localparam integer N_RESP = 8;
    localparam VIN_WIDTH = 16;
    localparam G_WIDTH   = 16;
    localparam FRAC_BITS = 8;

    /* -----------------------------
       Signals
       ----------------------------- */
    reg clk;
    reg rst_n;
    reg vin_valid;

    reg  [N_CHAL-1:0] C;      // challenge input
    wire [N_RESP-1:0] R;      // response output

    reg  [N_RESP-1:0] R_first;

    /* -----------------------------
       DUT
       ----------------------------- */
    PUF_FPGA #(
        .N_CHAL   (N_CHAL),
        .N_RESP   (N_RESP),
        .VIN_WIDTH(VIN_WIDTH),
        .G_WIDTH  (G_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .vin_valid (vin_valid),
        .C         (C),
        .R         (R)
    );

    /* -----------------------------
       Clock
       ----------------------------- */
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    /* -----------------------------
       Test sequence
       ----------------------------- */
    initial begin
        // >>> SET YOUR CHALLENGE HERE <<<
        C = 8'b1010_1001;   // example challenge

        rst_n     = 0;
        vin_valid = 0;
        R_first   = 0;

        $display("\n=== SINGLE-CHALLENGE MEMPUF TEST ===\n");
        $display("Challenge = %b", C);

        /* Reset */
        #20 rst_n = 1;

        /* Apply challenge */
        #10 vin_valid = 1;
        #200;

        R_first = R;
        $display("[%0t] First response  = %b", $time, R_first);

        /* Reset and re-apply to check stability */
        vin_valid = 0;
        #20 rst_n = 0;
        #20 rst_n = 1;

        #10 vin_valid = 1;
        #200;

        $display("[%0t] Second response = %b", $time, R);

        if (R !== R_first)
            $display(">>> WARNING: RESPONSE CHANGED <<<");
        else
            $display(">>> RESPONSE STABLE <<<");

        $display("\n=== TEST COMPLETE ===\n");
        $stop;
    end

endmodule
