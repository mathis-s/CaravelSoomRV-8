module ICacheTable (
	clk,
	rst,
	IN_lookupValid,
	IN_lookupPC,
	OUT_lookupAddress,
	OUT_stall,
	OUT_MC_if,
	IN_MC_cacheID,
	IN_MC_progress,
	IN_MC_busy
);
	parameter NUM_ICACHE_LINES = 8;
	input wire clk;
	input wire rst;
	input wire IN_lookupValid;
	input wire [30:0] IN_lookupPC;
	output reg [27:0] OUT_lookupAddress;
	output wire OUT_stall;
	output reg [41:0] OUT_MC_if;
	input wire IN_MC_cacheID;
	input wire [9:0] IN_MC_progress;
	input wire IN_MC_busy;
	integer i;
	reg [24:0] icacheTable [NUM_ICACHE_LINES - 1:0];
	reg cacheEntryFound;
	reg [$clog2(NUM_ICACHE_LINES) - 1:0] cacheEntryIndex;
	reg [6:0] lastProgress;
	reg [30:0] loadAddr;
	reg loading;
	reg [$clog2(NUM_ICACHE_LINES) - 1:0] lruPointer;
	reg waitCycle;
	always @(*) begin
		cacheEntryFound = 0;
		cacheEntryIndex = 0;
		OUT_lookupAddress = 28'bxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		for (i = 0; i < NUM_ICACHE_LINES; i = i + 1)
			if (icacheTable[i][1] && (icacheTable[i][24-:23] == IN_lookupPC[30:8])) begin
				OUT_lookupAddress = {i[22:0], IN_lookupPC[7:3]};
				cacheEntryFound = 1;
				cacheEntryIndex = i[$clog2(NUM_ICACHE_LINES) - 1:0];
			end
		if ((((0 && loading) && !waitCycle) && (IN_lookupPC[30:8] == loadAddr[30:8])) && ({lastProgress, 1'b0} > {IN_lookupPC[7:2], 2'b11})) begin
			cacheEntryFound = 1;
			cacheEntryIndex = lruPointer;
		end
	end
	assign OUT_stall = !cacheEntryFound || loading;
	always @(posedge clk) begin
		waitCycle <= 0;
		lastProgress <= IN_MC_progress[6:0];
		if (rst) begin
			for (i = 0; i < NUM_ICACHE_LINES; i = i + 1)
				icacheTable[i][1] <= 0;
			lruPointer <= 0;
			loading <= 0;
			OUT_MC_if[41] <= 0;
			OUT_MC_if[40] <= 0;
		end
		else begin
			OUT_MC_if[41] <= 0;
			OUT_MC_if[40] <= 0;
			if (IN_lookupValid && cacheEntryFound)
				icacheTable[cacheEntryIndex][0] <= 1;
			if ((loading && waitCycle) && (IN_MC_cacheID != 1))
				loading <= 0;
			else if ((loading && !IN_MC_busy) && !waitCycle) begin
				icacheTable[lruPointer][24-:23] <= loadAddr[30:8];
				icacheTable[lruPointer][1] <= 1;
				icacheTable[lruPointer][0] <= 1;
				lruPointer <= lruPointer + 1;
				loading <= 0;
			end
			else if ((!loading && !IN_MC_busy) && !cacheEntryFound) begin
				OUT_MC_if[41] <= 1;
				OUT_MC_if[40] <= 0;
				OUT_MC_if[39-:10] <= {lruPointer, 7'b0000000};
				OUT_MC_if[29-:30] <= {IN_lookupPC[30:8], 7'b0000000};
				icacheTable[lruPointer][1] <= 0;
				loadAddr <= IN_lookupPC;
				loading <= 1;
				waitCycle <= 1;
			end
			else if (icacheTable[lruPointer][1] && icacheTable[lruPointer][0])
				lruPointer <= lruPointer + 1;
		end
	end
endmodule
