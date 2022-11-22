module Rename (
	clk,
	en,
	frontEn,
	rst,
	OUT_stall,
	IN_uop,
	IN_comUOp,
	IN_wbHasResult,
	IN_wbUOp,
	IN_branchTaken,
	IN_branchFlush,
	IN_branchSqN,
	IN_branchLoadSqN,
	IN_branchStoreSqN,
	IN_mispredFlush,
	OUT_uopValid,
	OUT_uop,
	OUT_uopOrdering,
	OUT_nextSqN,
	OUT_nextLoadSqN,
	OUT_nextStoreSqN
);
	parameter WIDTH_UOPS = 4;
	parameter WIDTH_WR = 4;
	input wire clk;
	input wire en;
	input wire frontEn;
	input wire rst;
	output reg OUT_stall;
	input wire [(WIDTH_UOPS * 67) - 1:0] IN_uop;
	input wire [(WIDTH_UOPS * 23) - 1:0] IN_comUOp;
	input wire [WIDTH_WR - 1:0] IN_wbHasResult;
	input wire [(WIDTH_WR * 88) - 1:0] IN_wbUOp;
	input wire IN_branchTaken;
	input wire IN_branchFlush;
	input wire [6:0] IN_branchSqN;
	input wire [6:0] IN_branchLoadSqN;
	input wire [6:0] IN_branchStoreSqN;
	input wire IN_mispredFlush;
	output reg [WIDTH_UOPS - 1:0] OUT_uopValid;
	output reg [(WIDTH_UOPS * 100) - 1:0] OUT_uop;
	output reg [WIDTH_UOPS - 1:0] OUT_uopOrdering;
	output wire [6:0] OUT_nextSqN;
	output reg [6:0] OUT_nextLoadSqN;
	output reg [6:0] OUT_nextStoreSqN;
	integer i;
	integer j;
	wire [(2 * WIDTH_UOPS) - 1:0] RAT_lookupAvail;
	wire [((2 * WIDTH_UOPS) * 7) - 1:0] RAT_lookupSpecTag;
	reg [((2 * WIDTH_UOPS) * 5) - 1:0] RAT_lookupIDs;
	reg [(WIDTH_UOPS * 5) - 1:0] RAT_issueIDs;
	reg [WIDTH_UOPS - 1:0] RAT_issueValid;
	reg [WIDTH_UOPS - 1:0] RAT_issueAvail;
	reg [6:0] RAT_issueSqNs [WIDTH_UOPS - 1:0];
	reg [WIDTH_UOPS - 1:0] commitValid;
	reg [WIDTH_UOPS - 1:0] commitValid_int;
	reg [(WIDTH_UOPS * 5) - 1:0] RAT_commitIDs;
	reg [(WIDTH_UOPS * 7) - 1:0] RAT_commitTags;
	wire [(WIDTH_UOPS * 7) - 1:0] RAT_commitPrevTags;
	reg [WIDTH_UOPS - 1:0] RAT_commitAvail;
	reg [(WIDTH_UOPS * 5) - 1:0] RAT_wbIDs;
	reg [(WIDTH_UOPS * 7) - 1:0] RAT_wbTags;
	reg [WIDTH_UOPS - 1:0] TB_issueValid;
	reg [6:0] nextCounterSqN;
	reg [6:0] counterSqN;
	always @(*) begin
		nextCounterSqN = counterSqN;
		for (i = 0; i < WIDTH_UOPS; i = i + 1)
			begin
				RAT_lookupIDs[((2 * i) + 0) * 5+:5] = IN_uop[(i * 67) + 34-:5];
				RAT_lookupIDs[((2 * i) + 1) * 5+:5] = IN_uop[(i * 67) + 29-:5];
			end
		for (i = 0; i < WIDTH_UOPS; i = i + 1)
			begin
				RAT_issueIDs[i * 5+:5] = IN_uop[(i * 67) + 23-:5];
				RAT_issueSqNs[i] = nextCounterSqN;
				RAT_issueValid[i] = ((((!rst && !IN_branchTaken) && en) && frontEn) && !OUT_stall) && IN_uop[i * 67];
				RAT_issueAvail[i] = IN_uop[(i * 67) + 12-:3] == 3'd6;
				TB_issueValid[i] = (RAT_issueValid[i] && (IN_uop[(i * 67) + 23-:5] != 0)) && (IN_uop[(i * 67) + 12-:3] != 3'd6);
				if (RAT_issueValid[i])
					nextCounterSqN = nextCounterSqN + 1;
				commitValid[i] = (IN_comUOp[i * 23] && (IN_comUOp[(i * 23) + 22-:5] != 0)) && (!IN_branchTaken || ($signed(IN_comUOp[(i * 23) + 10-:7] - IN_branchSqN) <= 0));
				commitValid_int[i] = commitValid[i];
				RAT_commitIDs[i * 5+:5] = IN_comUOp[(i * 23) + 22-:5];
				RAT_commitTags[i * 7+:7] = IN_comUOp[(i * 23) + 17-:7];
				RAT_commitAvail[i] = IN_comUOp[(i * 23) + 1];
				RAT_wbIDs[i * 5+:5] = IN_wbUOp[(i * 88) + 48-:5];
				RAT_wbTags[i * 7+:7] = IN_wbUOp[(i * 88) + 55-:7];
			end
	end
	reg [(WIDTH_UOPS * 7) - 1:0] newTags;
	RenameTable rt(
		.clk(clk),
		.rst(rst),
		.IN_mispred(IN_branchTaken),
		.IN_mispredFlush(IN_mispredFlush),
		.IN_lookupIDs(RAT_lookupIDs),
		.OUT_lookupAvail(RAT_lookupAvail),
		.OUT_lookupSpecTag(RAT_lookupSpecTag),
		.IN_issueValid(RAT_issueValid),
		.IN_issueIDs(RAT_issueIDs),
		.IN_issueTags(newTags),
		.IN_issueAvail(RAT_issueAvail),
		.IN_commitValid(commitValid),
		.IN_commitIDs(RAT_commitIDs),
		.IN_commitTags(RAT_commitTags),
		.IN_commitAvail(RAT_commitAvail),
		.OUT_commitPrevTags(RAT_commitPrevTags),
		.IN_wbValid(IN_wbHasResult),
		.IN_wbID(RAT_wbIDs),
		.IN_wbTag(RAT_wbTags)
	);
	reg [(WIDTH_UOPS * 6) - 1:0] TB_tags;
	reg [WIDTH_UOPS - 1:0] TB_tagsValid;
	always @(*)
		for (i = 0; i < WIDTH_UOPS; i = i + 1)
			if (TB_issueValid[i])
				newTags[i * 7+:7] = {1'b0, TB_tags[i * 6+:6]};
			else if (IN_uop[(i * 67) + 12-:3] == 3'd6)
				newTags[i * 7+:7] = {1'b1, IN_uop[(i * 67) + 40-:6]};
			else
				newTags[i * 7+:7] = 7'h40;
	reg [WIDTH_UOPS - 1:0] isNewestCommit;
	wire [WIDTH_UOPS * 6:1] sv2v_tmp_tb_OUT_issueTags;
	always @(*) TB_tags = sv2v_tmp_tb_OUT_issueTags;
	wire [WIDTH_UOPS:1] sv2v_tmp_tb_OUT_issueTagsValid;
	always @(*) TB_tagsValid = sv2v_tmp_tb_OUT_issueTagsValid;
	TagBuffer tb(
		.clk(clk),
		.rst(rst),
		.IN_mispr(IN_branchTaken),
		.IN_mispredFlush(IN_mispredFlush),
		.IN_issueValid(TB_issueValid),
		.OUT_issueTags(sv2v_tmp_tb_OUT_issueTags),
		.OUT_issueTagsValid(sv2v_tmp_tb_OUT_issueTagsValid),
		.IN_commitValid(commitValid_int),
		.IN_commitNewest(isNewestCommit),
		.IN_RAT_commitPrevTags(RAT_commitPrevTags),
		.IN_commitTagDst(RAT_commitTags)
	);
	always @(*) begin
		OUT_stall = 0;
		for (i = 0; i < WIDTH_UOPS; i = i + 1)
			if ((!TB_tagsValid[i] && IN_uop[i * 67]) && (IN_uop[(i * 67) + 23-:5] != 0))
				OUT_stall = 1;
	end
	reg intOrder;
	reg [6:0] counterStoreSqN;
	reg [6:0] counterLoadSqN;
	assign OUT_nextSqN = counterSqN;
	always @(*)
		for (i = 0; i < WIDTH_UOPS; i = i + 1)
			begin
				isNewestCommit[i] = IN_comUOp[i * 23] && (IN_comUOp[(i * 23) + 22-:5] != 0);
				if (IN_comUOp[i * 23])
					for (j = i + 1; j < WIDTH_UOPS; j = j + 1)
						if (IN_comUOp[j * 23] && (IN_comUOp[(j * 23) + 22-:5] == IN_comUOp[(i * 23) + 22-:5]))
							isNewestCommit[i] = 0;
			end
	always @(posedge clk) begin
		if (rst) begin
			counterSqN <= 0;
			counterStoreSqN = -1;
			counterLoadSqN = 0;
			OUT_nextLoadSqN <= counterLoadSqN;
			OUT_nextStoreSqN <= counterStoreSqN + 1;
			intOrder = 0;
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				begin
					OUT_uop[(i * 100) + 50-:7] <= i[6:0];
					OUT_uopValid[i] <= 0;
				end
		end
		else if (IN_branchTaken) begin
			counterSqN <= IN_branchSqN + 1;
			counterLoadSqN = IN_branchLoadSqN;
			counterStoreSqN = IN_branchStoreSqN;
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				OUT_uopValid[i] <= 0;
		end
		else if ((en && frontEn) && !OUT_stall) begin
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				begin
					OUT_uop[(i * 100) + 99-:32] <= IN_uop[(i * 67) + 66-:32];
					OUT_uop[(i * 100) + 31-:6] <= IN_uop[(i * 67) + 18-:6];
					OUT_uop[(i * 100) + 3-:3] <= IN_uop[(i * 67) + 12-:3];
					OUT_uop[(i * 100) + 36-:5] <= IN_uop[(i * 67) + 23-:5];
					OUT_uop[(i * 100) + 25-:5] <= IN_uop[(i * 67) + 9-:5];
					OUT_uop[(i * 100) + 20-:3] <= IN_uop[(i * 67) + 4-:3];
					OUT_uop[(i * 100) + 51] <= IN_uop[(i * 67) + 24];
					OUT_uop[i * 100] <= IN_uop[(i * 67) + 1];
				end
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				if (IN_uop[i * 67]) begin
					OUT_uopValid[i] <= 1;
					OUT_uop[(i * 100) + 10-:7] <= counterLoadSqN;
					OUT_uopOrdering[i] <= intOrder;
					case (IN_uop[(i * 67) + 12-:3])
						3'd0: intOrder = !intOrder;
						3'd4, 3'd5: intOrder = 1;
						3'd7, 3'd3: intOrder = 0;
						3'd2: counterStoreSqN = counterStoreSqN + 1;
						3'd1: counterLoadSqN = counterLoadSqN + 1;
						default:
							;
					endcase
					OUT_uop[(i * 100) + 50-:7] <= RAT_issueSqNs[i];
					OUT_uop[(i * 100) + 17-:7] <= counterStoreSqN;
					OUT_uop[(i * 100) + 66-:7] <= RAT_lookupSpecTag[((2 * i) + 0) * 7+:7];
					OUT_uop[(i * 100) + 58-:7] <= RAT_lookupSpecTag[((2 * i) + 1) * 7+:7];
					OUT_uop[(i * 100) + 67] <= RAT_lookupAvail[(2 * i) + 0];
					OUT_uop[(i * 100) + 59] <= RAT_lookupAvail[(2 * i) + 1];
					if (IN_uop[(i * 67) + 23-:5] != 0)
						OUT_uop[(i * 100) + 43-:7] <= newTags[i * 7+:7];
				end
				else
					OUT_uopValid[i] <= 0;
			counterSqN <= nextCounterSqN;
		end
		else if (!en)
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				OUT_uopValid[i] <= 0;
		if (!rst)
			for (i = 0; i < WIDTH_WR; i = i + 1)
				if ((en && (!frontEn || OUT_stall)) && IN_wbHasResult[i])
					for (j = 0; j < WIDTH_UOPS; j = j + 1)
						if (OUT_uopValid[j]) begin
							if (OUT_uop[(j * 100) + 66-:7] == IN_wbUOp[(i * 88) + 55-:7])
								OUT_uop[(j * 100) + 67] <= 1;
							if (OUT_uop[(j * 100) + 58-:7] == IN_wbUOp[(i * 88) + 55-:7])
								OUT_uop[(j * 100) + 59] <= 1;
						end
		OUT_nextLoadSqN <= counterLoadSqN;
		OUT_nextStoreSqN <= counterStoreSqN + 1;
	end
endmodule
