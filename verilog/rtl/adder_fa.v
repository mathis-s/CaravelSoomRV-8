 
module Adder
#(parameter SIZE=32)
(
    input wire clk,
    input wire[SIZE-1:0] a,
    input wire[SIZE-1:0] b,
    output reg[SIZE-1:0] out
);

wire[SIZE-1:0] outComb;
wire[SIZE:0] carryChain;
assign carryChain[0] = 0;

generate
    genvar i;
    for (i = 0; i < SIZE; i=i+1) begin
        sky130_fd_sc_hd__fa_1 add (.COUT(carryChain[i+1]), .SUM(outComb[i]), .A(a[i]), .B(b[i]), .CIN(carryChain[i]));
    end
endgenerate

always @(posedge clk) begin
    out <= outComb;
end


endmodule
