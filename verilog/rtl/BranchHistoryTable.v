module BranchHistoryTable (
	clk,
	rst,
	IN_writeAddr,
	IN_writeTaken,
	IN_writeValid,
	IN_owriteValid,
	IN_owriteAddr,
	IN_owriteData,
	IN_readAddr,
	OUT_readHist
);
	parameter NUM_ENTRIES = 1024;
	parameter HISTORY_LEN = 8;
	input wire clk;
	input wire rst;
	localparam ADDR_LEN = $clog2(NUM_ENTRIES);
	input wire [ADDR_LEN - 1:0] IN_writeAddr;
	input wire IN_writeTaken;
	input wire IN_writeValid;
	input wire IN_owriteValid;
	input wire [ADDR_LEN - 1:0] IN_owriteAddr;
	input wire [HISTORY_LEN - 1:0] IN_owriteData;
	input wire [ADDR_LEN - 1:0] IN_readAddr;
	output reg [HISTORY_LEN - 1:0] OUT_readHist;
	integer i;
	reg [HISTORY_LEN - 1:0] data [0:NUM_ENTRIES - 1];
	always @(*) OUT_readHist = data[IN_readAddr];
	always @(posedge clk) begin
		if (rst) begin
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				data[i] <= 0;
		end
		else if (IN_writeValid)
			data[IN_writeAddr] <= {data[IN_writeAddr][HISTORY_LEN - 2:0], IN_writeTaken};
		if (!rst && IN_owriteValid)
			data[IN_owriteAddr] <= IN_owriteData;
	end
endmodule
