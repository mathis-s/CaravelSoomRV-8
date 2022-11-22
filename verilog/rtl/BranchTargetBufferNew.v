module BranchTargetBuffer (
	clk,
	rst,
	IN_pcValid,
	IN_pc,
	OUT_branchFound,
	OUT_branchDst,
	OUT_branchSrc,
	OUT_branchIsJump,
	OUT_branchCompr,
	OUT_multipleBranches,
	IN_BPT_branchTaken,
	IN_btUpdate
);
	parameter NUM_ENTRIES = 32;
	parameter ASSOC = 4;
	input wire clk;
	input wire rst;
	input wire IN_pcValid;
	input wire [30:0] IN_pc;
	output reg OUT_branchFound;
	output reg [30:0] OUT_branchDst;
	output reg [30:0] OUT_branchSrc;
	output reg OUT_branchIsJump;
	output reg OUT_branchCompr;
	output reg OUT_multipleBranches;
	input wire IN_BPT_branchTaken;
	input wire [66:0] IN_btUpdate;
	localparam LENGTH = NUM_ENTRIES / ASSOC;
	integer i;
	integer j;
	reg [(ASSOC * 66) - 1:0] entries [LENGTH - 1:0];
	reg [$clog2(ASSOC) - 1:0] usedID;
	always @(*) begin : sv2v_autoblock_1
		reg [(ASSOC * 66) - 1:0] fetched;
		fetched = entries[IN_pc[$clog2(LENGTH) + 1:2]];
		OUT_branchFound = 0;
		OUT_multipleBranches = 0;
		OUT_branchDst = 31'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		OUT_branchIsJump = 0;
		OUT_branchCompr = 0;
		OUT_branchSrc = 31'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		usedID = 0;
		if (IN_pcValid)
			for (i = 0; i < ASSOC; i = i + 1)
				if (((fetched[(i * 66) + 62] && (fetched[(i * 66) + 30-:29] == IN_pc[30:2])) && (fetched[(i * 66) + 1-:2] >= IN_pc[1:0])) && (!OUT_branchFound || (fetched[(i * 66) + 1-:2] < OUT_branchSrc[1:0]))) begin
					if (OUT_branchFound)
						OUT_multipleBranches = 1;
					OUT_branchFound = 1;
					OUT_branchIsJump = fetched[(i * 66) + 65];
					OUT_branchDst = fetched[(i * 66) + 61-:31];
					OUT_branchSrc = fetched[(i * 66) + 30-:31];
					OUT_branchCompr = fetched[(i * 66) + 64];
					usedID = i[$clog2(ASSOC) - 1:0];
				end
	end
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < LENGTH; i = i + 1)
				for (j = 0; j < ASSOC; j = j + 1)
					entries[i][(j * 66) + 62] <= 0;
		end
		else begin
			if (IN_btUpdate[0]) begin : sv2v_autoblock_2
				reg inserted;
				inserted = 0;
				for (i = 0; i < ASSOC; i = i + 1)
					if (!inserted && !entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 62]) begin
						inserted = 1;
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 62] <= 1;
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 63] <= 0;
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 64] <= IN_btUpdate[1];
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 65] <= IN_btUpdate[2];
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 61-:31] <= IN_btUpdate[34:4];
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 30-:31] <= IN_btUpdate[66:36];
					end
					else if (!inserted)
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 63] <= 0;
				for (i = 0; i < ASSOC; i = i + 1)
					if (!inserted && !entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 63]) begin
						inserted = 1;
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 62] <= 1;
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 63] <= 0;
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 64] <= IN_btUpdate[1];
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 65] <= IN_btUpdate[2];
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 61-:31] <= IN_btUpdate[34:4];
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 30-:31] <= IN_btUpdate[66:36];
					end
					else if (!inserted)
						entries[IN_btUpdate[35 + ($clog2(LENGTH) + 2):38]][(i * 66) + 63] <= 0;
			end
			if ((IN_pcValid && OUT_branchFound) && (IN_BPT_branchTaken || OUT_branchIsJump))
				entries[IN_pc[$clog2(LENGTH) + 1:2]][(usedID * 66) + 63] <= 1;
		end
endmodule
