module RenameTable (
	clk,
	rst,
	IN_mispred,
	IN_mispredFlush,
	IN_lookupIDs,
	OUT_lookupAvail,
	OUT_lookupSpecTag,
	IN_issueValid,
	IN_issueIDs,
	IN_issueTags,
	IN_issueAvail,
	IN_commitValid,
	IN_commitIDs,
	IN_commitTags,
	IN_commitAvail,
	OUT_commitPrevTags,
	IN_wbValid,
	IN_wbID,
	IN_wbTag
);
	parameter NUM_LOOKUP = 8;
	parameter NUM_ISSUE = 4;
	parameter NUM_COMMIT = 4;
	parameter NUM_WB = 4;
	parameter NUM_REGS = 32;
	parameter ID_SIZE = $clog2(NUM_REGS);
	parameter TAG_SIZE = 7;
	input wire clk;
	input wire rst;
	input wire IN_mispred;
	input wire IN_mispredFlush;
	input wire [(NUM_LOOKUP * ID_SIZE) - 1:0] IN_lookupIDs;
	output reg [NUM_LOOKUP - 1:0] OUT_lookupAvail;
	output reg [(NUM_LOOKUP * TAG_SIZE) - 1:0] OUT_lookupSpecTag;
	input wire [NUM_ISSUE - 1:0] IN_issueValid;
	input wire [(NUM_ISSUE * ID_SIZE) - 1:0] IN_issueIDs;
	input wire [(NUM_ISSUE * TAG_SIZE) - 1:0] IN_issueTags;
	input wire [NUM_ISSUE - 1:0] IN_issueAvail;
	input wire [NUM_COMMIT - 1:0] IN_commitValid;
	input wire [(NUM_COMMIT * ID_SIZE) - 1:0] IN_commitIDs;
	input wire [(NUM_COMMIT * TAG_SIZE) - 1:0] IN_commitTags;
	input wire [NUM_COMMIT - 1:0] IN_commitAvail;
	output reg [(NUM_COMMIT * TAG_SIZE) - 1:0] OUT_commitPrevTags;
	input wire [NUM_WB - 1:0] IN_wbValid;
	input wire [(NUM_WB * ID_SIZE) - 1:0] IN_wbID;
	input wire [(NUM_WB * TAG_SIZE) - 1:0] IN_wbTag;
	integer i;
	integer j;
	reg [14:0] rat [NUM_REGS - 1:0];
	always @(*) begin
		for (i = 0; i < NUM_LOOKUP; i = i + 1)
			begin
				OUT_lookupAvail[i] = rat[IN_lookupIDs[i * ID_SIZE+:ID_SIZE]][14];
				OUT_lookupSpecTag[i * TAG_SIZE+:TAG_SIZE] = rat[IN_lookupIDs[i * ID_SIZE+:ID_SIZE]][6-:7];
				for (j = 0; j < NUM_WB; j = j + 1)
					if (IN_wbValid[j] && (IN_wbTag[j * TAG_SIZE+:TAG_SIZE] == OUT_lookupSpecTag[i * TAG_SIZE+:TAG_SIZE]))
						OUT_lookupAvail[i] = 1;
				for (j = 0; j < (i / 2); j = j + 1)
					if ((IN_issueValid[j] && (IN_issueIDs[j * ID_SIZE+:ID_SIZE] == IN_lookupIDs[i * ID_SIZE+:ID_SIZE])) && (IN_issueIDs[j * ID_SIZE+:ID_SIZE] != 0)) begin
						OUT_lookupAvail[i] = IN_issueAvail[j];
						OUT_lookupSpecTag[i * TAG_SIZE+:TAG_SIZE] = IN_issueTags[j * TAG_SIZE+:TAG_SIZE];
					end
			end
		for (i = 0; i < NUM_COMMIT; i = i + 1)
			OUT_commitPrevTags[i * TAG_SIZE+:TAG_SIZE] = rat[IN_commitIDs[i * ID_SIZE+:ID_SIZE]][13-:7];
	end
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < NUM_REGS; i = i + 1)
				begin
					rat[i][14] <= 1;
					rat[i][13-:7] <= 7'h40;
					rat[i][6-:7] <= 7'h40;
				end
		end
		else begin
			for (i = 0; i < NUM_WB; i = i + 1)
				if ((IN_wbValid[i] && (rat[IN_wbID[i * ID_SIZE+:ID_SIZE]][6-:7] == IN_wbTag[i * TAG_SIZE+:TAG_SIZE])) && (IN_wbID[i * ID_SIZE+:ID_SIZE] != 0))
					rat[IN_wbID[i * ID_SIZE+:ID_SIZE]][14] <= 1;
			if (IN_mispred) begin
				for (i = 1; i < NUM_REGS; i = i + 1)
					begin
						rat[i][14] <= 1;
						rat[i][6-:7] <= rat[i][13-:7];
					end
			end
			else
				for (i = 0; i < NUM_ISSUE; i = i + 1)
					if (IN_issueValid[i] && (IN_issueIDs[i * ID_SIZE+:ID_SIZE] != 0)) begin
						rat[IN_issueIDs[i * ID_SIZE+:ID_SIZE]][14] <= IN_issueAvail[i];
						rat[IN_issueIDs[i * ID_SIZE+:ID_SIZE]][6-:7] <= IN_issueTags[i * TAG_SIZE+:TAG_SIZE];
					end
			for (i = 0; i < NUM_COMMIT; i = i + 1)
				if (IN_commitValid[i] && (IN_commitIDs[i * ID_SIZE+:ID_SIZE] != 0))
					if (IN_mispredFlush) begin
						if (!IN_mispred) begin
							rat[IN_commitIDs[i * ID_SIZE+:ID_SIZE]][6-:7] <= IN_commitTags[i * TAG_SIZE+:TAG_SIZE];
							rat[IN_commitIDs[i * ID_SIZE+:ID_SIZE]][14] <= IN_commitAvail[i];
							for (j = 0; j < NUM_WB; j = j + 1)
								if (IN_wbValid[j] && (IN_wbTag[j * TAG_SIZE+:TAG_SIZE] == IN_commitTags[i * TAG_SIZE+:TAG_SIZE]))
									rat[IN_commitIDs[i * ID_SIZE+:ID_SIZE]][14] <= 1;
						end
					end
					else begin
						rat[IN_commitIDs[i * ID_SIZE+:ID_SIZE]][13-:7] <= IN_commitTags[i * TAG_SIZE+:TAG_SIZE];
						if (IN_mispred)
							rat[IN_commitIDs[i * ID_SIZE+:ID_SIZE]][6-:7] <= IN_commitTags[i * TAG_SIZE+:TAG_SIZE];
					end
		end
endmodule
