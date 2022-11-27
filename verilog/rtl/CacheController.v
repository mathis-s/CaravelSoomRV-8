module CacheController (
	clk,
	rst,
	IN_branch,
	IN_SQ_empty,
	OUT_stall,
	IN_uopLd,
	OUT_uopLd,
	IN_uopSt,
	OUT_uopSt,
	OUT_MC_ce,
	OUT_MC_we,
	OUT_MC_sramAddr,
	OUT_MC_extAddr,
	IN_MC_progress,
	IN_MC_cacheID,
	IN_MC_busy,
	IN_fence,
	OUT_fenceBusy
);
	parameter SIZE = 16;
	parameter NUM_UOPS = 2;
	parameter QUEUE_SIZE = 4;
	input wire clk;
	input wire rst;
	input wire [75:0] IN_branch;
	input wire IN_SQ_empty;
	output wire [NUM_UOPS - 1:0] OUT_stall;
	input wire [162:0] IN_uopLd;
	output reg [162:0] OUT_uopLd;
	input wire [68:0] IN_uopSt;
	output reg [68:0] OUT_uopSt;
	output reg OUT_MC_ce;
	output reg OUT_MC_we;
	output reg [9:0] OUT_MC_sramAddr;
	output reg [29:0] OUT_MC_extAddr;
	input wire [9:0] IN_MC_progress;
	input wire [0:0] IN_MC_cacheID;
	input wire IN_MC_busy;
	input wire IN_fence;
	output wire OUT_fenceBusy;
	integer i;
	integer j;
	reg [26:0] ctable [SIZE - 1:0];
	reg freeEntryAvail;
	reg evicting;
	reg loading;
	reg [$clog2(SIZE) - 1:0] freeEntryID;
	reg [$clog2(SIZE) - 1:0] lruPointer;
	reg [$clog2(SIZE) - 1:0] evictingID;
	reg [162:0] cmissUOpLd;
	reg waitCycle;
	assign OUT_stall[0] = cmissUOpLd[0] || waitCycle;
	reg [68:0] cmissUOpSt;
	reg [1:0] evictionRq;
	assign OUT_stall[1] = (((cmissUOpSt[0] || loading) || evicting) || waitCycle) || (evictionRq != 2'd0);
	reg cacheTableEntryFound [NUM_UOPS - 1:0];
	reg [$clog2(SIZE) - 1:0] cacheTableEntry [NUM_UOPS - 1:0];
	always @(*) begin
		cacheTableEntryFound[0] = 0;
		cacheTableEntry[0] = 4'bxxxx;
		for (j = 0; j < SIZE; j = j + 1)
			if (ctable[j][2] && (ctable[j][26-:24] == IN_uopLd[162:139])) begin
				cacheTableEntryFound[0] = 1;
				cacheTableEntry[0] = j[$clog2(SIZE) - 1:0];
			end
		cacheTableEntryFound[1] = 0;
		cacheTableEntry[1] = 4'bxxxx;
		for (j = 0; j < SIZE; j = j + 1)
			if (ctable[j][2] && (ctable[j][26-:24] == IN_uopSt[68:45])) begin
				cacheTableEntryFound[1] = 1;
				cacheTableEntry[1] = j[$clog2(SIZE) - 1:0];
			end
	end
	reg fenceScheduled;
	reg fenceActive;
	assign OUT_fenceBusy = (fenceScheduled || fenceActive) || evicting;
	reg empty;
	always @(*) begin
		empty = 1;
		for (i = 0; i < SIZE; i = i + 1)
			if (ctable[i][2])
				empty = 0;
	end
	reg setDirty;
	reg [$clog2(SIZE) - 1:0] evictionRqID;
	reg evictionRqActive;
	reg outHistory;
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < SIZE; i = i + 1)
				begin
					ctable[i][2] <= 0;
					ctable[i][0] <= 0;
				end
			lruPointer <= 0;
			freeEntryAvail <= 1;
			freeEntryID <= 0;
			OUT_MC_ce <= 0;
			OUT_MC_we <= 0;
			evicting <= 0;
			loading <= 0;
			cmissUOpLd[0] <= 0;
			cmissUOpSt[0] <= 0;
			waitCycle <= 0;
			OUT_uopLd[0] <= 0;
			OUT_uopSt[0] <= 0;
			evictionRq <= 2'd0;
		end
		else begin
			OUT_MC_ce <= 0;
			OUT_MC_we <= 0;
			waitCycle <= 0;
			if (fenceActive) begin
				if (!ctable[lruPointer][2])
					lruPointer <= lruPointer + 1;
			end
			else if (ctable[lruPointer][2] && ctable[lruPointer][0]) begin
				if (ctable[lruPointer][2])
					ctable[lruPointer][0] <= 0;
				lruPointer <= lruPointer + 1;
			end
			if (!loading)
				if (evicting && (IN_MC_cacheID != 0)) begin
					evicting <= 0;
					ctable[evictingID][2] <= 1;
				end
				else if ((evicting && !waitCycle) && !IN_MC_busy) begin
					if (evictionRqActive)
						evictionRq <= 2'd0;
					else
						freeEntryAvail <= 1;
					evicting <= 0;
				end
				else if (((!evicting && !IN_MC_busy) && !waitCycle) && (evictionRq != 2'd0)) begin
					if (!ctable[evictionRqID][2])
						evictionRq <= 2'd0;
					else if ((((!IN_uopLd[0] || OUT_stall[0]) && !OUT_uopLd[0]) && (!IN_uopSt[0] || OUT_stall[1])) && !OUT_uopSt[0]) begin
						if (evictionRq != 2'd1) begin
							ctable[evictionRqID][2] <= 0;
							ctable[evictionRqID][0] <= 0;
						end
						else
							ctable[evictionRqID][1] <= 0;
						if (ctable[evictionRqID][1] && (evictionRq != 2'd3)) begin
							OUT_MC_ce <= 1;
							OUT_MC_we <= 1;
							OUT_MC_sramAddr <= {evictionRqID, 6'b000000};
							OUT_MC_extAddr <= {ctable[evictionRqID][26-:24], 6'b000000};
							evicting <= 1;
							waitCycle <= 1;
							evictionRqActive <= 1;
							evictingID <= evictionRqID;
						end
						else
							evictionRq <= 2'd0;
					end
				end
				else if ((((!freeEntryAvail || fenceActive) && !evicting) && !IN_MC_busy) && !waitCycle)
					if (!ctable[lruPointer][2]) begin
						freeEntryAvail <= 1;
						freeEntryID <= lruPointer;
					end
					else if (((((!ctable[lruPointer][0] || fenceActive) && (!IN_uopLd[0] || OUT_stall[0])) && !OUT_uopLd[0]) && (!IN_uopSt[0] || OUT_stall[1])) && !OUT_uopSt[0]) begin
						ctable[lruPointer][2] <= 0;
						ctable[lruPointer][0] <= 0;
						freeEntryID <= lruPointer;
						if (ctable[lruPointer][1]) begin
							OUT_MC_ce <= 1;
							OUT_MC_we <= 1;
							OUT_MC_sramAddr <= {lruPointer, 6'b000000};
							OUT_MC_extAddr <= {ctable[lruPointer][26-:24], 6'b000000};
							evicting <= 1;
							waitCycle <= 1;
							evictionRqActive <= 0;
							evictingID <= lruPointer;
						end
						else
							freeEntryAvail <= 1;
					end
			if (IN_branch[0] && ($signed(cmissUOpLd[44-:7] - IN_branch[43-:7]) > 0))
				cmissUOpLd[0] <= 0;
			if ((!OUT_stall[0] && IN_uopLd[0]) && (!IN_branch[0] || ($signed(IN_uopLd[44-:7] - IN_branch[43-:7]) <= 0))) begin
				if ((IN_uopLd[2] || cacheTableEntryFound[0]) || (IN_uopLd[162:155] >= 8'hff)) begin
					OUT_uopLd <= IN_uopLd;
					if ((IN_uopLd[162:155] < 8'hff) && !IN_uopLd[2]) begin
						OUT_uopLd[162-:32] <= {20'b00000000000000000000, cacheTableEntry[0], IN_uopLd[138:131]};
						ctable[cacheTableEntry[0]][0] <= 1;
					end
				end
				else if (((loading && !waitCycle) && (IN_uopLd[162:139] == OUT_MC_extAddr[29:6])) && (!IN_MC_busy || (IN_MC_progress[5:0] > IN_uopLd[138:133]))) begin
					OUT_uopLd <= IN_uopLd;
					OUT_uopLd[162:131] <= {20'b00000000000000000000, freeEntryID, IN_uopLd[138:131]};
				end
				else begin
					cmissUOpLd <= IN_uopLd;
					OUT_uopLd[0] <= 0;
				end
			end
			else if (((((cmissUOpLd[0] && (!IN_branch[0] || ($signed(cmissUOpLd[44-:7] - IN_branch[43-:7]) <= 0))) && loading) && !waitCycle) && (cmissUOpLd[162:139] == OUT_MC_extAddr[29:6])) && (!IN_MC_busy || (IN_MC_progress[5:0] > cmissUOpLd[138:133]))) begin
				OUT_uopLd <= cmissUOpLd;
				OUT_uopLd[162-:32] <= {20'b00000000000000000000, freeEntryID, cmissUOpLd[138:131]};
				cmissUOpLd[0] <= 0;
			end
			else
				OUT_uopLd[0] <= 0;
			if (!OUT_stall[1] && IN_uopSt[0]) begin
				if (IN_uopSt[4-:4] == 0) begin
					if (cacheTableEntryFound[1]) begin
						evictionRqID <= cacheTableEntry[1];
						case (IN_uopSt[6:5])
							0: evictionRq <= 2'd1;
							1: evictionRq <= 2'd3;
							default: evictionRq <= 2'd2;
						endcase
					end
					OUT_uopSt[0] <= 0;
				end
				else if (cacheTableEntryFound[1] || (IN_uopSt[68:61] >= 8'hfe)) begin
					OUT_uopSt <= IN_uopSt;
					if (IN_uopSt[68:61] < 8'hfe) begin
						OUT_uopSt[68-:32] <= {20'b00000000000000000000, cacheTableEntry[1], IN_uopSt[44:37]};
						ctable[cacheTableEntry[1]][0] <= 1;
						ctable[cacheTableEntry[1]][1] <= 1;
					end
				end
				else begin
					cmissUOpSt <= IN_uopSt;
					OUT_uopSt[0] <= 0;
				end
			end
			else if ((((cmissUOpSt[0] && loading) && !waitCycle) && (cmissUOpSt[68:45] == OUT_MC_extAddr[29:6])) && !IN_MC_busy) begin
				OUT_uopSt <= cmissUOpSt;
				OUT_uopSt[68-:32] <= {20'b00000000000000000000, freeEntryID, cmissUOpSt[44:37]};
				cmissUOpSt[0] <= 0;
				setDirty = 1;
			end
			else
				OUT_uopSt[0] <= 0;
			if (loading && (IN_MC_cacheID != 0)) begin
				loading <= 0;
				ctable[freeEntryID][0] <= 0;
				freeEntryAvail <= 1;
			end
			else if (loading && !waitCycle) begin
				if (!IN_MC_busy) begin
					loading <= 0;
					ctable[freeEntryID][2] <= 1;
					ctable[freeEntryID][0] <= 1;
					ctable[freeEntryID][1] <= setDirty;
				end
			end
			else if ((((!loading && freeEntryAvail) && !IN_branch[0]) && !IN_MC_busy) && (evictionRq == 2'd0))
				if (cmissUOpLd[0]) begin
					OUT_MC_ce <= 1;
					OUT_MC_we <= 0;
					OUT_MC_sramAddr <= {freeEntryID, 6'b000000};
					OUT_MC_extAddr <= {cmissUOpLd[162:139], 6'b000000};
					ctable[freeEntryID][0] <= 1;
					ctable[freeEntryID][26-:24] <= cmissUOpLd[162:139];
					loading <= 1;
					freeEntryAvail <= 0;
					waitCycle <= 1;
					setDirty = 0;
				end
				else if (cmissUOpSt[0]) begin
					OUT_MC_ce <= 1;
					OUT_MC_we <= 0;
					OUT_MC_sramAddr <= {freeEntryID, 6'b000000};
					OUT_MC_extAddr <= {cmissUOpSt[68:45], 6'b000000};
					ctable[freeEntryID][0] <= 1;
					ctable[freeEntryID][26-:24] <= cmissUOpSt[68:45];
					loading <= 1;
					freeEntryAvail <= 0;
					waitCycle <= 1;
					setDirty = 0;
				end
			if (fenceActive && empty)
				fenceActive <= 0;
			else if (((((fenceScheduled && IN_SQ_empty) && (((!IN_uopLd[0] && !IN_uopSt[0]) && !OUT_uopLd[0]) && !OUT_uopSt[0])) && !loading) && !evicting) && (evictionRq == 2'd0)) begin
				fenceActive <= 1;
				fenceScheduled <= 0;
			end
			else if (IN_fence)
				fenceScheduled <= 1;
		end
endmodule
