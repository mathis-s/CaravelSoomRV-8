module IndirectBranchPredictor (
	clk,
	rst,
	IN_clearICache,
	IN_ibUpdates,
	OUT_predDst
);
	parameter NUM_UPDATES = 2;
	input wire clk;
	input wire rst;
	input wire IN_clearICache;
	input wire [(NUM_UPDATES * 63) - 1:0] IN_ibUpdates;
	output reg [30:0] OUT_predDst;
	integer i;
	always @(posedge clk)
		if (rst || IN_clearICache)
			OUT_predDst <= 0;
		else
			for (i = 0; i < NUM_UPDATES; i = i + 1)
				if (IN_ibUpdates[i * 63])
					OUT_predDst <= IN_ibUpdates[(i * 63) + 31-:31];
endmodule
