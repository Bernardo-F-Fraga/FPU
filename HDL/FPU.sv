module FPU (
    input  logic        clock_100k,
    input  logic        reset,
    input  logic [31:0] op_a,
    input  logic [31:0] op_b,
    output logic [31:0] data_out,
    output logic [3:0]  status_out // [3] EXACT, [2] OVERFLOW, [1] UNDERFLOW, [0] INEXACT
);


    typedef enum logic [2:0] {
        DIVIDE, PRE_ADD, ADD, POS_ADD, NORMALIZER, OUTPUT_RESULT
    } statetype;
    statetype states;

    logic sign_a, sign_b, sign_r; //sinais (1 bit)
    logic sign_large, sign_small; // auxiliares dos sinais
    logic [10:0] exp_a, exp_b, exp_r; //expoentes (11 bits)
    logic [10:0] exp_diff, norm_exp; //auxiliares do expoente
    logic [20:0] mant_a, mant_b, mant_r; // mantissas (20 bits + 1 bit implícito)
    logic [20:0] mant_large, mant_small, norm_mant; // mantissas auxiliares
    logic [22:0] mant_add; // mantissa auxiliar da soma
    logic ov_flag, und_flag, inex_flag, exct_flag, zero_result; // flags overflow, underflow, exact, inexact e resultado zero
 
    always_ff @(posedge clock_100k or negedge reset) begin
        if (!reset) begin
            data_out   <= 32'd0;
            status_out <= 4'd0;
            sign_a <= 1'b0; exp_a <= 11'd0; mant_a <= 21'd0;
            sign_b <= 1'b0; exp_b <= 11'd0; mant_b <= 21'd0;
            sign_r <= 1'b0; exp_r <= 11'd0; mant_r <= 21'd0; mant_add <= 22'd0;
            ov_flag <= 1'b0; und_flag <= 1'b0; inex_flag <= 1'b0; exct_flag <= 1'b0; zero_result<= 1'b0;
            states     <= DIVIDE;
        end else begin
            case (states)
                DIVIDE: begin
                    sign_a <= op_a[31];
                    sign_b <= op_b[31];
                    exp_a  <= op_a[30:20];
                    exp_b  <= op_b[30:20];
                    mant_a <= (op_a[30:20] != 0) ? {1'b1, op_a[19:0]} : {1'b0, op_a[19:0]};
                    mant_b <= (op_b[30:20] != 0) ? {1'b1, op_b[19:0]} : {1'b0, op_b[19:0]};
                    states     <= PRE_ADD;
                end

                PRE_ADD: begin
                    if (exp_a > exp_b) begin
                        exp_diff    = exp_a - exp_b;
                        exp_r  <= exp_a;
                        mant_large  <= mant_a;
                        sign_large  <= sign_a;
                        mant_small  = mant_b >> exp_diff;
                        sign_small  <= sign_b;
                        inex_flag   = (exp_diff > 0) ? |(mant_b & ((1 << exp_diff) - 1)) : 1'b0;
                    end else if (exp_b > exp_a) begin
                        exp_diff    = exp_b - exp_a;
                        exp_r   <= exp_b;
                        mant_large  <= mant_b;
                        sign_large  <= sign_b;
                        mant_small  = mant_a >> exp_diff;
                        sign_small  <= sign_a;
                        inex_flag   = (exp_diff > 0) ? |(mant_a & ((1 << exp_diff) - 1)) : 1'b0;
                    end else begin
                            if (mant_a >= mant_b) begin
                                exp_r       <= exp_a;
                                mant_large  <= mant_a;
                                sign_large  <= sign_a;
                                mant_small  <= mant_b;
                                sign_small  <= sign_b;
                            end else begin
                                exp_r       <= exp_b;
                                mant_large  <= mant_b;
                                sign_large  <= sign_b;
                                mant_small  <= mant_a;
                                sign_small  <= sign_a;
                            end
                        inex_flag = 1'b0;
                    end
                        states <= ADD;
                end
                
                ADD: begin
                    if (sign_a == sign_b ) begin
                        mant_add <= {1'b0, mant_a} + {1'b0, mant_b};
                        sign_r <= sign_a;
                    end else if (mant_large > mant_small) begin
                            mant_add <= {1'b0, mant_large} - {1'b0, mant_small}; 
                            sign_r <= sign_large;
                        end else if (mant_large < mant_small) begin
                            mant_add <= {1'b0, mant_small} - {1'b0, mant_large};
                            sign_r <= sign_small;
                        end else begin 
                            mant_add <= 22'd0;
                            sign_r <= 1'b0;
                        end
                    
                    states <= POS_ADD;
                end
                
                POS_ADD: begin
                    mant_r <= mant_add[20:0];
                    if (mant_add[20:0] == 0) begin
                        sign_r <= 1'b0;
                        zero_result <= 1'b1;
                    end else begin
                        zero_result <= 1'b0;
                    end
                    states <= NORMALIZER;
                end

                NORMALIZER: begin
                    norm_exp = exp_r;
                    norm_mant = mant_r;
                    if (sign_large == sign_small && mant_add[21]) begin 
                        norm_exp = exp_r + 1;
                        norm_mant = mant_add[21:1];
                    end else if (norm_mant != 0) begin
                        for (int i = 20; i > 0 && norm_mant[20] == 1'b0; i--) begin
                            norm_mant = norm_mant << 1;
                            norm_exp = norm_exp - 1;
                        end
                    end
                    mant_r <= norm_mant;
                    exp_r  <= (norm_mant == 0) ? 11'd0 : norm_exp;
                    ov_flag   <= (norm_exp >= 11'd2047);
                    und_flag  <= (norm_exp == 0 && norm_mant != 0);
                    exct_flag <= ~inex_flag & ~(ov_flag | und_flag);
                    zero_result <= (norm_mant == 0);
                    states <= OUTPUT_RESULT;
                end

                OUTPUT_RESULT: begin
                    if (zero_result) begin
                        data_out <= 32'd0;
                    end else if (ov_flag) begin
                        data_out <= {sign_r, 11'h7ff, 20'd0};
                    end else begin
                        data_out <= {sign_r, exp_r[10:0], mant_r[19:0]};
                    end
                    status_out <= {exct_flag, ov_flag, und_flag, inex_flag};
                    states <= DIVIDE;
                end
            endcase
        end
    end
endmodule
