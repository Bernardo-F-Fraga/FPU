`timescale 1us/1ns
module tb;

logic clock_100k;
logic reset;
logic [31:0] op_a;
logic [31:0] op_b;
logic [31:0] data_out;
logic [3:0] status_out;

    FPU dut ( 
    .clock_100k(clk),
    .reset(rst),
    .op_a(op_a),
    .op_b(op_b),
    .data_out(data_out),
    .status_out(status_out)
    );
    
always #5 clk = ~clk;

    initial begin
        $display("Iniício dos testes");
        rst = 0;
        op_a = 32'b0;
        op_b = 32'b0;
        #20;
        
        #100;
        rst = 1;
        #50;

        //  Teste 1: Soma simples 1.0 + 1.0
        test(32'b0_10000000001_00000000000000000000,    //1.0
             32'b0_10000000001_00000000000000000000);   //1.0

        //  Teste 2: Subtração simples 2.0 - 1.0
        test(32'b0_10000000010_00000000000000000000,    //2.0
             32'b1_10000000001_00000000000000000000);   //-1.0

        //  Teste 3: Soma de 0 + 3.5
        test(32'b0_00000000000_00000000000000000000,    //2.0
             0_10000000001_10000000000000000000);   //-1.0

        //  Teste 4: Subtração do mesmo número
        test(32'b0_10000000001_00000000000000000000,    //1.0
             32'b1_10000000001_00000000000000000000);   //-1.0

        //  Teste 5: Overflow  (expoente muito alto)
        test(32'b0_11111111111_00000000000000000000,    // Expoente Máximo
             32'b0_11111111111_00000000000000000000);   

        //  Teste 6: Underflow (mantissa pequena com expoente mínimo)
        test(32'b0_00000000001_00000000000000000001,    
             32'b0_00000000001_00000000000000000001);  

        //  Teste 7: Inexact
        test(32'b0_10000000001_00000000000000000001,    //1.000...01
             32'b0_10000000001_00000000000000000001);   //1.000...01

        //  Teste 8: Soma Negativa -2.0 + -1.0
        test(32'b1_10000000010_00000000000000000000,    //-2.0
             32'b1_10000000001_00000000000000000000);   //-1.0

        //  Teste 9: Soma 0 + 0
        test(32'b0_00000000000_00000000000000000000,    
             32'b0_00000000000_00000000000000000000);   

        //  Teste 10: Subtração invertida 1.0 - 2.0
        test(32'b0_10000000001_00000000000000000000,    //1.0
             32'b1_10000000010_00000000000000000000);   //-2.0
    
    end

task test(input logic [31:0] a, input logic [31:0] b);
    begin 
    @(negedge clk);
    op_a <= a;
    op_b <= b;

    @(posedge clk); repeat (8) @(posedge clk); // Aguarda os ciclos
    $display("OpA = %b, OpB = %b -> Result = %b, Status = %b", a, b, data_out, status_out);
    end
endtask


endmodule
