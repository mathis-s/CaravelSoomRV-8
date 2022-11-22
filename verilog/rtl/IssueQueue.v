module IssueQueue (
	clk,
	rst,
	frontEn,
	IN_stall,
	IN_doNotIssueFU1,
	IN_doNotIssueFU2,
	IN_uopValid,
	IN_uop,
	IN_uopOrdering,
	IN_resultValid,
	IN_resultUOp,
	IN_loadForwardValid,
	IN_loadForwardTag,
	IN_branch,
	IN_issueValid,
	IN_issueUOps,
	IN_maxStoreSqN,
	IN_maxLoadSqN,
	OUT_valid,
	OUT_uop,
	OUT_full
);
	parameter SIZE = 8;
	parameter NUM_UOPS = 4;
	parameter RESULT_BUS_COUNT = 4;
	parameter IMM_BITS = 32;
	parameter FU0 = 3'd2;
	parameter FU1 = 3'd2;
	parameter FU2 = 3'd2;
	parameter FU0_SPLIT = 0;
	parameter FU0_ORDER = 0;
	parameter FU1_DLY = 0;
	input wire clk;
	input wire rst;
	input wire frontEn;
	input wire IN_stall;
	input wire IN_doNotIssueFU1;
	input wire IN_doNotIssueFU2;
	input wire [NUM_UOPS - 1:0] IN_uopValid;
	input wire [(NUM_UOPS * 100) - 1:0] IN_uop;
	input wire [NUM_UOPS - 1:0] IN_uopOrdering;
	input wire [RESULT_BUS_COUNT - 1:0] IN_resultValid;
	input wire [(RESULT_BUS_COUNT * 88) - 1:0] IN_resultUOp;
	input wire IN_loadForwardValid;
	input wire [6:0] IN_loadForwardTag;
	input wire [75:0] IN_branch;
	input wire [NUM_UOPS - 1:0] IN_issueValid;
	input wire [(NUM_UOPS * 100) - 1:0] IN_issueUOps;
	input wire [6:0] IN_maxStoreSqN;
	input wire [6:0] IN_maxLoadSqN;
	output reg OUT_valid;
	output reg [99:0] OUT_uop;
	output reg OUT_full;
	localparam ID_LEN = $clog2(SIZE);
	integer i;
	integer j;
	reg [IMM_BITS + 67:0] queue [SIZE - 1:0];
	reg valid [SIZE - 1:0];
	reg [$clog2(SIZE):0] insertIndex;
	reg [32:0] reservedWBs;
	reg newAvailA [SIZE - 1:0];
	reg newAvailB [SIZE - 1:0];
	always @(*)
		for (i = 0; i < SIZE; i = i + 1)
			begin
				newAvailA[i] = 0;
				newAvailB[i] = 0;
				for (j = 0; j < RESULT_BUS_COUNT; j = j + 1)
					if (j != 3) begin
						if (IN_resultValid[j] && (queue[i][66-:7] == IN_resultUOp[(j * 88) + 55-:7]))
							newAvailA[i] = 1;
						if (IN_resultValid[j] && (queue[i][58-:7] == IN_resultUOp[(j * 88) + 55-:7]))
							newAvailB[i] = 1;
					end
				for (j = 0; j < 2; j = j + 1)
					if ((IN_issueValid[j] && (IN_issueUOps[(j * 100) + 3-:3] == 3'd0)) && (IN_issueUOps[(j * 100) + 36-:5] != 0)) begin
						if (queue[i][66-:7] == IN_issueUOps[(j * 100) + 43-:7])
							newAvailA[i] = 1;
						if (queue[i][58-:7] == IN_issueUOps[(j * 100) + 43-:7])
							newAvailB[i] = 1;
					end
				if (IN_loadForwardValid && (queue[i][66-:7] == IN_loadForwardTag))
					newAvailA[i] = 1;
				if (IN_loadForwardValid && (queue[i][58-:7] == IN_loadForwardTag))
					newAvailB[i] = 1;
			end
	always @(*) begin : sv2v_autoblock_1
		reg [$clog2(SIZE):0] count;
		count = 0;
		for (i = 0; i < NUM_UOPS; i = i + 1)
			if (IN_uopValid[i] && ((((IN_uop[(i * 100) + 3-:3] == FU0) && (!FU0_SPLIT || (IN_uopOrdering[i] == FU0_ORDER))) || (IN_uop[(i * 100) + 3-:3] == FU1)) || (IN_uop[(i * 100) + 3-:3] == FU2)))
				count = count + 1;
		OUT_full = insertIndex > (SIZE[$clog2(SIZE):0] - count);
	end
	always @(posedge clk) begin
		for (i = 0; i < SIZE; i = i + 1)
			begin
				queue[i][67] <= queue[i][67] | newAvailA[i];
				queue[i][59] <= queue[i][59] | newAvailB[i];
			end
		reservedWBs <= {1'b0, reservedWBs[32:1]};
		if (rst) begin
			insertIndex = 0;
			reservedWBs <= 0;
			OUT_valid <= 0;
		end
		else if (IN_branch[0]) begin : sv2v_autoblock_2
			reg [ID_LEN:0] newInsertIndex;
			newInsertIndex = 0;
			for (i = 0; i < SIZE; i = i + 1)
				if ((i < insertIndex) && ($signed(queue[i][50-:7] - IN_branch[43-:7]) <= 0))
					newInsertIndex = i[$clog2(SIZE):0] + 1;
			insertIndex = newInsertIndex;
			if (!IN_stall || ($signed(OUT_uop[50-:7] - IN_branch[43-:7]) > 0))
				OUT_valid <= 0;
		end
		else begin : sv2v_autoblock_3
			reg issued;
			issued = 0;
			if (!IN_stall) begin
				OUT_valid <= 0;
				for (i = 0; i < SIZE; i = i + 1)
					if ((i < insertIndex) && !issued)
						if (((((((queue[i][67] || newAvailA[i]) && (queue[i][59] || newAvailB[i])) && ((queue[i][3-:3] != FU1) || !IN_doNotIssueFU1)) && ((queue[i][3-:3] != FU2) || !IN_doNotIssueFU2)) && !(((queue[i][3-:3] == 3'd0) || (queue[i][3-:3] == 3'd5)) && reservedWBs[0])) && (((((FU0 != 3'd2) && (FU1 != 3'd2)) && (FU2 != 3'd2)) || (queue[i][3-:3] != 3'd2)) || ($signed(queue[i][17-:7] - IN_maxStoreSqN) <= 0))) && (((((FU0 != 3'd1) && (FU1 != 3'd1)) && (FU2 != 3'd1)) || (queue[i][3-:3] != 3'd1)) || ($signed(queue[i][10-:7] - IN_maxLoadSqN) <= 0))) begin
							issued = 1;
							OUT_valid <= 1;
							OUT_uop[99-:32] <= {{32 - IMM_BITS {1'b0}}, queue[i][IMM_BITS + 67-:((IMM_BITS + 67) >= 68 ? IMM_BITS + 0 : 69 - (IMM_BITS + 67))]};
							OUT_uop[67] <= queue[i][67];
							OUT_uop[66-:7] <= queue[i][66-:7];
							OUT_uop[59] <= queue[i][59];
							OUT_uop[58-:7] <= queue[i][58-:7];
							OUT_uop[51] <= queue[i][51];
							OUT_uop[50-:7] <= queue[i][50-:7];
							OUT_uop[43-:7] <= queue[i][43-:7];
							OUT_uop[36-:5] <= queue[i][36-:5];
							OUT_uop[31-:6] <= queue[i][31-:6];
							OUT_uop[25-:5] <= queue[i][25-:5];
							OUT_uop[20-:3] <= queue[i][20-:3];
							OUT_uop[17-:7] <= queue[i][17-:7];
							OUT_uop[10-:7] <= queue[i][10-:7];
							OUT_uop[3-:3] <= queue[i][3-:3];
							OUT_uop[0] <= queue[i][0];
							for (j = i; j < (SIZE - 1); j = j + 1)
								begin
									queue[j] <= queue[j + 1];
									queue[j][67] <= queue[j + 1][67] | newAvailA[j + 1];
									queue[j][59] <= queue[j + 1][59] | newAvailB[j + 1];
								end
							insertIndex = insertIndex - 1;
							if ((queue[i][3-:3] == FU1) && (FU1_DLY > 0))
								reservedWBs <= {1'b0, reservedWBs[32:1]} | (1 << (FU1_DLY - 1));
						end
			end
			if (frontEn)
				for (i = 0; i < NUM_UOPS; i = i + 1)
					if (IN_uopValid[i] && ((((IN_uop[(i * 100) + 3-:3] == FU0) && (!FU0_SPLIT || (IN_uopOrdering[i] == FU0_ORDER))) || (IN_uop[(i * 100) + 3-:3] == FU1)) || (IN_uop[(i * 100) + 3-:3] == FU2))) begin : sv2v_autoblock_4
						reg [IMM_BITS + 67:0] temp;
						temp[IMM_BITS + 67-:((IMM_BITS + 67) >= 68 ? IMM_BITS + 0 : 69 - (IMM_BITS + 67))] = IN_uop[(i * 100) + ((67 + IMM_BITS) >= 68 ? 67 + IMM_BITS : ((67 + IMM_BITS) + ((67 + IMM_BITS) >= 68 ? (67 + IMM_BITS) - 67 : 69 - (67 + IMM_BITS))) - 1)-:((67 + IMM_BITS) >= 68 ? (67 + IMM_BITS) - 67 : 69 - (67 + IMM_BITS))];
						temp[67] = IN_uop[(i * 100) + 67];
						temp[66-:7] = IN_uop[(i * 100) + 66-:7];
						temp[59] = IN_uop[(i * 100) + 59];
						temp[58-:7] = IN_uop[(i * 100) + 58-:7];
						temp[51] = IN_uop[(i * 100) + 51];
						temp[50-:7] = IN_uop[(i * 100) + 50-:7];
						temp[43-:7] = IN_uop[(i * 100) + 43-:7];
						temp[36-:5] = IN_uop[(i * 100) + 36-:5];
						temp[31-:6] = IN_uop[(i * 100) + 31-:6];
						temp[25-:5] = IN_uop[(i * 100) + 25-:5];
						temp[20-:3] = IN_uop[(i * 100) + 20-:3];
						temp[17-:7] = IN_uop[(i * 100) + 17-:7];
						temp[10-:7] = IN_uop[(i * 100) + 10-:7];
						temp[3-:3] = IN_uop[(i * 100) + 3-:3];
						temp[0] = IN_uop[i * 100];
						for (j = 0; j < RESULT_BUS_COUNT; j = j + 1)
							if (IN_resultValid[j]) begin
								if (temp[66-:7] == IN_resultUOp[(j * 88) + 55-:7])
									temp[67] = 1;
								if (temp[58-:7] == IN_resultUOp[(j * 88) + 55-:7])
									temp[59] = 1;
							end
						queue[insertIndex[ID_LEN - 1:0]] <= temp;
						insertIndex = insertIndex + 1;
					end
		end
	end
endmodule
