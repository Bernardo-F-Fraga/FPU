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
        $display("-------------------------------");
        $display("Inicio dos Testes\n");
        clock_100k = 0;
        reset = 0;
        op_a = 0;
        op_b = 0;
        #10;
        reset = 1;
        #10;
        //soma simples 1 + 1
        op_a = 32'b00000000000000000000000000000001;
        op_b = 32'b00000000000000000000000000000001;        
        #170;
        // subtração simples 2 - 1
        op_a = 32'b00000000000000000000000000000010;
        op_b = 32'b10000000000000000000000000000001; 
        #170;
        //com overflow
        op_a = 32'b01111111111111111111111111111111;
        op_b = 32'b01111111111111111111111111111111;
        #300;
        // soma com ponto flutuante
        op_a = 32'b0_10000000000_01000000000000000000; // 2.5
        op_b = 32'b0_10000000000_01000000000000000000; // 2.5
        #300;

        $display("\n Testes finalizados.");
        $stop;


    end

endmodule