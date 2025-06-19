module FPU (
    input  logic        clock_100k,
    input  logic        reset,       // reset assíncrono ativo em nível baixo
    input  logic [31:0] op_a,
    input  logic [31:0] op_b,
    output logic [31:0] data_out,
    output logic [3:0]  status_out  // [3] EXACT, [2] OVERFLOW, [1] UNDERFLOW, [0] INEXACT
);

    // Campos dos operandos
    logic        sign_a, sign_b, sign_r;
    logic [10:0] exp_a, exp_b, exp_r;
    logic [20:0] mant_a, mant_b, mant_r;

    // Variáveis pipeline
    logic [20:0] mant_add;
    logic        sign_add;
    logic [10:0] exp_next;

    // Status
    logic ov_flag, und_flag, inex_flag, exct_flag;

    typedef enum logic [3:0] { DIVIDE, PRE_ADD, WAIT_PRE_ADD, ADD, WAIT_ADD, NORMALIZER, ROUNDING, OUTPUT_RESULT } statetype;
    statetype states;

    always_ff @(posedge clock_100k or negedge reset) begin
        if (!reset) begin
            data_out   <= 32'd0;
            status_out <= 4'd0;
            mant_a     <= 21'd0;
            exp_a      <= 11'd0;
            sign_a     <= 1'b0;

            mant_b     <= 21'd0;
            exp_b      <= 11'd0;
            sign_b     <= 1'b0;

            mant_r     <= 21'd0;
            exp_r      <= 11'd0;
            sign_r     <= 1'b0;

            mant_add   <= 21'd0;
            sign_add   <= 1'b0;
            exp_next   <= 11'd0;

            ov_flag    <= 1'b0;
            und_flag   <= 1'b0;
            inex_flag  <= 1'b0;
            exct_flag  <= 1'b0;

            states <= DIVIDE;
        end else begin
            case (states)
                DIVIDE: begin
                    $display("entrei no divide");
                    $display("---------------------------------------------------");
                    sign_a <= op_a[31];
                    sign_b <= op_b[31];
                    exp_a  <= op_a[30:20];
                    exp_b  <= op_b[30:20];
                    mant_a <= (op_a[30:20] != 0) ? {1'b1, op_a[19:0]} : {1'b0, op_a[19:0]};
                    mant_b <= (op_b[30:20] != 0) ? {1'b1, op_b[19:0]} : {1'b0, op_b[19:0]};
                    ov_flag    <= 1'b0;
                    und_flag   <= 1'b0;
                    inex_flag  <= 1'b0;
                    exct_flag  <= 1'b0;
                   $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                   $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                   $display("---------------------------------------------------");
                    states <= PRE_ADD;
                end

                PRE_ADD: begin
                    $display("entrei no pre_add");
                    $display("---------------------------------------------------");
                    if (exp_a == exp_b) begin
                        exp_next <= exp_a;
                    end else if (exp_a > exp_b) begin
                        mant_b <= mant_b >> (exp_a - exp_b);
                        exp_next <= exp_a;
                    end else begin
                        mant_a <= mant_a >> (exp_b - exp_a);
                        exp_next <= exp_b;
                    end
                    $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                   $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                   $display("---------------------------------------------------");
                    states <= WAIT_PRE_ADD;
                end

                WAIT_PRE_ADD: begin
                    $display("entrei no wait_pre_add");
                    $display("---------------------------------------------------");
                    exp_r <= exp_next;
                     $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                   $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                   $display("---------------------------------------------------");
                    states <= ADD;
                end

                ADD: begin
                    $display("entrei no add");
                    $display("---------------------------------------------------");
                    if (sign_a == sign_b) begin
                        mant_add <= (mant_a + mant_b);
                        sign_add <= sign_a;
                    end else if (mant_a >= mant_b) begin
                        mant_add <= (mant_a - mant_b);
                        sign_add <= sign_a;
                    end else begin
                        mant_add <= (mant_b - mant_a);
                        sign_add <= sign_b;
                    end
                     $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                   $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                   $display("---------------------------------------------------");
                    states <= WAIT_ADD;
                end

                WAIT_ADD: begin
                    $display("entrei no wait_add");
                    $display("---------------------------------------------------");
                    mant_r <= mant_add;
                    sign_r <= sign_add;
                     $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                   $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                   $display("---------------------------------------------------");
                    states <= NORMALIZER;
                end

                NORMALIZER: begin
                    $display("entrei no normalizer");
                    $display("---------------------------------------------------");
                    if (mant_r[21]) begin
                        inex_flag <= inex_flag | mant_r[0];
                        mant_r <= mant_r >> 1;
                        exp_r  <= exp_r + 1;
                    $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                    $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                    $display("---------------------------------------------------");
                        states <= ROUNDING;
                       
                    end else if (!mant_r[20] && exp_r > 0 && mant_r != 0) begin
                        mant_r <= mant_r << 1;
                        exp_r  <= exp_r - 1;
                    $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                    $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                    $display("---------------------------------------------------");
                        states <= ROUNDING;
                    end else begin
                        ov_flag   <= (exp_r > 11'd2046);
                        und_flag  <= (exp_r == 0 && mant_r[19:0] != 0);
                        exct_flag <= ~inex_flag;
                        $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                        $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                        $display("---------------------------------------------------");
                        states <= ROUNDING;
                    end
                end
                ROUNDING: begin
                    $display("entrei no rounding");
                    $display("---------------------------------------------------");
                    if (ov_flag) begin
                        exp_r  <= 11'd2046;
                        mant_r <= 21'd0;
                    end
                    status_out <= {exct_flag, ov_flag, und_flag, inex_flag};
                     $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                     $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                     $display("---------------------------------------------------");
                    states <= OUTPUT_RESULT;
                end

                OUTPUT_RESULT: begin
                    $display("entrei no output_result");
                    $display("---------------------------------------------------");
                    $display("DEBUG: sign=%b exp=%h mant=%h", sign_a, exp_a, mant_a);
                   $display("DEBUG: sign=%b exp=%h mant=%h", sign_b, exp_b, mant_b);
                    $display("DEBUG: sign=%b exp=%h mant=%h", sign_r, exp_r, mant_r);
                    $display("---------------------------------------------------");
                    data_out <= {sign_r, exp_r, mant_r[19:0]};
                    $display("DEBUG: sign=%b exp=%h mant=%h", sign_r, exp_r, mant_r);
                    $display("---------------------------------------------------");
                    $display("terminei");
                    $display("---------------------------------------------------");
                    states <= DIVIDE;
                end

            endcase
        end
    end

endmodule
