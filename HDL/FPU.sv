module FPU (

input logic clock_100k,
input logic reset,
input logic [31:0] op_a,
input logic [31:0] op_b,

output logic [31:0] data_out,
output logic [3:0] status_out,

);

logic [19:0] mant_a, mant_b, mant_r, mant_s; // 20bits (19:0)
logic [10:0] exp_a, exp_b, exp_r, dif;   // 11 bits (30:20)
logic [2:0]  rounding_bits;
logic sign_a, sign_b, sign_r;        // 1 bit (31)

typedef enum {DIVIDE, PRE_ADD, ADD, NORMALIZER, ROUNDING, OUTPUT_RESULT} statetype;
statetype states;


always @ (posedge clock_100k or negedge reset) begin 
    if (!reset) begin

        op_a       <= 32'd0;
        op_b       <= 32'd0;
        data_out   <= 32'd0;
        status_out <= 4'd0;

        mant_a     <= 20'd0;
        exp_a      <= 10'd0;
        sign_a     <= 1'd0;
  
  
        mant_b     <= 20'd0;
        exp_b      <= 10'd0;
        sign_b     <= 1'd0;
            
        mant_r     <= 20'd0;
        exp_r      <= 10'd0;
        sign_r     <= 1'd0;
    
        dif        <= 10'd0;

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

            end else if (exp_a > exp_b) begin        //se o expoente a for maior que b, então faz a diferença dos expoentes e usa esse expoente na soma e shifta a menor mantissa(b) 
                    dif <= (exp_a - exp_b); 
                    mant_b <= mant_b >> (exp_a - exp_b); 
                    exp_b = exp_a;
                    exp_r <= exp_b;
                    
            end else begin
                    //se o expoente b for maior que a, então faz a diferença dos expoentes e usa esse expoente na soma e shifta a menor mantissa(a)
                    dif <= (exp_b - exp_a);
                    mant_a <= mant_a >> (exp_b - exp_a);
                    exp_a = exp_b;
                    exp_r <= exp_a;
                    end
                states <= ADD;
                end

        ADD: begin
        if (sign_a == sign_b) begin
            mant_r <= mant_a + mant_b;
            sign_r <= sign_a;   

        end else if (sign_a > sign_b) begin
            mant_r <= mant_a - mant_b;
            sign_r <= sign_a;

        end else begin
            mant_r <= mantb - mant_a;
            sign_r <= sign_b;
        end
            states <= NORMALIZER;

    end

        NORMALIZER: begin
            if(mant_r[20] == 1'b1 ) begin
               mant_r <= mant_r >> 1;
               exp_r  <= exp_r + 1;
               rounding_bits <= {mant_r[0], 1'b0, 1'b0};
                
            end else begin
                while (mant_r[19] != 1'b1 && exp_r > 0) begin
                mant_r = mant_r << 1;
                exp_r = exp_r - 1;
                end
                rounding_bits <= 3'b000;
            end
            state <= ROUNDING;
        end
        
       ROUNDING: begin
                    // Checagem de bits de arredondamento para INEXACT
                    if (rounding_bits != 3'b000)
                        inex_flag <= 1;
                    else
                        exct_flag <= 1;

                    // Checar overflow e underflow
                    if (exp_r > 11'd2046) // limite para 11 bits
                        ov_flag <= 1;
                    else if (exp_r == 0 && mant_r != 0)
                        und_flag <= 1;
                    state <= OUTPUT_RESULT;
                end

                OUTPUT_RESULT: begin
                    data_out <= {sign_r, exp_r, mant_r[18:0]};
                    status_out <= 4'b0000;
                    if (exct_flag) status_out[3] <= 1'b1;
                    if (ov_flag)   status_out[2] <= 1'b1;
                    if (und_flag)  status_out[1] <= 1'b1;
                    if (inex_flag) status_out[0] <= 1'b1;
                    state <= DIVIDE; // reinicia para próxima operação
                end
            endcase
        end
    end
endmodule
