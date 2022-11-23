module StoreQueue (
	clk,
	rst,
	IN_disable,
	IN_stallLd,
	OUT_empty,
	IN_uopSt,
	IN_uopLd,
	IN_curSqN,
	IN_branch,
	OUT_uopSt,
	OUT_lookupData,
	OUT_lookupMask,
	OUT_flush,
	OUT_maxStoreSqN,
	IN_IO_busy
);
	parameter NUM_PORTS = 2;
	parameter NUM_PORTS_LD = 1;
	parameter NUM_ENTRIES = 24;
	input wire clk;
	input wire rst;
	input wire IN_disable;
	input wire IN_stallLd;
	output reg OUT_empty;
	input wire [162:0] IN_uopSt;
	input wire [162:0] IN_uopLd;
	input wire [6:0] IN_curSqN;
	input wire [75:0] IN_branch;
	output reg [68:0] OUT_uopSt;
	output reg [31:0] OUT_lookupData;
	output reg [3:0] OUT_lookupMask;
	output wire OUT_flush;
	output reg [6:0] OUT_maxStoreSqN;
	input wire IN_IO_busy;
	integer i;
	integer j;
	reg [74:0] entries [NUM_ENTRIES - 1:0];
	reg [6:0] baseIndex;
	reg didCSRwrite;
	reg empty;
	always @(*) begin
		empty = 1;
		for (i = 0; i < NUM_ENTRIES; i = i + 1)
			if (entries[i][74])
				empty = 0;
	end
	reg [74:0] evicted [1:0];
	reg [3:0] lookupMask;
	reg [31:0] lookupData;
	always @(*) begin
		lookupMask = 0;
		lookupData = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		for (i = 0; i < 2; i = i + 1)
			if ((IN_uopLd[89] && evicted[i][74]) && (evicted[i][65-:30] == IN_uopLd[162:133])) begin
				if (evicted[i][0])
					lookupData[7:0] = evicted[i][11:4];
				if (evicted[i][1])
					lookupData[15:8] = evicted[i][19:12];
				if (evicted[i][2])
					lookupData[23:16] = evicted[i][27:20];
				if (evicted[i][3])
					lookupData[31:24] = evicted[i][35:28];
				lookupMask = lookupMask | evicted[i][3-:4];
			end
		for (i = 0; i < NUM_ENTRIES; i = i + 1)
			if (((IN_uopLd[89] && entries[i][74]) && (entries[i][65-:30] == IN_uopLd[162:133])) && (($signed(entries[i][72-:7] - IN_uopLd[44-:7]) < 0) || entries[i][73])) begin
				if (entries[i][0])
					lookupData[7:0] = entries[i][11:4];
				if (entries[i][1])
					lookupData[15:8] = entries[i][19:12];
				if (entries[i][2])
					lookupData[23:16] = entries[i][27:20];
				if (entries[i][3])
					lookupData[31:24] = entries[i][35:28];
				lookupMask = lookupMask | entries[i][3-:4];
			end
	end
	reg flushing;
	assign OUT_flush = flushing;
	reg doingEnqueue;
	always @(posedge clk) begin
		didCSRwrite <= 0;
		doingEnqueue = 0;
		if (rst) begin
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				entries[i][74] <= 0;
			evicted[0][74] <= 0;
			evicted[1][74] <= 0;
			baseIndex = 0;
			OUT_maxStoreSqN <= (baseIndex + NUM_ENTRIES[6:0]) - 1;
			OUT_empty <= 1;
			OUT_uopSt[0] <= 0;
			flushing <= 0;
		end
		else begin
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				if ($signed(IN_curSqN - entries[i][72-:7]) > 0)
					entries[i][73] <= 1;
			if ((((!IN_disable && entries[0][74]) && !IN_branch[0]) && entries[0][73]) && (!(IN_IO_busy || didCSRwrite) || (entries[0][65:58] != 8'hff))) begin
				entries[NUM_ENTRIES - 1][74] <= 0;
				didCSRwrite <= entries[0][65:58] == 8'hff;
				if (!flushing)
					baseIndex = baseIndex + 1;
				OUT_uopSt[0] <= 1;
				OUT_uopSt[68-:32] <= {entries[0][65-:30], 2'b00};
				OUT_uopSt[36-:32] <= entries[0][35-:32];
				OUT_uopSt[4-:4] <= entries[0][3-:4];
				for (i = 1; i < NUM_ENTRIES; i = i + 1)
					begin
						entries[i - 1] <= entries[i];
						if ($signed(IN_curSqN - entries[i][72-:7]) > 0)
							entries[i - 1][73] <= 1;
					end
				evicted[1] <= entries[0];
				evicted[0] <= evicted[1];
			end
			else if (!IN_disable)
				OUT_uopSt[0] <= 0;
			if (IN_branch[0]) begin
				for (i = 0; i < NUM_ENTRIES; i = i + 1)
					if (($signed(entries[i][72-:7] - IN_branch[43-:7]) > 0) && !entries[i][73])
						entries[i][74] <= 0;
				if (IN_branch[22])
					baseIndex = IN_branch[36-:7] + 1;
				flushing <= IN_branch[22];
			end
			if ((IN_uopSt[0] && (!IN_branch[0] || ($signed(IN_uopSt[44-:7] - IN_branch[43-:7]) <= 0))) && !IN_uopSt[2]) begin : sv2v_autoblock_1
				reg [$clog2(NUM_ENTRIES) - 1:0] index;
				index = IN_uopSt[$clog2(NUM_ENTRIES) + 30:31] - baseIndex[$clog2(NUM_ENTRIES) - 1:0];
				entries[index][74] <= 1;
				entries[index][73] <= 0;
				entries[index][72-:7] <= IN_uopSt[44-:7];
				entries[index][65-:30] <= IN_uopSt[162:133];
				entries[index][35-:32] <= IN_uopSt[130-:32];
				entries[index][3-:4] <= IN_uopSt[98-:4];
				doingEnqueue = 1;
			end
			if (flushing)
				for (i = 0; i < 3; i = i + 1)
					evicted[i][74] <= 0;
			OUT_empty <= empty && !doingEnqueue;
			if (OUT_empty)
				flushing <= 0;
			OUT_maxStoreSqN <= (baseIndex + NUM_ENTRIES[6:0]) - 1;
			if (!IN_stallLd) begin
				OUT_lookupData <= lookupData;
				OUT_lookupMask <= lookupMask;
			end
		end
	end
endmodule
