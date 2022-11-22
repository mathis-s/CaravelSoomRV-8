module RenameHistory (
	clk,
	rst,
	IN_issueValid,
	IN_issueSqNs,
	IN_issueRegNms,
	IN_issueTags,
	IN_readSqN,
	OUT_readRegNm,
	OUT_readRegTag
);
	parameter NUM_UOPS = 3;
	parameter NUM_ENTRIES = 32;
	input wire clk;
	input wire rst;
	input wire [NUM_UOPS - 1:0] IN_issueValid;
	input wire [(NUM_UOPS * 6) - 1:0] IN_issueSqNs;
	input wire [(NUM_UOPS * 6) - 1:0] IN_issueRegNms;
	input wire [(NUM_UOPS * 7) - 1:0] IN_issueTags;
	input wire [5:0] IN_readSqN;
	output reg [(NUM_UOPS * 6) - 1:0] OUT_readRegNm;
	output reg [(NUM_UOPS * 7) - 1:0] OUT_readRegTag;
	integer i;
	reg [12:0] entries [NUM_ENTRIES - 1:0];
	always @(*)
		for (i = 0; i < NUM_UOPS; i = i + 1)
			begin
				OUT_readRegNm[i * 6+:6] = entries[IN_readSqN[$clog2(NUM_ENTRIES) - 1:0] + i[$clog2(NUM_ENTRIES) - 1:0]][12-:6];
				OUT_readRegTag[i * 7+:7] = entries[IN_readSqN[$clog2(NUM_ENTRIES) - 1:0] + i[$clog2(NUM_ENTRIES) - 1:0]][6-:7];
			end
	always @(posedge clk)
		for (i = 0; i < NUM_UOPS; i = i + 1)
			if (IN_issueValid[i]) begin
				entries[IN_issueSqNs[(i * 6) + ($clog2(NUM_ENTRIES) - 1)-:$clog2(NUM_ENTRIES)]][12-:6] <= IN_issueRegNms[i * 6+:6];
				entries[IN_issueSqNs[(i * 6) + ($clog2(NUM_ENTRIES) - 1)-:$clog2(NUM_ENTRIES)]][6-:7] <= IN_issueTags[i * 7+:7];
			end
endmodule
