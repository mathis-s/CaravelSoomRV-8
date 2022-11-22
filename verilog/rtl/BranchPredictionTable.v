module BranchPredictionTable (
	clk,
	rst,
	IN_readAddr,
	OUT_taken,
	IN_writeEn,
	IN_writeAddr,
	IN_writeTaken
);
	parameter INDEX_LEN = 8;
	parameter NUM_COUNTERS = 1 << INDEX_LEN;
	input wire clk;
	input wire rst;
	input wire [INDEX_LEN - 1:0] IN_readAddr;
	output wire OUT_taken;
	input wire IN_writeEn;
	input wire [INDEX_LEN - 1:0] IN_writeAddr;
	input wire IN_writeTaken;
	integer i;
	reg [1:0] counters [NUM_COUNTERS - 1:0];
	assign OUT_taken = counters[IN_readAddr][1];
	always @(posedge clk)
		if (rst) begin
`ifdef __ICARUS__
			for (i = 0; i < NUM_COUNTERS; i = i + 1)
				counters[i] <= 2'b10;
`endif
		end
		else if (IN_writeEn)
			if (IN_writeTaken)
				counters[IN_writeAddr] <= (counters[IN_writeAddr] == 2'b11 ? 2'b11 : counters[IN_writeAddr] + 1);
			else
				counters[IN_writeAddr] <= (counters[IN_writeAddr] == 2'b00 ? 2'b00 : counters[IN_writeAddr] - 1);
endmodule
