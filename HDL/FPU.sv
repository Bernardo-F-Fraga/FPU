module FPU (

input logic clock_100k,
input logic reset,
input logic [31:0] op_a,
input logic [31:0] op_b,

output logic [31:0] data_out,
output logic [3:0] status_out,

);

reg [19:0] mant_a, mant_b, mant_r, mant_s; // 20bits (19:0)
reg [10:0] exp_a, exp_b, exp_r, dif;   // 11 bits (30:20)
reg sign_a, sign_b, sign_r;        // 1 bit (31)
reg ov_flag, und_flag, inex_flag, ex_flag; // flags

typedef enum {DIVIDE, PRE_ADD, ADD, NORMALIZER, SO, OVERFLOW, UNDERFLOW, INEXECT, EXACT} statetype;
statetype states;


always @ (posedge clock_100k) begin 
    if (reset) begin

        op_a       <= 32'd0;
        op_b       <= 32'd0;
        data_out   <= 32'd0;
        status_out <= 4'd0;

        mant_a     <= 20'd0;
        exp_a      <= 11'd0;
        sign_a     <= 1'd0;
  
  
        mant_b     <= 20'd0;
        exp_b      <= 11'd0;
        sign_b     <= 1'd0;
            
        mant_r     <= 20'd0;
        exp_r      <= 11'd0;
        sign_r     <= 1'd0;
    
        dif        <= 11'd0;
        ov_flag    
        und_flag
        inex_flag
        ex_flag
        

        states <= DIVIDE;
    end else begin 
        case (states)

        DIVIDE: begin
            sign_a <= op_a[31];
            sign_b <= op_b[31];

            exp_a <= op_a [30:20];
            exp_b <= op_b [30:20];
            

            mant_a <= op_a [19:0];
            mant_b <= op_b [19:0];

            states <= PRE_ADD;
        end

        PRE_ADD: begin
            //se os expoentes forem iguais, então vai direto para soma
            if(exp_a == exp_b) begin
                exp_r <= exp_a;
                states <= ADD;

            end else begin
                //se o expoente a for maior que b, então faz a diferença dos expoentes e usa esse expoente na soma e shifta a menor mantissa(b) 
                if (exp_a > exp_b) begin
                    dif <= (exp_a - exp_b); 
                    mant_b <= mant_b >> (exp_a - exp_b); 
                    exp_b = exp_a;
                    exp_r <= exp_b;
                    states <= ADD;

                end else begin
                    //se o expoente b for maior que a, então faz a diferença dos expoentes e usa esse expoente na soma e shifta a menor mantissa(a)
                    if (exp_b > exp_a) begin
                        mant_a <= mant_a >> (exp_b - exp_a);
                        exp_a = exp_b;
                        states <= ADD;

                    end
                end
            end
        end 

        ADD: begin
        if (sign_a == sign_b) begin
            mant_r <= mant_a + mant_b;
            sign_r <= sign_a;
            states <= SO;      

        end else begin
            if (sign_a > sign_b) begin
            mant_r <= mant_a - mant_b;
            sign_r <= sign_a;
            states <= NORMALIZER;
            end

        end else begin
            if(sign_b > sign_a) begin
            mant_r <= mantb - mant_a;
            sign_r <= sign_b;
            states <= NORMALIZER;
            end
        end

    end

        NORMALIZER: begin
            if(mant_r[20] == 1'b1 ) begin
                mant_r <= mant_r >> dif;
                exp_r  <= exp_r + dif;
                states <= SO;
            end else begin
                while (mantissa_result[23] != 1'b1 && expoente_result > 0) begin
                mantissa_result = mantissa_result << 1;
                 expoente_result = expoente_result - 1;
                 states <= SO;
            end
        end
        
        SO: begin
            if (expoente_result > 8'd254) begin
            status_out[2] = 1'b1;  // OVERFLOW
            end else begin
                if (expoente_result < 8'd1 && mantissa_result != 0) begin
                status_out[1] = 1'b1;  // UNDERFLOW
                end
            end else begin
                    if (guard_bit == 1'b1 || round_bit == 1'b1 || sticky_bit == 1'b1) begin
                    status_out[0] = 1'b1;  // INEXACT
                    end
            end else begin    
                    if (status_out == 4'b0000) begin
                    status_out[3] = 1'b1;  // EXACT
                    end
            end

        end


    end
end
endmodule