module BranchSelector (
	clk,
	rst,
	IN_branches,
	OUT_branch,
	IN_ROB_curSqN,
	IN_RN_nextSqN,
	IN_mispredFlush
);
	parameter NUM_BRANCHES = 4;
	input wire clk;
	input wire rst;
	input wire [(NUM_BRANCHES * 76) - 1:0] IN_branches;
	output reg [75:0] OUT_branch;
	input wire [6:0] IN_ROB_curSqN;
	input wire [6:0] IN_RN_nextSqN;
	input wire IN_mispredFlush;
	integer i;
	reg [6:0] mispredFlushSqN;
	reg disableMispredFlush;
	always @(*) begin
		OUT_branch[0] = 0;
		OUT_branch = 0;
		for (i = 0; i < 3; i = i + 1)
			if ((IN_branches[i * 76] && (!OUT_branch[0] || ($signed(IN_branches[(i * 76) + 43-:7] - OUT_branch[43-:7]) < 0))) && (!IN_mispredFlush || ($signed(IN_branches[(i * 76) + 43-:7] - mispredFlushSqN) < 0))) begin
				OUT_branch[0] = 1;
				OUT_branch[75-:32] = IN_branches[(i * 76) + 75-:32];
				OUT_branch[43-:7] = IN_branches[(i * 76) + 43-:7];
				OUT_branch[29-:7] = IN_branches[(i * 76) + 29-:7];
				OUT_branch[36-:7] = IN_branches[(i * 76) + 36-:7];
				if (i == 3)
					OUT_branch[22] = IN_branches[(i * 76) + 22];
				OUT_branch[21-:5] = IN_branches[(i * 76) + 21-:5];
				OUT_branch[16-:16] = IN_branches[(i * 76) + 16-:16];
			end
		if (IN_branches[228] && (!IN_mispredFlush || ($signed(IN_branches[271-:7] - mispredFlushSqN) < 0))) begin
			OUT_branch[0] = 1;
			OUT_branch[75-:32] = IN_branches[303-:32];
			OUT_branch[43-:7] = IN_branches[271-:7];
			OUT_branch[29-:7] = IN_branches[257-:7];
			OUT_branch[36-:7] = IN_branches[264-:7];
			OUT_branch[22] = IN_branches[250];
			OUT_branch[21-:5] = IN_branches[249-:5];
			OUT_branch[16-:16] = IN_branches[244-:16];
		end
	end
	always @(posedge clk)
		if (rst) begin
			mispredFlushSqN <= 0;
			disableMispredFlush <= 0;
		end
		else if (OUT_branch[0])
			mispredFlushSqN <= OUT_branch[43-:7];
endmodule
