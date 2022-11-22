 
module Adder
#(parameter SIZE=64)
(
    input wire clk,
    input wire[SIZE-1:0] a,
    input wire[SIZE-1:0] b,
    output reg[SIZE-1:0] out
);

always @(posedge clk) begin
    out <= a + b;
end


endmodule
