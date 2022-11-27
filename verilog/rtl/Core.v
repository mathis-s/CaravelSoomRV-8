module Core (
	clk,
	rst,
	en,
	IN_instrRaw,
	OUT_MEM_writeAddr,
	OUT_MEM_writeData,
	OUT_MEM_writeEnable,
	OUT_MEM_writeMask,
	OUT_MEM_readEnable,
	OUT_MEM_readAddr,
	IN_MEM_readData,
	OUT_instrAddr,
	OUT_instrReadEnable,
	OUT_halt,
	OUT_SPI_cs,
	OUT_SPI_clk,
	OUT_SPI_mosi,
	IN_SPI_miso,
	OUT_MC_ce,
	OUT_MC_we,
	OUT_MC_cacheID,
	OUT_MC_sramAddr,
	OUT_MC_extAddr,
	IN_MC_progress,
	IN_MC_busy
);
	parameter NUM_UOPS = 2;
	parameter NUM_WBS = 4;
	input wire clk;
	input wire rst;
	input wire en;
	input wire [127:0] IN_instrRaw;
	output wire [29:0] OUT_MEM_writeAddr;
	output wire [31:0] OUT_MEM_writeData;
	output wire OUT_MEM_writeEnable;
	output wire [3:0] OUT_MEM_writeMask;
	output wire OUT_MEM_readEnable;
	output wire [29:0] OUT_MEM_readAddr;
	input wire [31:0] IN_MEM_readData;
	output wire [27:0] OUT_instrAddr;
	output wire OUT_instrReadEnable;
	output wire OUT_halt;
	output wire OUT_SPI_cs;
	output wire OUT_SPI_clk;
	output wire OUT_SPI_mosi;
	input wire IN_SPI_miso;
	output reg OUT_MC_ce;
	output reg OUT_MC_we;
	output reg [0:0] OUT_MC_cacheID;
	output reg [9:0] OUT_MC_sramAddr;
	output reg [29:0] OUT_MC_extAddr;
	input wire [9:0] IN_MC_progress;
	input wire IN_MC_busy;
	wire [41:0] CC_MC_if;
	wire [41:0] PC_MC_if;
	always @(*)
		if (PC_MC_if[41]) begin
			OUT_MC_ce = PC_MC_if[41];
			OUT_MC_we = PC_MC_if[40];
			OUT_MC_sramAddr = PC_MC_if[39-:10];
			OUT_MC_extAddr = PC_MC_if[29-:30];
			OUT_MC_cacheID = 1;
		end
		else begin
			OUT_MC_ce = CC_MC_if[41];
			OUT_MC_we = CC_MC_if[40];
			OUT_MC_sramAddr = CC_MC_if[39-:10];
			OUT_MC_extAddr = CC_MC_if[29-:30];
			OUT_MC_cacheID = 0;
		end
	integer i;
	wire [(NUM_WBS * 88) - 1:0] wbUOp;
	wire [NUM_WBS - 1:0] wbHasResult;
	wire wbHasResult_int [NUM_WBS - 1:0];
	assign wbHasResult[0] = wbUOp[0] && (wbUOp[48-:5] != 0);
	assign wbHasResult[1] = wbUOp[88] && (wbUOp[136-:5] != 0);
	assign wbHasResult[2] = wbUOp[176] && (wbUOp[224-:5] != 0);
	assign wbHasResult[3] = wbUOp[264] && (wbUOp[312-:5] != 0);
	assign wbHasResult_int[0] = wbUOp[0] && (wbUOp[48-:5] != 0);
	assign wbHasResult_int[1] = wbUOp[88] && (wbUOp[136-:5] != 0);
	assign wbHasResult_int[2] = wbUOp[176] && (wbUOp[224-:5] != 0);
	assign wbHasResult_int[3] = wbUOp[264] && (wbUOp[312-:5] != 0);
	wire [91:0] comUOps;
	wire comValid [3:0];
	wire frontendEn;
	wire ifetchEn;
	reg [2:0] stateValid;
	assign OUT_instrReadEnable = !(ifetchEn && stateValid[0]);
	reg [127:0] instrRawBackup;
	reg useInstrRawBackup;
	wire [127:0] instrRaw = (useInstrRawBackup ? instrRawBackup : IN_instrRaw);
	always @(posedge clk)
		if (rst)
			useInstrRawBackup <= 0;
		else if (!(ifetchEn && stateValid[0])) begin
			instrRawBackup <= instrRaw;
			useInstrRawBackup <= 1;
		end
		else
			useInstrRawBackup <= 0;
	wire [303:0] branchProvs;
	wire [75:0] branch;
	wire mispredFlush;
	wire [6:0] RN_nextSqN;
	wire [6:0] ROB_curSqN;
	BranchSelector bsel(
		.clk(clk),
		.rst(rst),
		.IN_branches(branchProvs),
		.OUT_branch(branch),
		.IN_ROB_curSqN(ROB_curSqN),
		.IN_RN_nextSqN(RN_nextSqN),
		.IN_mispredFlush(mispredFlush)
	);
	wire [31:0] PC_pc;
	wire BP_branchTaken;
	wire BP_isJump;
	wire [31:0] BP_branchSrc;
	wire [31:0] BP_branchDst;
	wire [15:0] BP_branchHistory;
	wire [8:0] BP_info;
	wire BP_multipleBranches;
	wire BP_branchFound;
	wire BP_branchCompr;
	wire [431:0] IF_instrs;
	wire [24:0] PC_readAddress;
	wire [294:0] PC_readData;
	wire PC_stall;
	wire DEC_branch;
	wire [30:0] DEC_branchDst;
	wire [4:0] DEC_branchFetchID;
	wire ROB_clearICache;
	wire [4:0] ROB_curFetchID;
	ProgramCounter progCnt(
		.clk(clk),
		.en0(stateValid[0] && ifetchEn),
		.en1(stateValid[1] && ifetchEn),
		.rst(rst),
		.IN_pc((branch[0] ? branch[75-:32] : {DEC_branchDst, 1'b0})),
		.IN_write(branch[0] || DEC_branch),
		.IN_branchTaken(branch[0]),
		.IN_fetchID((branch[0] ? branch[21-:5] : DEC_branchFetchID)),
		.IN_instr(instrRaw),
		.IN_clearICache(ROB_clearICache),
		.IN_BP_branchTaken(BP_branchTaken),
		.IN_BP_isJump(BP_isJump),
		.IN_BP_branchSrc(BP_branchSrc),
		.IN_BP_branchDst(BP_branchDst),
		.IN_BP_history(BP_branchHistory),
		.IN_BP_info(BP_info),
		.IN_BP_multipleBranches(BP_multipleBranches),
		.IN_BP_branchFound(BP_branchFound),
		.IN_BP_branchCompr(BP_branchCompr),
		.IN_pcReadAddr(PC_readAddress),
		.OUT_pcReadData(PC_readData),
		.IN_ROB_curFetchID(ROB_curFetchID),
		.OUT_pcRaw(PC_pc),
		.OUT_instrAddr(OUT_instrAddr),
		.OUT_instrs(IF_instrs),
		.OUT_stall(PC_stall),
		.OUT_MC_if(PC_MC_if),
		.IN_MC_cacheID(OUT_MC_cacheID),
		.IN_MC_progress(IN_MC_progress),
		.IN_MC_busy(IN_MC_busy || CC_MC_if[41])
	);
	wire [133:0] BP_btUpdates;
	wire [58:0] ROB_bpUpdate;
	BranchPredictor bp(
		.clk(clk),
		.rst(rst),
		.IN_clearICache(ROB_clearICache),
		.IN_mispredFlush(mispredFlush),
		.IN_branch(branch),
		.IN_pcValid(stateValid[0] && ifetchEn),
		.IN_pc(PC_pc),
		.OUT_branchTaken(BP_branchTaken),
		.OUT_isJump(BP_isJump),
		.OUT_branchSrc(BP_branchSrc),
		.OUT_branchDst(BP_branchDst),
		.OUT_branchHistory(BP_branchHistory),
		.OUT_branchInfo(BP_info),
		.OUT_multipleBranches(BP_multipleBranches),
		.OUT_branchFound(BP_branchFound),
		.OUT_branchCompr(BP_branchCompr),
		.IN_btUpdates(BP_btUpdates),
		.IN_bpUpdate(ROB_bpUpdate)
	);
	wire [125:0] IBP_updates;
	wire [30:0] IBP_predDst;
	IndirectBranchPredictor ibp(
		.clk(clk),
		.rst(rst),
		.IN_clearICache(ROB_clearICache),
		.IN_ibUpdates(IBP_updates),
		.OUT_predDst(IBP_predDst)
	);
	always @(posedge clk)
		if (rst)
			stateValid <= 3'b000;
		else if (branch[0] || DEC_branch)
			stateValid <= 3'b000;
		else if (ifetchEn)
			stateValid <= {stateValid[1:0], 1'b1};
	wire PD_full;
	wire [279:0] PD_instrs;
	wire RN_stall;
	wire FUSE_full = !frontendEn || RN_stall;
	PreDecode preDec(
		.clk(clk),
		.rst(rst),
		.ifetchValid(stateValid[2] && ifetchEn),
		.outEn(!FUSE_full),
		.OUT_full(PD_full),
		.mispred(branch[0] || DEC_branch),
		.IN_instrs(IF_instrs),
		.OUT_instrs(PD_instrs)
	);
	wire ROB_disableIFetch;
	assign ifetchEn = (!PD_full && !PC_stall) && !ROB_disableIFetch;
	wire [271:0] DE_uop;
	wire [7:0] CR_mode;
	InstrDecoder idec(
		.clk(clk),
		.rst(rst),
		.IN_invalidate(branch[0]),
		.en(!FUSE_full),
		.IN_instrs(PD_instrs),
		.IN_indirBranchTarget(IBP_predDst),
		.IN_enCustom(!CR_mode[3'd7]),
		.OUT_decBranch(DEC_branch),
		.OUT_decBranchDst(DEC_branchDst),
		.OUT_decBranchFetchID(DEC_branchFetchID),
		.OUT_uop(DE_uop)
	);
	wire [403:0] RN_uop;
	wire [3:0] RN_uopValid;
	wire [6:0] RN_nextLoadSqN;
	wire [6:0] RN_nextStoreSqN;
	wire [3:0] RN_uopOrdering;
	Rename rn(
		.clk(clk),
		.en(!branch[0] && !mispredFlush),
		.frontEn(frontendEn),
		.rst(rst),
		.OUT_stall(RN_stall),
		.IN_uop(DE_uop),
		.IN_comUOp(comUOps),
		.IN_wbHasResult(wbHasResult),
		.IN_wbUOp(wbUOp),
		.IN_branchTaken(branch[0]),
		.IN_branchFlush(branch[22]),
		.IN_branchSqN(branch[43-:7]),
		.IN_branchLoadSqN(branch[29-:7]),
		.IN_branchStoreSqN(branch[36-:7]),
		.IN_mispredFlush(mispredFlush),
		.OUT_uopValid(RN_uopValid),
		.OUT_uop(RN_uop),
		.OUT_uopOrdering(RN_uopOrdering),
		.OUT_nextSqN(RN_nextSqN),
		.OUT_nextLoadSqN(RN_nextLoadSqN),
		.OUT_nextStoreSqN(RN_nextStoreSqN)
	);
	wire [3:0] RV_uopValid;
	wire [403:0] RV_uop;
	wire [3:0] stall;
	assign stall[0] = 0;
	assign stall[1] = 0;
	wire IQ0_full;
	wire DIV_busy;
	wire [795:0] LD_uop;
	wire [31:0] enabledXUs;
	wire DIV_doNotIssue = (DIV_busy || (LD_uop[0] && enabledXUs[4])) || (RV_uopValid[0] && (RV_uop[4-:4] == 4'd4));
	wire [6:0] LB_maxLoadSqN;
	wire [6:0] LSU_loadFwdTag;
	wire LSU_loadFwdValid;
	wire [6:0] SQ_maxStoreSqN;
	IssueQueue #(
		.SIZE(8),
		.NUM_UOPS(4),
		.RESULT_BUS_COUNT(4),
		.IMM_BITS(32),
		.FU0(4'd0),
		.FU1(4'd4),
		.FU2(4'd5),
		.FU3(4'd5),
		.FU0_SPLIT(1),
		.FU0_ORDER(0),
		.FU1_DLY(33)
	) iq0(
		.clk(clk),
		.rst(rst),
		.frontEn(((frontendEn && !branch[0]) && !mispredFlush) && !RN_stall),
		.IN_stall(stall[0]),
		.IN_doNotIssueFU1(DIV_doNotIssue),
		.IN_doNotIssueFU2(1'b0),
		.IN_uopValid(RN_uopValid),
		.IN_uop(RN_uop),
		.IN_uopOrdering(RN_uopOrdering),
		.IN_resultValid(wbHasResult),
		.IN_resultUOp(wbUOp),
		.IN_loadForwardValid(LSU_loadFwdValid),
		.IN_loadForwardTag(LSU_loadFwdTag),
		.IN_branch(branch),
		.IN_issueValid(RV_uopValid),
		.IN_issueUOps(RV_uop),
		.IN_maxStoreSqN(SQ_maxStoreSqN),
		.IN_maxLoadSqN(LB_maxLoadSqN),
		.OUT_valid(RV_uopValid[0]),
		.OUT_uop(RV_uop[0+:101]),
		.OUT_full(IQ0_full)
	);
	wire IQ1_full;
	wire FDIV_busy;
	wire FDIV_doNotIssue = (FDIV_busy || (LD_uop[199] && enabledXUs[14])) || (RV_uopValid[1] && (RV_uop[105-:4] == 4'd6));
	wire MUL_doNotIssue = 0;
	IssueQueue #(
		.SIZE(8),
		.NUM_UOPS(4),
		.RESULT_BUS_COUNT(4),
		.IMM_BITS(32),
		.FU0(4'd0),
		.FU1(4'd3),
		.FU2(4'd6),
		.FU3(4'd7),
		.FU0_SPLIT(1),
		.FU0_ORDER(1),
		.FU1_DLY(5)
	) iq1(
		.clk(clk),
		.rst(rst),
		.frontEn(((frontendEn && !branch[0]) && !mispredFlush) && !RN_stall),
		.IN_stall(stall[1]),
		.IN_doNotIssueFU1(MUL_doNotIssue),
		.IN_doNotIssueFU2(FDIV_doNotIssue),
		.IN_uopValid(RN_uopValid),
		.IN_uop(RN_uop),
		.IN_uopOrdering(RN_uopOrdering),
		.IN_resultValid(wbHasResult),
		.IN_resultUOp(wbUOp),
		.IN_loadForwardValid(LSU_loadFwdValid),
		.IN_loadForwardTag(LSU_loadFwdTag),
		.IN_branch(branch),
		.IN_issueValid(RV_uopValid),
		.IN_issueUOps(RV_uop),
		.IN_maxStoreSqN(SQ_maxStoreSqN),
		.IN_maxLoadSqN(LB_maxLoadSqN),
		.OUT_valid(RV_uopValid[1]),
		.OUT_uop(RV_uop[101+:101]),
		.OUT_full(IQ1_full)
	);
	wire IQ2_full;
	IssueQueue #(
		.SIZE(8),
		.NUM_UOPS(4),
		.RESULT_BUS_COUNT(4),
		.IMM_BITS(12),
		.FU0(4'd1),
		.FU1(4'd1),
		.FU2(4'd1),
		.FU3(4'd1),
		.FU0_SPLIT(0),
		.FU0_ORDER(0),
		.FU1_DLY(0)
	) iq2(
		.clk(clk),
		.rst(rst),
		.frontEn(((frontendEn && !branch[0]) && !mispredFlush) && !RN_stall),
		.IN_stall(stall[2]),
		.IN_doNotIssueFU1(1'b0),
		.IN_doNotIssueFU2(1'b0),
		.IN_uopValid(RN_uopValid),
		.IN_uop(RN_uop),
		.IN_uopOrdering(RN_uopOrdering),
		.IN_resultValid(wbHasResult),
		.IN_resultUOp(wbUOp),
		.IN_loadForwardValid(LSU_loadFwdValid),
		.IN_loadForwardTag(LSU_loadFwdTag),
		.IN_branch(branch),
		.IN_issueValid(RV_uopValid),
		.IN_issueUOps(RV_uop),
		.IN_maxStoreSqN(SQ_maxStoreSqN),
		.IN_maxLoadSqN(LB_maxLoadSqN),
		.OUT_valid(RV_uopValid[2]),
		.OUT_uop(RV_uop[202+:101]),
		.OUT_full(IQ2_full)
	);
	wire IQ3_full;
	IssueQueue #(
		.SIZE(10),
		.NUM_UOPS(4),
		.RESULT_BUS_COUNT(4),
		.IMM_BITS(12),
		.FU0(4'd2),
		.FU1(4'd2),
		.FU2(4'd2),
		.FU3(4'd2),
		.FU0_SPLIT(0),
		.FU0_ORDER(0),
		.FU1_DLY(0)
	) iq3(
		.clk(clk),
		.rst(rst),
		.frontEn(((frontendEn && !branch[0]) && !mispredFlush) && !RN_stall),
		.IN_stall(stall[3]),
		.IN_doNotIssueFU1(1'b0),
		.IN_doNotIssueFU2(1'b0),
		.IN_uopValid(RN_uopValid),
		.IN_uop(RN_uop),
		.IN_uopOrdering(RN_uopOrdering),
		.IN_resultValid(wbHasResult),
		.IN_resultUOp(wbUOp),
		.IN_loadForwardValid(LSU_loadFwdValid),
		.IN_loadForwardTag(LSU_loadFwdTag),
		.IN_branch(branch),
		.IN_issueValid(RV_uopValid),
		.IN_issueUOps(RV_uop),
		.IN_maxStoreSqN(SQ_maxStoreSqN),
		.IN_maxLoadSqN(LB_maxLoadSqN),
		.OUT_valid(RV_uopValid[3]),
		.OUT_uop(RV_uop[303+:101]),
		.OUT_full(IQ3_full)
	);
	wire [47:0] RF_readAddress;
	wire [255:0] RF_readData;
	RF rf(
		.clk(clk),
		.waddr0(wbUOp[54-:6]),
		.wdata0(wbUOp[87-:32]),
		.wen0(wbHasResult_int[0]),
		.waddr1(wbUOp[142-:6]),
		.wdata1(wbUOp[175-:32]),
		.wen1(wbHasResult_int[1]),
		.waddr2(wbUOp[230-:6]),
		.wdata2(wbUOp[263-:32]),
		.wen2(wbHasResult_int[2]),
		.waddr3(wbUOp[318-:6]),
		.wdata3(wbUOp[351-:32]),
		.wen3(wbHasResult_int[3]),
		.raddr0(RF_readAddress[0+:6]),
		.rdata0(RF_readData[0+:32]),
		.raddr1(RF_readAddress[6+:6]),
		.rdata1(RF_readData[32+:32]),
		.raddr2(RF_readAddress[12+:6]),
		.rdata2(RF_readData[64+:32]),
		.raddr3(RF_readAddress[18+:6]),
		.rdata3(RF_readData[96+:32]),
		.raddr4(RF_readAddress[24+:6]),
		.rdata4(RF_readData[128+:32]),
		.raddr5(RF_readAddress[30+:6]),
		.rdata5(RF_readData[160+:32]),
		.raddr6(RF_readAddress[36+:6]),
		.rdata6(RF_readData[192+:32]),
		.raddr7(RF_readAddress[42+:6]),
		.rdata7(RF_readData[224+:32])
	);
	wire [15:0] LD_fu;
	wire [63:0] LD_zcFwdResult;
	wire [13:0] LD_zcFwdTag;
	wire [1:0] LD_zcFwdValid;
	Load ld(
		.clk(clk),
		.rst(rst),
		.IN_uopValid(RV_uopValid),
		.IN_uop(RV_uop),
		.IN_wbHasResult(wbHasResult),
		.IN_wbUOp(wbUOp),
		.IN_invalidate(branch[0]),
		.IN_invalidateSqN(branch[43-:7]),
		.IN_stall(stall),
		.IN_zcFwdResult(LD_zcFwdResult),
		.IN_zcFwdTag(LD_zcFwdTag),
		.IN_zcFwdValid(LD_zcFwdValid),
		.OUT_pcReadAddr(PC_readAddress[0+:20]),
		.IN_pcReadData(PC_readData[0+:236]),
		.OUT_rfReadAddr(RF_readAddress),
		.IN_rfReadData(RF_readData),
		.OUT_enableXU(enabledXUs),
		.OUT_funcUnit(LD_fu),
		.OUT_uop(LD_uop)
	);
	wire INTALU_wbReq;
	wire [87:0] INT0_uop;
	IntALU ialu(
		.clk(clk),
		.en(enabledXUs[0]),
		.rst(rst),
		.IN_wbStall(1'b0),
		.IN_uop(LD_uop[0+:199]),
		.IN_invalidate(branch[0]),
		.IN_invalidateSqN(branch[43-:7]),
		.OUT_wbReq(INTALU_wbReq),
		.OUT_branch(branchProvs[0+:76]),
		.OUT_btUpdate(BP_btUpdates[0+:67]),
		.OUT_ibInfo(IBP_updates[0+:63]),
		.OUT_zcFwdResult(LD_zcFwdResult[0+:32]),
		.OUT_zcFwdTag(LD_zcFwdTag[0+:7]),
		.OUT_zcFwdValid(LD_zcFwdValid[0]),
		.OUT_uop(INT0_uop)
	);
	wire [87:0] DIV_uop;
	Divide div(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[4]),
		.OUT_busy(DIV_busy),
		.IN_branch(branch),
		.IN_uop(LD_uop[0+:199]),
		.OUT_uop(DIV_uop)
	);
	wire [87:0] FPU_uop;
	FPU fpu(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[5]),
		.IN_branch(branch),
		.IN_uop(LD_uop[0+:199]),
		.OUT_uop(FPU_uop)
	);
	assign wbUOp[0+:88] = (INT0_uop[0] ? INT0_uop : (FPU_uop[0] ? FPU_uop : DIV_uop));
	wire [162:0] CC_uopLd;
	wire [68:0] CC_uopSt;
	wire CC_storeStall;
	wire CC_fenceBusy;
	wire [162:0] AGU_LD_uop;
	wire ROB_startFence;
	wire SQ_empty;
	wire [68:0] SQ_uop;
	CacheController cc(
		.clk(clk),
		.rst(rst),
		.IN_branch(branch),
		.IN_SQ_empty(SQ_empty),
		.OUT_stall({CC_storeStall, stall[2]}),
		.IN_uopLd(AGU_LD_uop),
		.OUT_uopLd(CC_uopLd),
		.IN_uopSt(SQ_uop),
		.OUT_uopSt(CC_uopSt),
		.OUT_MC_ce(CC_MC_if[41]),
		.OUT_MC_we(CC_MC_if[40]),
		.OUT_MC_sramAddr(CC_MC_if[39-:10]),
		.OUT_MC_extAddr(CC_MC_if[29-:30]),
		.IN_MC_progress(IN_MC_progress),
		.IN_MC_cacheID(OUT_MC_cacheID),
		.IN_MC_busy(IN_MC_busy || PC_MC_if[41]),
		.IN_fence(ROB_startFence),
		.OUT_fenceBusy(CC_fenceBusy)
	);
	wire [63:0] CR_rmask;
	AGU aguLD(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[17]),
		.stall(stall[2]),
		.IN_mode(CR_mode),
		.IN_rmask(CR_rmask),
		.IN_branch(branch),
		.IN_uop(LD_uop[398+:199]),
		.OUT_uop(AGU_LD_uop)
	);
	wire [162:0] AGU_ST_uop;
	wire [39:0] AGU_ST_zcFwd;
	wire [63:0] CR_wmask;
	StoreAGU aguST(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[26]),
		.stall(stall[3]),
		.IN_mode(CR_mode),
		.IN_wmask(CR_wmask),
		.IN_branch(branch),
		.OUT_zcFwd(AGU_ST_zcFwd),
		.IN_uop(LD_uop[597+:199]),
		.OUT_aguOp(AGU_ST_uop),
		.OUT_uop(wbUOp[264+:88])
	);
	LoadBuffer lb(
		.clk(clk),
		.rst(rst),
		.commitSqN(ROB_curSqN),
		.IN_stall(stall[3:2]),
		.IN_uop({AGU_ST_uop, AGU_LD_uop}),
		.IN_branch(branch),
		.OUT_branch(branchProvs[152+:76]),
		.OUT_maxLoadSqN(LB_maxLoadSqN)
	);
	wire CSR_we;
	wire [31:0] CSR_dataOut;
	wire [3:0] SQ_lookupMask;
	wire [31:0] SQ_lookupData;
	assign stall[3] = 1'b0;
	wire SQ_flush;
	wire IO_busy;
	StoreQueue sq(
		.clk(clk),
		.rst(rst),
		.IN_disable(CC_storeStall),
		.IN_stallLd(stall[2]),
		.OUT_empty(SQ_empty),
		.IN_uopSt(AGU_ST_uop),
		.IN_uopLd(AGU_LD_uop),
		.IN_curSqN(ROB_curSqN),
		.IN_branch(branch),
		.OUT_uopSt(SQ_uop),
		.OUT_lookupData(SQ_lookupData),
		.OUT_lookupMask(SQ_lookupMask),
		.OUT_flush(SQ_flush),
		.OUT_maxStoreSqN(SQ_maxStoreSqN),
		.IN_IO_busy((IO_busy || SQ_uop[0]) || CC_uopSt[0])
	);
	LoadStoreUnit lsu(
		.clk(clk),
		.rst(rst),
		.IN_branch(branch),
		.IN_uopLd(CC_uopLd),
		.IN_uopSt(CC_uopSt),
		.OUT_MEM_re(OUT_MEM_readEnable),
		.OUT_MEM_readAddr(OUT_MEM_readAddr),
		.IN_MEM_readData(IN_MEM_readData),
		.OUT_MEM_we(OUT_MEM_writeEnable),
		.OUT_MEM_writeAddr(OUT_MEM_writeAddr),
		.OUT_MEM_writeData(OUT_MEM_writeData),
		.OUT_MEM_wm(OUT_MEM_writeMask),
		.IN_SQ_lookupMask(SQ_lookupMask),
		.IN_SQ_lookupData(SQ_lookupData),
		.IN_CSR_data(CSR_dataOut),
		.OUT_CSR_we(CSR_we),
		.OUT_uopLd(wbUOp[176+:88]),
		.OUT_loadFwdValid(LSU_loadFwdValid),
		.OUT_loadFwdTag(LSU_loadFwdTag)
	);
	wire [87:0] INT1_uop;
	IntALU ialu1(
		.clk(clk),
		.en(enabledXUs[8]),
		.rst(rst),
		.IN_wbStall(1'b0),
		.IN_uop(LD_uop[199+:199]),
		.IN_invalidate(branch[0]),
		.IN_invalidateSqN(branch[43-:7]),
		.OUT_branch(branchProvs[76+:76]),
		.OUT_btUpdate(BP_btUpdates[67+:67]),
		.OUT_ibInfo(IBP_updates[63+:63]),
		.OUT_zcFwdResult(LD_zcFwdResult[32+:32]),
		.OUT_zcFwdTag(LD_zcFwdTag[7+:7]),
		.OUT_zcFwdValid(LD_zcFwdValid[1]),
		.OUT_uop(INT1_uop)
	);
	wire [87:0] MUL_uop;
	wire MUL_busy;
	Multiply mul(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[11]),
		.OUT_busy(MUL_busy),
		.IN_branch(branch),
		.IN_uop(LD_uop[199+:199]),
		.OUT_uop(MUL_uop)
	);
	wire [87:0] FMUL_uop;
	FMul fmul(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[15]),
		.IN_branch(branch),
		.IN_uop(LD_uop[199+:199]),
		.OUT_uop(FMUL_uop)
	);
	wire [87:0] FDIV_uop;
	FDiv fdiv(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[14]),
		.IN_wbAvail((!INT1_uop[0] && !MUL_uop[0]) && !FMUL_uop[0]),
		.OUT_busy(FDIV_busy),
		.IN_branch(branch),
		.IN_uop(LD_uop[199+:199]),
		.OUT_uop(FDIV_uop)
	);
	assign wbUOp[88+:88] = (INT1_uop[0] ? INT1_uop : (MUL_uop[0] ? MUL_uop : (FMUL_uop[0] ? FMUL_uop : FDIV_uop)));
	wire [6:0] ROB_maxSqN;
	wire [31:0] CR_irqAddr;
	wire [2:0] ROB_irqFlags;
	wire [31:0] ROB_irqSrc;
	wire [31:0] ROB_irqMemAddr;
	wire MEMSUB_busy = (((((!SQ_empty || IN_MC_busy) || CC_uopLd[0]) || CC_uopSt[0]) || SQ_uop[0]) || AGU_LD_uop[0]) || CC_fenceBusy;
	wire ROB_irqTaken;
	wire timerIRQ;
	ROB rob(
		.clk(clk),
		.rst(rst),
		.IN_uop(RN_uop),
		.IN_uopValid(RN_uopValid),
		.IN_wbUOps(wbUOp),
		.IN_branch(branch),
		.OUT_maxSqN(ROB_maxSqN),
		.OUT_curSqN(ROB_curSqN),
		.OUT_comUOp(comUOps),
		.OUT_bpUpdate(ROB_bpUpdate),
		.IN_irqAddr(CR_irqAddr),
		.OUT_irqFlags(ROB_irqFlags),
		.OUT_irqSrc(ROB_irqSrc),
		.OUT_irqMemAddr(ROB_irqMemAddr),
		.OUT_pcReadAddr(PC_readAddress[20+:5]),
		.IN_pcReadData(PC_readData[236+:59]),
		.OUT_branch(branchProvs[228+:76]),
		.OUT_curFetchID(ROB_curFetchID),
		.IN_irq(timerIRQ),
		.IN_MEM_busy(MEMSUB_busy),
		.IN_allowBreak(!CR_mode[3'd6]),
		.OUT_fence(ROB_startFence),
		.OUT_clearICache(ROB_clearICache),
		.OUT_disableIFetch(ROB_disableIFetch),
		.OUT_irqTaken(ROB_irqTaken),
		.OUT_halt(OUT_halt),
		.OUT_mispredFlush(mispredFlush)
	);
	ControlRegs cr(
		.clk(clk),
		.rst(rst),
		.IN_mispredFlush(mispredFlush),
		.IN_we(CSR_we),
		.IN_wm(OUT_MEM_writeMask),
		.IN_writeAddr(OUT_MEM_writeAddr[6:0]),
		.IN_data(OUT_MEM_writeData),
		.IN_re(OUT_MEM_readEnable),
		.IN_readAddr(OUT_MEM_readAddr[6:0]),
		.OUT_data(CSR_dataOut),
		.IN_comValid({comUOps[0], comUOps[23], comUOps[46], comUOps[69]}),
		.IN_branchMispred((branchProvs[76] || branchProvs[0]) && !mispredFlush),
		.IN_wbValid({wbUOp[0], wbUOp[88], wbUOp[176], wbUOp[264]}),
		.IN_ifValid({DE_uop[0] && !FUSE_full, DE_uop[68] && !FUSE_full, DE_uop[136] && !FUSE_full, DE_uop[204] && !FUSE_full}),
		.IN_comBranch({comUOps[0] && comUOps[3], comUOps[23] && comUOps[26], comUOps[46] && comUOps[49], comUOps[69] && comUOps[72]}),
		.OUT_irqAddr(CR_irqAddr),
		.IN_irqTaken(ROB_irqTaken),
		.IN_irqSrc(ROB_irqSrc),
		.IN_irqFlags(ROB_irqFlags),
		.IN_irqMemAddr(ROB_irqMemAddr),
		.OUT_SPI_cs(OUT_SPI_cs),
		.OUT_SPI_clk(OUT_SPI_clk),
		.OUT_SPI_mosi(OUT_SPI_mosi),
		.IN_SPI_miso(IN_SPI_miso),
		.OUT_mode(CR_mode),
		.OUT_wmask(CR_wmask),
		.OUT_rmask(CR_rmask),
		.OUT_tmrIRQ(timerIRQ),
		.OUT_IO_busy(IO_busy)
	);
	assign frontendEn = (((((((!IQ0_full && !IQ1_full) && !IQ2_full) && !IQ3_full) && ($signed(RN_nextSqN - ROB_maxSqN) <= -3)) && !branch[0]) && en) && !mispredFlush) && !SQ_flush;
endmodule
