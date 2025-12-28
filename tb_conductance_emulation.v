module tb;

    reg clk;
    reg reset;
    reg signed [7:0] vin; 
    wire [31:0] G;
    
    real v_temp; 

    // Instantiate the memristor
    memristor_conductance dut (
        .clk(clk),
        .reset(reset),
        .vin(vin),
        .G(G)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test stimulus
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);

        // Initialize
        reset = 1; 
        v_temp = 0;
        vin = 0;
        #10;
        reset = 0;

        // 1. From 0 to 4
        while (v_temp < 4.0) begin
            v_temp = v_temp + 0.25;
            vin = v_temp; 
            #10;
        end

        // 2. From 4 back to 0
        while (v_temp > 0.0) begin
            v_temp = v_temp - 0.25;
            vin = v_temp;
            #10;
        end

        // 3. From 0 to -4
        while (v_temp > -4.0) begin
            v_temp = v_temp - 0.25;
            vin = v_temp;
            #10;
        end

        // 4. From -4 back to 0
        while (v_temp < 0.0) begin
            v_temp = v_temp + 0.25;
            vin = v_temp;
            #10;
        end

        #20;
        $finish;
    end

endmodule