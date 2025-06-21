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

    task mostra_resultado(string teste, logic [31:0] esperado);
        $display("%s | Esperado (hex): %h | Saída FPU (hex): %h | Status: %b", 
                 teste, esperado, data_out, status_out);
    endtask

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

        // 1. Soma simples: 1.0 + 1.0 = 2.0
        op_a = 32'h3FF00000; // 1.0
        op_b = 32'h3FF00000; // 1.0
        #300;
        mostra_resultado("Teste 1: 1.0 + 1.0", 32'h40000000); // Esperado: 2.0

        // 2. Subtração simples: 2.0 + (-1.0) = 1.0 
        op_a = 32'h40000000; // 2.0   
        op_b = 32'hBFF00000; // -1.0 
        #300;
        mostra_resultado("Teste 2: 2.0 + (-1.0)", 32'h3FF00000); // Esperado: 1.0

        // 3. Soma com zero: 5.0 + 0.0 = 5.0
        op_a = 32'h40140000; // 5.0
        op_b = 32'h00000000; // 0.0
        #300;
        mostra_resultado("Teste 3: 5.0 + 0.0", 32'h40140000); // Esperado: 5.0

        // 4. Subtração de iguais: 8.0 + (-8.0) = 0.0 
        op_a = 32'h40200000; //  8.0                                                
        op_b = 32'hC0200000; // -8.0 
        #300;
        mostra_resultado("Teste 4: 0.0 + (-8.0)", 32'h00000000); // Esperado: 0.0

        // 5. Subtração identidade: 8.0 + (-0.0) = 8.0  
        op_a = 32'h40200000; // 8.0
        op_b = 32'h00000000; // 0.0
        #300;
        mostra_resultado("Teste 5: 8.0 - 0.0", 32'h40200000); // Esperado: 7.0

        // 6. Indentidade negativa: 0.0 + (-8.0) = 0.0 
        op_a = 32'h00000000; //  0.0                                                
        op_b = 32'hC0200000; // -8.0 
        #300;
        mostra_resultado("Teste 6: 0.0 + (-8.0)", 32'hC0200000); // Esperado: 0.0

        // 7. Soma de negativos: -3.0 + (-2.0) = -5.0
        op_a = 32'hC0080000; // -3.0
        op_b = 32'hC0000000; // -2.0
        #300;
        mostra_resultado("Teste 7: -3.0 + (-2.0)", 32'hC0140000); // Esperado: -5.0

        // 8. Soma com overflow: max + max (overflow esperado)
        op_a = 32'h7FEFFFFF; // Maior valor positivo normalizado
        op_b = 32'h7FEFFFFF;
        #300;
        mostra_resultado("Teste 8: Overflow", 32'h7FF00000);      

        // 10. Underflow real (produto de dois subnormais mínimos) 
        op_a = 32'h00000001; // menor subnormal positivo (~2^-1042)
        op_b = 32'h00000001; // menor subnormal positivo (~2^-1042)
        #300;
        mostra_resultado("Teste 9: Underflow real", 32'h00000002); 
        
        // 10. Soma de frações: 2.5 + 2.5 = 5.0
        op_a = 32'h40040000; // 2.5 
        op_b = 32'h40040000; // 2.5
        #300;
        mostra_resultado("Teste 10: 2.5 + 2.5", 32'h40140000); // Esperado: 5.0
        $display("\nTestes finalizados.");
        #300;
        $stop;
    end

endmodule
