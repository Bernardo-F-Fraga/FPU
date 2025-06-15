`timescale 1us/1ns
module tb;

logic clock_100k;
logic reset;
logic [31:0] op_a;
logic [31:0] op_b;
logic [31:0] data_out;
logic [3:0] status_out;

    FPU dut ( 
    .clock_100k(clock_100k),
    .reset(reset),
    .op_a(op_a),
    .op_b(op_b),
    .data_out(data_out),
    .status_out(status_out)
    );
    
always #5 clock_100k = ~clock_100k;

    initial begin
        reset = 1;
        op_a = 32'b0;
        op_b = 32'b0;
        #20;
        reset = 0;
        #100;
        reset = 1;
        #50;
        // Formato: {sinal, expoente[11], mantissa[20]}

endmodule
