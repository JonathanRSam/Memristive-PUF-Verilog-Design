`timescale 1ns/1ps

module MemPUF #(
    parameter integer N_CHAL = 8,   // number of challenge bits
    parameter integer N_RESP = 8,   // number of response bits
    parameter VIN_WIDTH = 16,
    parameter G_WIDTH   = 16,
    parameter FRAC_BITS = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire vin_valid,

    input  wire [N_CHAL-1:0] C,   // challenge vector
    output reg  [N_RESP-1:0] R    // response vector
);

    /* -----------------------------
       Derived parameters
       ----------------------------- */
    localparam integer N_ROWS = 2 * N_CHAL;
    localparam integer N_COLS = 2 * N_RESP;

    // Safe upper bound for column sum width
    localparam integer COLSUM_WIDTH = G_WIDTH + 4;

    /* -----------------------------
       Voltage levels
       ----------------------------- */
    localparam signed [VIN_WIDTH-1:0] V_HIGH =
        4 * (1 << FRAC_BITS);
    localparam signed [VIN_WIDTH-1:0] V_LOW  =
       0 * (1 << FRAC_BITS);

    /* -----------------------------
       Row voltages from challenge bits
       ----------------------------- */
    wire signed [VIN_WIDTH-1:0] row_vin [0:N_ROWS-1];

    genvar i;
    generate
        for (i = 0; i < N_CHAL; i = i + 1) begin : ROW_VOLT
            assign row_vin[2*i]   = ( C[i]) ? V_HIGH : V_LOW;
            assign row_vin[2*i+1] = (~C[i]) ? V_HIGH : V_LOW;
        end
    endgenerate

    /* -----------------------------
       Memristor crossbar
       ----------------------------- */
    wire signed [G_WIDTH-1:0] g_out  [0:N_ROWS-1][0:N_COLS-1];
    wire signed [31:0]        g_real [0:N_ROWS-1][0:N_COLS-1];

    genvar r, c;
    generate
        for (r = 0; r < N_ROWS; r = r + 1) begin : ROW
            for (c = 0; c < N_COLS; c = c + 1) begin : COL
                MemRan mem_rc (
                    .clk       (clk),
                    .rst_n     (rst_n),
                    .vin_valid (vin_valid),
                    .vin       (row_vin[r]),
                    .g_out     (g_out[r][c]),
                    .g_real    (g_real[r][c])
                );
            end
        end
    endgenerate

    /* -----------------------------
       Column summation
       ----------------------------- */
    reg signed [COLSUM_WIDTH-1:0] col_sum [0:N_COLS-1];

    integer j, k;
    always @(*) begin
        for (j = 0; j < N_COLS; j = j + 1) begin
            col_sum[j] = {COLSUM_WIDTH{1'b0}};
            for (k = 0; k < N_ROWS; k = k + 1)
                col_sum[j] = col_sum[j] + g_out[k][j];
        end
    end

    /* -----------------------------
       Response generation
       ----------------------------- */
    integer b;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            R <= {N_RESP{1'b0}};
        end else if (vin_valid) begin
            for (b = 0; b < N_RESP; b = b + 1)
                R[b] <= (col_sum[2*b] > col_sum[2*b+1]);
        end
    end

endmodule