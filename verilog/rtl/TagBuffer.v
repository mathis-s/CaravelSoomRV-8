module TagBuffer (
	clk,
	rst,
	IN_mispr,
	IN_mispredFlush,
	IN_issueValid,
	OUT_issueTags,
	OUT_issueTagsValid,
	IN_commitValid,
	IN_commitNewest,
	IN_RAT_commitPrevTags,
	IN_commitTagDst
);
	parameter NUM_UOPS = 4;
	input wire clk;
	input wire rst;
	input wire IN_mispr;
	input wire IN_mispredFlush;
	input wire [NUM_UOPS - 1:0] IN_issueValid;
	output reg [(NUM_UOPS * 6) - 1:0] OUT_issueTags;
	output reg [NUM_UOPS - 1:0] OUT_issueTagsValid;
	input wire [NUM_UOPS - 1:0] IN_commitValid;
	input wire [NUM_UOPS - 1:0] IN_commitNewest;
	input wire [(NUM_UOPS * 7) - 1:0] IN_RAT_commitPrevTags;
	input wire [(NUM_UOPS * 7) - 1:0] IN_commitTagDst;
	integer i;
	integer j;
	reg [1:0] tags [63:0];
	always @(*)
		for (i = 0; i < NUM_UOPS; i = i + 1)
			begin
				OUT_issueTags[i * 6+:6] = 6'bxxxxxx;
				for (j = 0; j < 64; j = j + 1)
					if (((!tags[j][1] && ((i <= 0) || (OUT_issueTags[0+:6] != j[5:0]))) && ((i <= 1) || (OUT_issueTags[6+:6] != j[5:0]))) && ((i <= 2) || (OUT_issueTags[12+:6] != j[5:0])))
						OUT_issueTags[i * 6+:6] = j[5:0];
			end
	reg [63:0] dbgUsed;
	always @(*)
		for (i = 0; i < 64; i = i + 1)
			dbgUsed[i] = tags[i][1];
	reg [6:0] free;
	reg [6:0] freeCom;
	always @(*)
		for (i = 0; i < NUM_UOPS; i = i + 1)
			OUT_issueTagsValid[i] = free > i[6:0];
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < 64; i = i + 1)
				begin
					tags[i][1] <= 1'b0;
					tags[i][0] <= 1'b0;
				end
			free = 64;
			freeCom = 64;
		end
		else begin
			if (IN_mispr) begin
				for (i = 0; i < 64; i = i + 1)
					if (!tags[i][0])
						tags[i][1] <= 0;
			end
			else
				for (i = 0; i < NUM_UOPS; i = i + 1)
					if (IN_issueValid[i]) begin
						tags[OUT_issueTags[i * 6+:6]][1] <= 1;
						free = free - 1;
					end
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if (IN_commitValid[i])
					if (IN_mispredFlush) begin
						if (!IN_mispr && !IN_commitTagDst[(i * 7) + 6]) begin
							tags[IN_commitTagDst[(i * 7) + 5-:6]][1] <= 1;
							free = free - 1;
						end
					end
					else if (IN_commitNewest[i]) begin
						if (!IN_RAT_commitPrevTags[(i * 7) + 6]) begin
							tags[IN_RAT_commitPrevTags[(i * 7) + 5-:6]][0] <= 0;
							tags[IN_RAT_commitPrevTags[(i * 7) + 5-:6]][1] <= 0;
							freeCom = freeCom + 1;
							free = free + 1;
						end
						if (!IN_commitTagDst[(i * 7) + 6]) begin
							tags[IN_commitTagDst[(i * 7) + 5-:6]][0] <= 1;
							tags[IN_commitTagDst[(i * 7) + 5-:6]][1] <= 1;
							freeCom = freeCom - 1;
						end
					end
					else if (!IN_commitTagDst[(i * 7) + 6]) begin
						tags[IN_commitTagDst[(i * 7) + 5-:6]][0] <= 0;
						tags[IN_commitTagDst[(i * 7) + 5-:6]][1] <= 0;
						free = free + 1;
					end
			if (IN_mispr)
				free = freeCom;
		end
endmodule
