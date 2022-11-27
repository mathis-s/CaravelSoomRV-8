module TageTable (
	clk,
	rst,
	IN_readAddr,
	IN_readTag,
	OUT_readValid,
	OUT_readTaken,
	IN_writeAddr,
	IN_writeTag,
	IN_writeTaken,
	IN_writeValid,
	IN_writeNew,
	IN_writeUseful,
	IN_writeUpdate,
	OUT_writeAlloc,
	IN_anyAlloc
);
	parameter SIZE = 64;
	parameter TAG_SIZE = 8;
	parameter USF_SIZE = 2;
	parameter CNT_SIZE = 2;
	parameter INTERVAL = 20;
	input wire clk;
	input wire rst;
	input wire [5:0] IN_readAddr;
	input wire [7:0] IN_readTag;
	output reg OUT_readValid;
	output reg OUT_readTaken;
	input wire [5:0] IN_writeAddr;
	input wire [7:0] IN_writeTag;
	input wire IN_writeTaken;
	input wire IN_writeValid;
	input wire IN_writeNew;
	input wire IN_writeUseful;
	input wire IN_writeUpdate;
	output reg OUT_writeAlloc;
	input wire IN_anyAlloc;
	integer i;
	reg [((TAG_SIZE + USF_SIZE) + CNT_SIZE) - 1:0] entries [SIZE - 1:0];
	always @(*) begin
		OUT_readValid = entries[IN_readAddr][TAG_SIZE + (USF_SIZE + (CNT_SIZE - 1))-:((TAG_SIZE + (USF_SIZE + (CNT_SIZE - 1))) >= (USF_SIZE + (CNT_SIZE + 0)) ? ((TAG_SIZE + (USF_SIZE + (CNT_SIZE - 1))) - (USF_SIZE + (CNT_SIZE + 0))) + 1 : ((USF_SIZE + (CNT_SIZE + 0)) - (TAG_SIZE + (USF_SIZE + (CNT_SIZE - 1)))) + 1)] == IN_readTag;
		OUT_readTaken = entries[IN_readAddr][(CNT_SIZE - 1) - ((CNT_SIZE - 1) - (CNT_SIZE - 1))];
	end
	reg [INTERVAL - 1:0] decrCnt;
	always @(*) OUT_writeAlloc = ((IN_writeValid && !IN_writeUpdate) && IN_writeNew) && (entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] == 0);
	always @(posedge clk) begin
		if (decrCnt == 0)
			for (i = 0; i < SIZE; i = i + 1)
				if (entries[i][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] != 0)
					entries[i][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] <= entries[i][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] - 1;
		if (rst)
			decrCnt <= 0;
		else if (IN_writeValid)
			if (IN_writeUpdate) begin
				if (IN_writeTaken && (entries[IN_writeAddr][CNT_SIZE - 1-:CNT_SIZE] != {CNT_SIZE {1'b1}}))
					entries[IN_writeAddr][CNT_SIZE - 1-:CNT_SIZE] <= entries[IN_writeAddr][CNT_SIZE - 1-:CNT_SIZE] + 1;
				else if (!IN_writeTaken && (entries[IN_writeAddr][CNT_SIZE - 1-:CNT_SIZE] != {CNT_SIZE {1'b0}}))
					entries[IN_writeAddr][CNT_SIZE - 1-:CNT_SIZE] <= entries[IN_writeAddr][CNT_SIZE - 1-:CNT_SIZE] - 1;
				if (IN_writeUseful && (entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] != {USF_SIZE {1'b1}}))
					entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] <= entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] + 1;
				else if (!IN_writeUseful && (entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] != {USF_SIZE {1'b0}}))
					entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] <= entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] - 1;
			end
			else if (IN_writeNew)
				if (entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] == 0) begin
					entries[IN_writeAddr][TAG_SIZE + (USF_SIZE + (CNT_SIZE - 1))-:((TAG_SIZE + (USF_SIZE + (CNT_SIZE - 1))) >= (USF_SIZE + (CNT_SIZE + 0)) ? ((TAG_SIZE + (USF_SIZE + (CNT_SIZE - 1))) - (USF_SIZE + (CNT_SIZE + 0))) + 1 : ((USF_SIZE + (CNT_SIZE + 0)) - (TAG_SIZE + (USF_SIZE + (CNT_SIZE - 1)))) + 1)] <= IN_writeTag;
					entries[IN_writeAddr][CNT_SIZE - 1-:CNT_SIZE] <= {IN_writeTaken, {CNT_SIZE - 1 {1'b0}}};
					entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] <= 0;
				end
				else if (!IN_anyAlloc)
					entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] <= entries[IN_writeAddr][USF_SIZE + (CNT_SIZE - 1)-:((USF_SIZE + (CNT_SIZE - 1)) >= (CNT_SIZE + 0) ? ((USF_SIZE + (CNT_SIZE - 1)) - (CNT_SIZE + 0)) + 1 : ((CNT_SIZE + 0) - (USF_SIZE + (CNT_SIZE - 1))) + 1)] - 1;
		decrCnt <= decrCnt - 1;
	end
endmodule
