module ROB (
	clk,
	rst,
	IN_uop,
	IN_uopValid,
	IN_wbUOps,
	IN_branch,
	OUT_maxSqN,
	OUT_curSqN,
	OUT_comUOp,
	OUT_bpUpdate,
	IN_irqAddr,
	OUT_irqFlags,
	OUT_irqSrc,
	OUT_irqMemAddr,
	OUT_pcReadAddr,
	IN_pcReadData,
	OUT_branch,
	OUT_curFetchID,
	IN_irq,
	IN_MEM_busy,
	IN_allowBreak,
	OUT_fence,
	OUT_clearICache,
	OUT_disableIFetch,
	OUT_irqTaken,
	OUT_halt,
	OUT_mispredFlush
);
	parameter LENGTH = 64;
	parameter WIDTH = 4;
	parameter WIDTH_WB = 4;
	input wire clk;
	input wire rst;
	input wire [(WIDTH * 101) - 1:0] IN_uop;
	input wire [WIDTH - 1:0] IN_uopValid;
	input wire [(WIDTH_WB * 88) - 1:0] IN_wbUOps;
	input wire [75:0] IN_branch;
	output wire [6:0] OUT_maxSqN;
	output wire [6:0] OUT_curSqN;
	output reg [(WIDTH * 23) - 1:0] OUT_comUOp;
	output reg [58:0] OUT_bpUpdate;
	input wire [31:0] IN_irqAddr;
	output reg [2:0] OUT_irqFlags;
	output reg [31:0] OUT_irqSrc;
	output reg [31:0] OUT_irqMemAddr;
	output wire [4:0] OUT_pcReadAddr;
	input wire [58:0] IN_pcReadData;
	output reg [75:0] OUT_branch;
	output reg [4:0] OUT_curFetchID;
	input wire IN_irq;
	input wire IN_MEM_busy;
	input wire IN_allowBreak;
	output reg OUT_fence;
	output reg OUT_clearICache;
	output wire OUT_disableIFetch;
	output reg OUT_irqTaken;
	output reg OUT_halt;
	output reg OUT_mispredFlush;
	integer i;
	integer j;
	localparam ID_LEN = $clog2(LENGTH);
	reg [100:0] rnUOpSorted [WIDTH - 1:0];
	reg rnUOpValidSorted [WIDTH - 1:0];
	always @(*)
		for (i = 0; i < WIDTH; i = i + 1)
			begin
				rnUOpValidSorted[i] = 0;
				rnUOpSorted[i] = 101'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
				for (j = 0; j < WIDTH; j = j + 1)
					if (IN_uopValid[j] && (IN_uop[(j * 101) + 46-:2] == i[1:0])) begin
						rnUOpValidSorted[i] = 1;
						rnUOpSorted[i] = IN_uop[j * 101+:101];
					end
			end
	reg [26:0] entries [LENGTH - 1:0];
	reg [6:0] baseIndex;
	assign OUT_maxSqN = (baseIndex + LENGTH) - 1;
	assign OUT_curSqN = baseIndex;
	reg [6:0] pcLookupEntrySqN;
	reg [26:0] pcLookupEntry;
	assign OUT_pcReadAddr = pcLookupEntry[7-:5];
	wire [30:0] baseIndexPC = {IN_pcReadData[58:31], pcLookupEntry[10-:3]} - (pcLookupEntry[2] ? 0 : 1);
	reg [15:0] baseIndexHist;
	reg [8:0] baseIndexBPI;
	always @(*) begin
		if ((IN_pcReadData[24] && !IN_pcReadData[16]) && (pcLookupEntry[10-:3] > IN_pcReadData[27-:3]))
			baseIndexHist = {IN_pcReadData[14:0], IN_pcReadData[23]};
		else
			baseIndexHist = IN_pcReadData[15-:16];
		baseIndexBPI = (pcLookupEntry[10-:3] == IN_pcReadData[27-:3] ? IN_pcReadData[24-:9] : 0);
	end
	reg stop;
	reg memoryWait;
	reg instrFence;
	reg externalIRQ;
	assign OUT_disableIFetch = memoryWait;
	reg misprReplay;
	reg misprReplayEnd;
	reg [6:0] misprReplayIter;
	reg [6:0] misprReplayEndSqN;
	reg [3:0] deqAddresses [WIDTH - 1:0];
	reg [26:0] deqPorts [WIDTH - 1:0];
	always @(*)
		for (i = 0; i < WIDTH; i = i + 1)
			deqPorts[i] = entries[{deqAddresses[i], i[1:0]}];
	reg [26:0] deqEntries [WIDTH - 1:0];
	always @(*) begin : sv2v_autoblock_1
		reg [5:0] addr;
		addr = (misprReplay && !IN_branch[0] ? misprReplayIter[5:0] : baseIndex[5:0]);
		for (i = 0; i < WIDTH; i = i + 1)
			begin
				deqAddresses[addr[1:0]] = addr[5:2];
				deqEntries[i] = deqPorts[addr[1:0]];
				addr = addr + 6'b000001;
			end
	end
	always @(posedge clk) begin
		OUT_branch[0] <= 0;
		OUT_halt <= 0;
		OUT_fence <= 0;
		OUT_clearICache <= 0;
		OUT_irqTaken <= 0;
		externalIRQ <= externalIRQ | IN_irq;
		if (rst) begin
			baseIndex <= 0;
			for (i = 0; i < LENGTH; i = i + 1)
				begin
					entries[i][1] <= 0;
					entries[i][0] <= 0;
				end
			for (i = 0; i < WIDTH; i = i + 1)
				OUT_comUOp[i * 23] <= 0;
			OUT_branch[0] <= 0;
			misprReplay <= 0;
			OUT_mispredFlush <= 0;
			OUT_curFetchID <= -1;
			OUT_bpUpdate[0] <= 0;
			pcLookupEntry[1] <= 0;
			stop <= 0;
			memoryWait <= 0;
		end
		else if (IN_branch[0]) begin
			for (i = 0; i < LENGTH; i = i + 1)
				if ($signed({entries[i][16], i[5:0]} - IN_branch[43-:7]) > 0) begin
					entries[i][1] <= 0;
					entries[i][0] <= 0;
				end
			misprReplay <= 1;
			misprReplayEndSqN <= IN_branch[43-:7];
			misprReplayIter <= baseIndex;
			misprReplayEnd <= 0;
			OUT_mispredFlush <= 0;
		end
		if (!rst) begin
			OUT_bpUpdate[0] <= 0;
			if (memoryWait && !IN_MEM_busy)
				if (instrFence) begin
					instrFence <= 0;
					OUT_clearICache <= 1;
				end
				else
					memoryWait <= 0;
			pcLookupEntry[1] <= 0;
			if (pcLookupEntry[1])
				if ((((pcLookupEntry[26-:3] == 3'd4) && IN_allowBreak) || (pcLookupEntry[26-:3] == 3'd6)) || (pcLookupEntry[26-:3] == 3'd7)) begin
					if (pcLookupEntry[26-:3] == 3'd4)
						OUT_halt <= 1;
					else if (pcLookupEntry[26-:3] == 3'd7)
						memoryWait <= 1;
					else if (pcLookupEntry[26-:3] == 3'd6) begin
						instrFence <= 1;
						memoryWait <= 1;
						OUT_fence <= 1;
					end
					OUT_branch[0] <= 1;
					OUT_branch[75-:32] <= {baseIndexPC + (pcLookupEntry[2] ? 31'd1 : 31'd2), 1'b0};
					OUT_branch[43-:7] <= pcLookupEntrySqN;
					OUT_branch[22] <= 1;
					OUT_branch[36-:7] <= 0;
					OUT_branch[29-:7] <= 0;
					OUT_branch[21-:5] <= pcLookupEntry[7-:5];
					OUT_branch[16-:16] <= baseIndexHist;
					stop <= 0;
				end
				else if ((((pcLookupEntry[26-:3] == 3'd4) && !IN_allowBreak) || (pcLookupEntry[26-:3] == 3'd5)) || externalIRQ) begin
					OUT_irqTaken <= 1;
					OUT_branch[0] <= 1;
					OUT_branch[75-:32] <= IN_irqAddr;
					OUT_branch[43-:7] <= pcLookupEntrySqN;
					OUT_branch[22] <= 1;
					OUT_branch[36-:7] <= 0;
					OUT_branch[29-:7] <= 0;
					OUT_branch[21-:5] <= pcLookupEntry[7-:5];
					OUT_branch[16-:16] <= baseIndexHist;
					OUT_irqSrc <= {baseIndexPC, 1'b0};
					OUT_irqFlags <= (externalIRQ ? 3'b000 : pcLookupEntry[26-:3]);
					externalIRQ <= 0;
					stop <= 0;
				end
				else begin
					OUT_bpUpdate[0] <= 1;
					OUT_bpUpdate[58-:31] <= IN_pcReadData[58-:31];
					OUT_bpUpdate[27] <= pcLookupEntry[2];
					OUT_bpUpdate[17-:16] <= IN_pcReadData[15-:16];
					OUT_bpUpdate[26-:9] <= IN_pcReadData[24-:9];
					OUT_bpUpdate[1] <= pcLookupEntry[26-:3] == 3'd2;
				end
			if (misprReplay && !IN_branch[0]) begin
				if (misprReplayEnd) begin
					misprReplay <= 0;
					for (i = 0; i < WIDTH; i = i + 1)
						OUT_comUOp[i * 23] <= 0;
					OUT_mispredFlush <= 0;
				end
				else begin
					OUT_mispredFlush <= 1;
					for (i = 0; i < WIDTH; i = i + 1)
						if ($signed((misprReplayIter + i[6:0]) - misprReplayEndSqN) <= 0) begin
							OUT_comUOp[i * 23] <= 1;
							OUT_comUOp[(i * 23) + 22-:5] <= deqEntries[i][15-:5];
							OUT_comUOp[(i * 23) + 17-:7] <= deqEntries[i][23-:7];
							OUT_comUOp[(i * 23) + 1] <= deqEntries[i][0];
							for (j = 0; j < WIDTH_WB; j = j + 1)
								if ((IN_wbUOps[j * 88] && (IN_wbUOps[(j * 88) + 48-:5] != 0)) && (IN_wbUOps[(j * 88) + 55-:7] == deqEntries[i][23-:7]))
									OUT_comUOp[(i * 23) + 1] <= 1;
						end
						else begin
							OUT_comUOp[i * 23] <= 0;
							misprReplayEnd <= 1;
						end
					misprReplayIter <= misprReplayIter + WIDTH;
				end
			end
			else if (!stop && !IN_branch[0]) begin : sv2v_autoblock_2
				reg temp;
				reg pred;
				reg [ID_LEN - 1:0] cnt;
				reg [WIDTH - 1:0] deqMask;
				temp = 0;
				pred = 0;
				cnt = 0;
				deqMask = 0;
				for (i = 0; i < WIDTH; i = i + 1)
					begin : sv2v_autoblock_3
						reg [$clog2(LENGTH) - 1:0] id;
						id = baseIndex[ID_LEN - 1:0] + i[ID_LEN - 1:0];
						if ((!temp && deqEntries[i][0]) && (!pred || (deqEntries[i][26-:3] == 3'd0))) begin
							OUT_comUOp[(i * 23) + 22-:5] <= deqEntries[i][15-:5];
							OUT_comUOp[(i * 23) + 17-:7] <= deqEntries[i][23-:7];
							OUT_comUOp[(i * 23) + 10-:7] <= {deqEntries[i][16], id[5:0]};
							OUT_comUOp[(i * 23) + 3] <= ((deqEntries[i][26-:3] == 3'd1) || (deqEntries[i][26-:3] == 3'd2)) || (deqEntries[i][26-:3] == 3'd3);
							OUT_comUOp[(i * 23) + 1] <= deqEntries[i][2];
							OUT_comUOp[i * 23] <= 1;
							OUT_curFetchID <= deqEntries[i][7-:5];
							deqMask[id[1:0]] = 1;
							if (|deqEntries[i][26:25] || externalIRQ) begin
								pcLookupEntry <= deqEntries[i];
								pcLookupEntrySqN <= {deqEntries[i][16], id[5:0]};
								pred = 1;
							end
							if (deqEntries[i][26] || externalIRQ) begin
								if (deqEntries[i][26-:3] == 3'd5)
									OUT_comUOp[(i * 23) + 22-:5] <= 0;
								stop <= 1;
								temp = 1;
							end
							entries[id][1] <= 0;
							entries[id][0] <= 0;
							cnt = cnt + 1;
						end
						else begin
							temp = 1;
							OUT_comUOp[i * 23] <= 0;
						end
					end
				baseIndex <= baseIndex + cnt;
			end
			else
				for (i = 0; i < WIDTH; i = i + 1)
					OUT_comUOp[i * 23] <= 0;
			for (i = 0; i < WIDTH; i = i + 1)
				if (rnUOpValidSorted[i] && !IN_branch[0]) begin : sv2v_autoblock_4
					reg [5:0] id;
					id = {rnUOpSorted[i][50:47], i[1:0]};
					entries[id][1] <= 1;
					entries[id][23-:7] <= rnUOpSorted[i][44-:7];
					entries[id][15-:5] <= rnUOpSorted[i][37-:5];
					entries[id][16] <= rnUOpSorted[i][51];
					entries[id][2] <= rnUOpSorted[i][0];
					entries[id][7-:5] <= rnUOpSorted[i][26-:5];
					entries[id][0] <= rnUOpSorted[i][4-:4] == 4'd8;
					entries[id][26-:3] <= 3'd0;
					entries[id][10-:3] <= rnUOpSorted[i][21-:3];
				end
			for (i = 0; i < WIDTH_WB; i = i + 1)
				if (IN_wbUOps[i * 88] && (!IN_branch[0] || ($signed(IN_wbUOps[(i * 88) + 43-:7] - IN_branch[43-:7]) <= 0))) begin : sv2v_autoblock_5
					reg [$clog2(LENGTH) - 1:0] id;
					id = IN_wbUOps[(i * 88) + ((ID_LEN + 36) >= 37 ? ID_LEN + 36 : ((ID_LEN + 36) + ((ID_LEN + 36) >= 37 ? ID_LEN + 0 : 38 - (ID_LEN + 36))) - 1)-:((ID_LEN + 36) >= 37 ? ID_LEN + 0 : 38 - (ID_LEN + 36))];
					entries[id][0] <= 1;
					entries[id][26-:3] <= IN_wbUOps[(i * 88) + 4-:3];
				end
		end
	end
endmodule
