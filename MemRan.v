`timescale 1ns/1ps

module MemRan(
    clk,
    rst_n,
    vin_valid,
    vin,
    g_out,
    g_real
);

    /* -----------------------------
       Parameters
       ----------------------------- */
    parameter VIN_WIDTH   = 16;
    parameter G_WIDTH     = 16;
    parameter FRAC_BITS   = 8;    // vin fractional bits
    parameter N_POWER     = 2;
    parameter REAL_MAX    = 50;   
    parameter C_FRAC_BITS = 12;   // fractional bits for c

    /* -----------------------------
       Ports
       ----------------------------- */
    input  wire clk;
    input  wire rst_n;
    input  wire vin_valid;
    input  wire signed [VIN_WIDTH-1:0] vin;

    output reg  signed [G_WIDTH-1:0]   g_out;
    output wire signed [31:0]          g_real; 

    /* -----------------------------
       Internal registers
       ----------------------------- */
    reg signed [G_WIDTH-1:0]   ginit;
    reg signed [G_WIDTH-1:0]   c_base;
    reg signed [G_WIDTH-1:0]   c_offset;
    reg signed [G_WIDTH-1:0]   c;              // total: base + offset
    reg signed [VIN_WIDTH-1:0] vth;
    reg signed [VIN_WIDTH-1:0] vth_base;
    reg signed [VIN_WIDTH-1:0] vth_off;

    /* -----------------------------
       Initialization
       ----------------------------- */
    initial begin
        ginit = 128;

        c_base   = 1 <<< C_FRAC_BITS;
        c_offset = $urandom_range(-400,400);
        c = c_base + c_offset;

        // Voltage threshold
        vth_base = 4 * (1 << FRAC_BITS);
        vth_off  = $urandom_range(-20,20);
        vth      = vth_base + vth_off;
    end

    /* -----------------------------
       Absolute input voltage
       ----------------------------- */
    wire signed [VIN_WIDTH-1:0] vin_abs;
    assign vin_abs = (vin[VIN_WIDTH-1]) ? -vin : vin;

    /* -----------------------------
       Power of vin
       ----------------------------- */
    localparam integer PROD_WIDTH = VIN_WIDTH * N_POWER + 4;
    reg signed [PROD_WIDTH-1:0] v_pow;
    integer i;
    always @(*) begin
        case (N_POWER)
            1: v_pow = vin_abs;
            2: v_pow = vin_abs * vin_abs;
            3: v_pow = vin_abs * vin_abs * vin_abs;
            4: v_pow = vin_abs * vin_abs * vin_abs * vin_abs;
            5: v_pow = vin_abs * vin_abs * vin_abs * vin_abs * vin_abs;
            6: v_pow = vin_abs * vin_abs * vin_abs * vin_abs * vin_abs * vin_abs;
            default: begin
                v_pow = vin_abs;
                for (i = 1; i < N_POWER; i = i + 1)
                    v_pow = v_pow * vin_abs;
            end
        endcase
    end

    /* -----------------------------
       Extended multiplication and truncation
       ----------------------------- */
    localparam integer EXT_WIDTH = G_WIDTH + PROD_WIDTH + 8;
    reg signed [EXT_WIDTH-1:0] extended_mul;
    reg signed [G_WIDTH-1:0]   delta_g_trunc;

    always @(*) begin
        extended_mul = c * v_pow;
        delta_g_trunc = extended_mul >>> (N_POWER * FRAC_BITS + C_FRAC_BITS - 8);
    end

    /* -----------------------------
       Memristor state update
       ----------------------------- */
    reg signed [G_WIDTH-1:0] g_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            g_out <= ginit;
        else if (vin_valid) begin
            if (vin >= vth)
                g_out <= g_out + delta_g_trunc;
            else if (vin <= -vth)
                g_out <= g_out - delta_g_trunc;
    
            // clip at 0
            if (g_out < 0) g_out <= 0;
        end
    end

    /* -----------------------------
       Real conductance output
       ----------------------------- */
    assign g_real = (g_out * REAL_MAX) >>> FRAC_BITS;

endmodule