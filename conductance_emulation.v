//Memristor implementation using conductance as state variable

module memristor_conductance #(
  parameter WIDTH = 32,
  parameter N = 2,
  parameter C = 1,
  parameter VTH = 8'd32, 
  parameter GINIT = 32'd100
)(
  input wire clk,
  input wire reset,
  input wire signed [7:0] vin,
  output reg [WIDTH-1 : 0] G	//reg [7:0] G
);
  
  reg [WIDTH-1 : 0] G_prev;
  wire signed [WIDTH-1 : 0] abs_vin;
  wire signed [WIDTH-1 : 0] pow_vin_n;
  wire [WIDTH-1 : 0] delta;	//Value of c * |V|^n
  
  assign abs_vin = vin < 0 ? -vin : vin;
  
  //Creating the value of |V|^n
  integer i;
  reg signed [WIDTH-1 : 0] temp_pow;
  always @(*) begin
    temp_pow = 1;	//Setting the variable as 1 to be exponented
    for (i = 1; i <= N+1; i = i + 1)
      temp_pow = temp_pow * abs_vin;		//formulating |V|^n
  end
  assign pow_vin_n = temp_pow;
  
  assign delta = C * pow_vin_n;	//formulating c * |V|^n
  
  always @(posedge clk) begin
    if (reset) begin
      G <= GINIT;
    end
    else
      begin
        G_prev = G;
        if (vin >= VTH)
          G <= G_prev + delta;
        else if (vin <= -VTH)
          G <= G_prev - delta;
        else
          G <= G_prev;
      end
  end
endmodule
          


