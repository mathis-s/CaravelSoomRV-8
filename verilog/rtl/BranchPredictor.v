module BranchPredictor (
	clk,
	rst,
	IN_clearICache,
	IN_mispredFlush,
	IN_branch,
	IN_pcValid,
	IN_pc,
	OUT_branchTaken,
	OUT_isJump,
	OUT_branchSrc,
	OUT_branchDst,
	OUT_branchHistory,
	OUT_branchInfo,
	OUT_multipleBranches,
	OUT_branchFound,
	OUT_branchCompr,
	IN_btUpdates,
	IN_bpUpdate
);
	parameter NUM_IN = 2;
	parameter NUM_ENTRIES = 32;
	parameter ID_BITS = 16;
	input wire clk;
	input wire rst;
	input wire IN_clearICache;
	input wire IN_mispredFlush;
	input wire [75:0] IN_branch;
	input wire IN_pcValid;
	input wire [31:0] IN_pc;
	output wire OUT_branchTaken;
	output wire OUT_isJump;
	output wire [31:0] OUT_branchSrc;
	output wire [31:0] OUT_branchDst;
	output wire [15:0] OUT_branchHistory;
	output wire [8:0] OUT_branchInfo;
	output wire OUT_multipleBranches;
	output wire OUT_branchFound;
	output wire OUT_branchCompr;
	input wire [(NUM_IN * 67) - 1:0] IN_btUpdates;
	input wire [58:0] IN_bpUpdate;
	integer i;
	reg [15:0] gHistory;
	reg [15:0] gHistoryCom;
	reg [66:0] btUpdate;
	always @(*) begin
		btUpdate = 67'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		btUpdate[0] = 0;
		for (i = 0; i < NUM_IN; i = i + 1)
			if (IN_btUpdates[i * 67])
				btUpdate = IN_btUpdates[i * 67+:67];
	end
	wire [30:0] branchAddr = IN_pc[31:1];
	assign OUT_branchHistory = gHistory;
	assign OUT_branchInfo[8] = OUT_branchFound;
	assign OUT_branchInfo[7] = OUT_branchTaken;
	assign OUT_branchInfo[0] = OUT_isJump;
	wire tageTaken;
	assign OUT_branchTaken = OUT_branchFound && (OUT_isJump ? 1 : tageTaken);
	assign OUT_branchDst[0] = 1'b0;
	assign OUT_branchSrc[0] = 1'b0;
	BranchTargetBuffer btb(
		.clk(clk),
		.rst(rst || IN_clearICache),
		.IN_pcValid(IN_pcValid),
		.IN_pc(IN_pc[31:1]),
		.OUT_branchFound(OUT_branchFound),
		.OUT_branchDst(OUT_branchDst[31:1]),
		.OUT_branchSrc(OUT_branchSrc[31:1]),
		.OUT_branchIsJump(OUT_isJump),
		.OUT_branchCompr(OUT_branchCompr),
		.OUT_multipleBranches(OUT_multipleBranches),
		.IN_BPT_branchTaken(OUT_branchTaken),
		.IN_btUpdate(btUpdate)
	);
	TagePredictor tagePredictor(
		.clk(clk),
		.rst(rst),
		.IN_predAddr(branchAddr),
		.IN_predHistory(gHistory),
		.OUT_predTageID(OUT_branchInfo[6-:3]),
		.OUT_predUseful(OUT_branchInfo[3-:3]),
		.OUT_predTaken(tageTaken),
		.IN_writeValid((IN_bpUpdate[0] && IN_bpUpdate[26]) && !IN_mispredFlush),
		.IN_writeAddr(IN_bpUpdate[58:28]),
		.IN_writeHistory(IN_bpUpdate[17-:16]),
		.IN_writeTageID(IN_bpUpdate[24-:3]),
		.IN_writeTaken(IN_bpUpdate[1]),
		.IN_writeUseful(IN_bpUpdate[21-:3]),
		.IN_writePred(IN_bpUpdate[25])
	);
	always @(posedge clk) begin
		if (rst) begin
			gHistory <= 0;
			gHistoryCom <= 0;
		end
		else begin
			if (OUT_branchFound && !OUT_isJump)
				gHistory <= {gHistory[14:0], OUT_branchTaken};
			if (IN_bpUpdate[0] && !IN_mispredFlush)
				gHistoryCom <= {gHistoryCom[14:0], IN_bpUpdate[1]};
		end
		if (!rst && IN_branch[0])
			gHistory <= IN_branch[16-:16];
	end
endmodule
