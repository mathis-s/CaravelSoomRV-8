module TagePredictor (
	clk,
	rst,
	IN_predAddr,
	IN_predHistory,
	OUT_predTageID,
	OUT_predUseful,
	OUT_predTaken,
	IN_writeValid,
	IN_writeAddr,
	IN_writeHistory,
	IN_writeTageID,
	IN_writeTaken,
	IN_writeUseful,
	IN_writePred
);
	parameter NUM_STAGES = 3;
	parameter FACTOR = 2;
	parameter TABLE_SIZE = 64;
	parameter TAG_SIZE = 8;
	input wire clk;
	input wire rst;
	input wire [30:0] IN_predAddr;
	input wire [15:0] IN_predHistory;
	output reg [2:0] OUT_predTageID;
	output reg [2:0] OUT_predUseful;
	output reg OUT_predTaken;
	input wire IN_writeValid;
	input wire [30:0] IN_writeAddr;
	input wire [15:0] IN_writeHistory;
	input wire [2:0] IN_writeTageID;
	input wire IN_writeTaken;
	input wire [2:0] IN_writeUseful;
	input wire IN_writePred;
	localparam HASH_SIZE = $clog2(TABLE_SIZE);
	integer i;
	integer j;
	wire [NUM_STAGES - 1:0] valid;
	wire [NUM_STAGES - 1:0] predictions;
	BranchPredictionTable basePredictor(
		.clk(clk),
		.rst(rst),
		.IN_readAddr(IN_predAddr[7:0]),
		.OUT_taken(predictions[0]),
		.IN_writeEn(IN_writeValid),
		.IN_writeAddr(IN_writeAddr[7:0]),
		.IN_writeTaken(IN_writeTaken)
	);
	assign valid[0] = 1;
	reg [HASH_SIZE - 1:0] predHashes [NUM_STAGES - 2:0];
	reg [HASH_SIZE - 1:0] writeHashes [NUM_STAGES - 2:0];
	reg [TAG_SIZE - 1:0] predTags [NUM_STAGES - 2:0];
	reg [TAG_SIZE - 1:0] writeTags [NUM_STAGES - 2:0];
	always @(*)
		for (i = 0; i < (NUM_STAGES - 1); i = i + 1)
			begin
				predTags[i] = IN_predAddr[TAG_SIZE - 1:0];
				writeTags[i] = IN_writeAddr[TAG_SIZE - 1:0];
				predHashes[i] = 0;
				writeHashes[i] = 0;
				for (j = 0; j < (31 / HASH_SIZE); j = j + 1)
					begin
						predHashes[i] = predHashes[i] ^ IN_predAddr[j * HASH_SIZE+:HASH_SIZE];
						writeHashes[i] = writeHashes[i] ^ IN_writeAddr[j * HASH_SIZE+:HASH_SIZE];
					end
				for (j = 0; j < (FACTOR ** i); j = j + 1)
					begin
						predHashes[i] = (predHashes[i] ^ IN_predHistory[TAG_SIZE * j+:HASH_SIZE]) ^ {4'b0000, IN_predHistory[(TAG_SIZE * j) + HASH_SIZE+:2]};
						writeHashes[i] = (writeHashes[i] ^ IN_writeHistory[TAG_SIZE * j+:HASH_SIZE]) ^ {4'b0000, IN_writeHistory[(TAG_SIZE * j) + HASH_SIZE+:2]};
						predTags[i] = predTags[i] ^ IN_predHistory[TAG_SIZE * j+:TAG_SIZE];
						writeTags[i] = writeTags[i] ^ IN_writeHistory[TAG_SIZE * j+:TAG_SIZE];
						predTags[i] = predTags[i] ^ {IN_predHistory[TAG_SIZE * j+:TAG_SIZE - 1], 1'b0};
						writeTags[i] = writeTags[i] ^ {IN_writeHistory[TAG_SIZE * j+:TAG_SIZE - 1], 1'b0};
					end
			end
	wire [NUM_STAGES - 1:0] alloc;
	assign alloc[0] = 0;
	genvar ii;
	generate
		for (ii = 1; ii < NUM_STAGES; ii = ii + 1) begin : genblk1
			TageTable tage(
				.clk(clk),
				.rst(rst),
				.IN_readAddr(predHashes[ii - 1]),
				.IN_readTag(predTags[ii - 1]),
				.OUT_readValid(valid[ii]),
				.OUT_readTaken(predictions[ii]),
				.IN_writeAddr(writeHashes[ii - 1]),
				.IN_writeTag(writeTags[ii - 1]),
				.IN_writeTaken(IN_writeTaken),
				.IN_writeValid(IN_writeValid),
				.IN_writeNew(((IN_writeTaken != IN_writePred) && !alloc[ii - 1]) && (ii > IN_writeTageID)),
				.IN_writeUseful((IN_writeUseful[ii] == IN_writeTaken) && (IN_writeUseful[ii] != IN_writeUseful[ii - 1])),
				.IN_writeUpdate(ii == IN_writeTageID),
				.OUT_writeAlloc(alloc[ii]),
				.IN_anyAlloc(|alloc)
			);
		end
	endgenerate
	always @(*) begin
		OUT_predTaken = 0;
		OUT_predTageID = 0;
		for (i = 0; i < NUM_STAGES; i = i + 1)
			begin
				if (valid[i]) begin
					OUT_predTageID = i[2:0];
					OUT_predTaken = predictions[i];
				end
				OUT_predUseful[i] = OUT_predTaken;
			end
	end
endmodule
