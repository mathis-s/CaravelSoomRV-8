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
	parameter FU0 = 4'd2;
	parameter FU1 = 4'd2;
	parameter FU2 = 4'd2;
	parameter FU3 = 4'd2;
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
	input wire [(NUM_UOPS * 101) - 1:0] IN_uop;
	input wire [NUM_UOPS - 1:0] IN_uopOrdering;
	input wire [RESULT_BUS_COUNT - 1:0] IN_resultValid;
	input wire [(RESULT_BUS_COUNT * 88) - 1:0] IN_resultUOp;
	input wire IN_loadForwardValid;
	input wire [6:0] IN_loadForwardTag;
	input wire [75:0] IN_branch;
	input wire [NUM_UOPS - 1:0] IN_issueValid;
	input wire [(NUM_UOPS * 101) - 1:0] IN_issueUOps;
	input wire [6:0] IN_maxStoreSqN;
	input wire [6:0] IN_maxLoadSqN;
	output reg OUT_valid;
	output reg [100:0] OUT_uop;
	output reg OUT_full;
	localparam ID_LEN = $clog2(SIZE);
	integer i;
	integer j;
	reg [IMM_BITS + 68:0] queue [SIZE - 1:0];
	reg valid [SIZE - 1:0];
	reg [$clog2(SIZE):0] insertIndex;
	reg [32:0] reservedWBs;
	reg newAvailA [SIZE - 1:0];
	reg newAvailB [SIZE - 1:0];
	reg newAvailA_dl [SIZE - 1:0];
	reg newAvailB_dl [SIZE - 1:0];
	always @(*)
		for (i = 0; i < SIZE; i = i + 1)
			begin
				newAvailA[i] = 0;
				newAvailB[i] = 0;
				newAvailA_dl[i] = 0;
				newAvailB_dl[i] = 0;
				for (j = 0; j < RESULT_BUS_COUNT; j = j + 1)
					begin
						if (IN_resultValid[j] && (queue[i][67-:7] == IN_resultUOp[(j * 88) + 55-:7]))
							newAvailA[i] = 1;
						if (IN_resultValid[j] && (queue[i][59-:7] == IN_resultUOp[(j * 88) + 55-:7]))
							newAvailB[i] = 1;
					end
				for (j = 0; j < 2; j = j + 1)
					if (IN_issueValid[j] && (IN_issueUOps[(j * 101) + 37-:5] != 0))
						if (IN_issueUOps[(j * 101) + 4-:4] == 4'd0) begin
							if (queue[i][67-:7] == IN_issueUOps[(j * 101) + 44-:7])
								newAvailA[i] = 1;
							if (queue[i][59-:7] == IN_issueUOps[(j * 101) + 44-:7])
								newAvailB[i] = 1;
						end
						else if ((IN_issueUOps[(j * 101) + 4-:4] == 4'd5) || (IN_issueUOps[(j * 101) + 4-:4] == 4'd7)) begin
							if (queue[i][67-:7] == IN_issueUOps[(j * 101) + 44-:7])
								newAvailA_dl[i] = 1;
							if (queue[i][59-:7] == IN_issueUOps[(j * 101) + 44-:7])
								newAvailB_dl[i] = 1;
						end
				if (IN_loadForwardValid && (queue[i][67-:7] == IN_loadForwardTag))
					newAvailA[i] = 1;
				if (IN_loadForwardValid && (queue[i][59-:7] == IN_loadForwardTag))
					newAvailB[i] = 1;
			end
	always @(*) begin : sv2v_autoblock_1
		reg [$clog2(SIZE):0] count;
		count = 0;
		for (i = 0; i < NUM_UOPS; i = i + 1)
			if (IN_uopValid[i] && (((((IN_uop[(i * 101) + 4-:4] == FU0) && (!FU0_SPLIT || (IN_uopOrdering[i] == FU0_ORDER))) || (IN_uop[(i * 101) + 4-:4] == FU1)) || (IN_uop[(i * 101) + 4-:4] == FU2)) || (IN_uop[(i * 101) + 4-:4] == FU3)))
				count = count + 1;
		OUT_full = insertIndex > (SIZE[$clog2(SIZE):0] - count);
	end
	always @(posedge clk) begin
		for (i = 0; i < SIZE; i = i + 1)
			begin
				queue[i][68] <= (queue[i][68] | newAvailA[i]) | newAvailA_dl[i];
				queue[i][60] <= (queue[i][60] | newAvailB[i]) | newAvailB_dl[i];
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
				if ((i < insertIndex) && ($signed(queue[i][51-:7] - IN_branch[43-:7]) <= 0))
					newInsertIndex = i[$clog2(SIZE):0] + 1;
			insertIndex = newInsertIndex;
			if (!IN_stall || ($signed(OUT_uop[51-:7] - IN_branch[43-:7]) > 0))
				OUT_valid <= 0;
		end
		else begin : sv2v_autoblock_3
			reg issued;
			issued = 0;
			if (!IN_stall) begin
				OUT_valid <= 0;
				for (i = 0; i < SIZE; i = i + 1)
					if ((i < insertIndex) && !issued)
						if (((((((queue[i][68] || newAvailA[i]) && (queue[i][60] || newAvailB[i])) && ((queue[i][4-:4] != FU1) || !IN_doNotIssueFU1)) && ((queue[i][4-:4] != FU2) || !IN_doNotIssueFU2)) && !((((queue[i][4-:4] == 4'd0) || (queue[i][4-:4] == 4'd5)) || (queue[i][4-:4] == 4'd7)) && reservedWBs[0])) && ((((((FU0 != 4'd2) && (FU1 != 4'd2)) && (FU2 != 4'd2)) && (FU3 != 4'd2)) || (queue[i][4-:4] != 4'd2)) || ($signed(queue[i][18-:7] - IN_maxStoreSqN) <= 0))) && ((((((FU0 != 4'd1) && (FU1 != 4'd1)) && (FU2 != 4'd1)) && (FU3 != 4'd1)) || (queue[i][4-:4] != 4'd1)) || ($signed(queue[i][11-:7] - IN_maxLoadSqN) <= 0))) begin
							issued = 1;
							OUT_valid <= 1;
							OUT_uop[100-:32] <= {{32 - IMM_BITS {1'b0}}, queue[i][IMM_BITS + 68-:((IMM_BITS + 68) >= 69 ? IMM_BITS + 0 : 70 - (IMM_BITS + 68))]};
							OUT_uop[68] <= queue[i][68];
							OUT_uop[67-:7] <= queue[i][67-:7];
							OUT_uop[60] <= queue[i][60];
							OUT_uop[59-:7] <= queue[i][59-:7];
							OUT_uop[52] <= queue[i][52];
							OUT_uop[51-:7] <= queue[i][51-:7];
							OUT_uop[44-:7] <= queue[i][44-:7];
							OUT_uop[37-:5] <= queue[i][37-:5];
							OUT_uop[32-:6] <= queue[i][32-:6];
							OUT_uop[26-:5] <= queue[i][26-:5];
							OUT_uop[21-:3] <= queue[i][21-:3];
							OUT_uop[18-:7] <= queue[i][18-:7];
							OUT_uop[11-:7] <= queue[i][11-:7];
							OUT_uop[4-:4] <= queue[i][4-:4];
							OUT_uop[0] <= queue[i][0];
							for (j = i; j < (SIZE - 1); j = j + 1)
								begin
									queue[j] <= queue[j + 1];
									queue[j][68] <= (queue[j + 1][68] | newAvailA[j + 1]) | newAvailA_dl[j + 1];
									queue[j][60] <= (queue[j + 1][60] | newAvailB[j + 1]) | newAvailB_dl[j + 1];
								end
							insertIndex = insertIndex - 1;
							if ((queue[i][4-:4] == FU1) && (FU1_DLY > 0))
								reservedWBs <= {1'b0, reservedWBs[32:1]} | (1 << (FU1_DLY - 1));
						end
			end
			if (frontEn)
				for (i = 0; i < NUM_UOPS; i = i + 1)
					if (IN_uopValid[i] && (((((IN_uop[(i * 101) + 4-:4] == FU0) && (!FU0_SPLIT || (IN_uopOrdering[i] == FU0_ORDER))) || (IN_uop[(i * 101) + 4-:4] == FU1)) || (IN_uop[(i * 101) + 4-:4] == FU2)) || (IN_uop[(i * 101) + 4-:4] == FU3))) begin : sv2v_autoblock_4
						reg [IMM_BITS + 68:0] temp;
						temp[IMM_BITS + 68-:((IMM_BITS + 68) >= 69 ? IMM_BITS + 0 : 70 - (IMM_BITS + 68))] = IN_uop[(i * 101) + ((68 + IMM_BITS) >= 69 ? 68 + IMM_BITS : ((68 + IMM_BITS) + ((68 + IMM_BITS) >= 69 ? (68 + IMM_BITS) - 68 : 70 - (68 + IMM_BITS))) - 1)-:((68 + IMM_BITS) >= 69 ? (68 + IMM_BITS) - 68 : 70 - (68 + IMM_BITS))];
						temp[68] = IN_uop[(i * 101) + 68];
						temp[67-:7] = IN_uop[(i * 101) + 67-:7];
						temp[60] = IN_uop[(i * 101) + 60];
						temp[59-:7] = IN_uop[(i * 101) + 59-:7];
						temp[52] = IN_uop[(i * 101) + 52];
						temp[51-:7] = IN_uop[(i * 101) + 51-:7];
						temp[44-:7] = IN_uop[(i * 101) + 44-:7];
						temp[37-:5] = IN_uop[(i * 101) + 37-:5];
						temp[32-:6] = IN_uop[(i * 101) + 32-:6];
						temp[26-:5] = IN_uop[(i * 101) + 26-:5];
						temp[21-:3] = IN_uop[(i * 101) + 21-:3];
						temp[18-:7] = IN_uop[(i * 101) + 18-:7];
						temp[11-:7] = IN_uop[(i * 101) + 11-:7];
						temp[4-:4] = IN_uop[(i * 101) + 4-:4];
						temp[0] = IN_uop[i * 101];
						for (j = 0; j < RESULT_BUS_COUNT; j = j + 1)
							if (IN_resultValid[j]) begin
								if (temp[67-:7] == IN_resultUOp[(j * 88) + 55-:7])
									temp[68] = 1;
								if (temp[59-:7] == IN_resultUOp[(j * 88) + 55-:7])
									temp[60] = 1;
							end
						queue[insertIndex[ID_LEN - 1:0]] <= temp;
						insertIndex = insertIndex + 1;
					end
		end
	end
endmodule
