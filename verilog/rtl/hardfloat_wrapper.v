module hardfloat_wrapper
(
    input wire clk,

    input wire[32:0] a,
    input wire[32:0] b,
    input wire[32:0] c,

    /*output wire[9:0] OUT_sExp,
    output wire[26:0] OUT_sig,
    output wire OUT_invalidExc, 
    output wire OUT_isNaN, 
    output wire OUT_isInf, 
    output wire OUT_isZero, 
    output wire OUT_sign*/
    output reg[31:0] OUT_res
);

//wire[32:0] res;
wire[31:0] res;
/*mulAddRecFN fma
(
    .control(0),
    .op(0),
    .a(a),
    .b(b),
    .c(c),
    .roundingMode(3'b0),
    .out(res),
    .exceptionFlags()
);*/

/*mulRecFN#(.expWidth(8), .sigWidth(24)) add
(
    .control(0),
    //.subOp(c[0]),
    .a(a),
    .b(b),
    .roundingMode(0),
    .out(res),
    .exceptionFlags()
);*/

/*wire invalidExc, out_isNaN, out_isInf, out_isZero, out_sign;
reg invalidExc_reg, out_isNaN_reg, out_isInf_reg, out_isZero_reg, out_sign_reg;

wire signed [(8 + 1):0] out_sExp;
reg signed [(8 + 1):0] out_sExp_reg;
wire [(24 + 2):0] out_sig;
reg [(24 + 2):0] out_sig_reg;

mulAddRecFNToRaw#(8, 24)
    mul(
        control,
        2'b0,
        a,
        b,
        c,
        3'b0,
        invalidExc,
        out_isNaN,
        out_isInf,
        out_isZero,
        out_sign,
        out_sExp,
        out_sig
    );*/

recFNToFN#(8, 24) rec
(
    .in(a),
    .out(res)

);
always@(posedge clk) begin
    OUT_res <= res;
end

/*always@(posedge clk) begin
    out_sExp_reg <= out_sExp;
    out_sig_reg <= out_sig;
    invalidExc_reg <= invalidExc;
    out_isNaN_reg <= out_isNaN;
    out_isInf_reg <= out_isInf;
    out_isZero_reg <= out_isZero;
    out_sign_reg  <= out_sign;
end

assign OUT_sExp = out_sExp_reg;
assign OUT_sig = out_sig_reg;
assign invalidExc = invalidExc_reg;
assign OUT_isNaN = out_isNaN_reg;
assign OUT_isInf = out_isInf_reg;
assign OUT_isZero = out_isZero_reg;
assign OUT_sign = out_sign_reg;*/

endmodule