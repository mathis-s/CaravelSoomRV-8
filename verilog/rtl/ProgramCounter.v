module ProgramCounter (
	clk,
	en0,
	en1,
	rst,
	IN_pc,
	IN_write,
	IN_branchTaken,
	IN_fetchID,
	IN_instr,
	IN_clearICache,
	IN_BP_branchFound,
	IN_BP_branchTaken,
	IN_BP_isJump,
	IN_BP_branchSrc,
	IN_BP_branchDst,
	IN_BP_history,
	IN_BP_info,
	IN_BP_multipleBranches,
	IN_BP_branchCompr,
	IN_pcReadAddr,
	OUT_pcReadData,
	IN_ROB_curFetchID,
	OUT_pcRaw,
	OUT_instrAddr,
	OUT_instrs,
	OUT_stall,
	OUT_MC_if,
	IN_MC_cacheID,
	IN_MC_progress,
	IN_MC_busy
);
	parameter NUM_UOPS = 3;
	parameter NUM_BLOCKS = 8;
	input wire clk;
	input wire en0;
	input wire en1;
	input wire rst;
	input wire [31:0] IN_pc;
	input wire IN_write;
	input wire IN_branchTaken;
	input wire [4:0] IN_fetchID;
	input wire [127:0] IN_instr;
	input wire IN_clearICache;
	input wire IN_BP_branchFound;
	input wire IN_BP_branchTaken;
	input wire IN_BP_isJump;
	input wire [31:0] IN_BP_branchSrc;
	input wire [31:0] IN_BP_branchDst;
	input wire [15:0] IN_BP_history;
	input wire [8:0] IN_BP_info;
	input wire IN_BP_multipleBranches;
	input wire IN_BP_branchCompr;
	input wire [24:0] IN_pcReadAddr;
	output wire [294:0] OUT_pcReadData;
	input wire [4:0] IN_ROB_curFetchID;
	output wire [31:0] OUT_pcRaw;
	output wire [27:0] OUT_instrAddr;
	output reg [(NUM_BLOCKS * 54) - 1:0] OUT_instrs;
	output wire OUT_stall;
	output wire [41:0] OUT_MC_if;
	input wire [0:0] IN_MC_cacheID;
	input wire [9:0] IN_MC_progress;
	input wire IN_MC_busy;
	integer i;
	reg [4:0] fetchID;
	reg [30:0] pc;
	reg [30:0] pcLast;
	wire [4:0] fetchIDlast;
	reg [15:0] histLast;
	reg [8:0] infoLast;
	reg [2:0] branchPosLast;
	reg multipleLast;
	assign OUT_pcRaw = {pc, 1'b0};
	always @(*)
		for (i = 0; i < NUM_BLOCKS; i = i + 1)
			OUT_instrs[(i * 54) + 53-:16] = IN_instr[16 * i+:16];
	wire [58:0] PCF_writeData;
	assign PCF_writeData[58-:31] = pcLast;
	assign PCF_writeData[15-:16] = histLast;
	assign PCF_writeData[24-:9] = infoLast;
	assign PCF_writeData[27-:3] = branchPosLast;
	PCFile #(.WORD_SIZE(59)) pcFile(
		.clk(clk),
		.wen0(en1),
		.waddr0(fetchID),
		.wdata0(PCF_writeData),
		.raddr0(IN_pcReadAddr[0+:5]),
		.rdata0(OUT_pcReadData[0+:59]),
		.raddr1(IN_pcReadAddr[5+:5]),
		.rdata1(OUT_pcReadData[59+:59]),
		.raddr2(IN_pcReadAddr[10+:5]),
		.rdata2(OUT_pcReadData[118+:59]),
		.raddr3(IN_pcReadAddr[15+:5]),
		.rdata3(OUT_pcReadData[177+:59]),
		.raddr4(IN_pcReadAddr[20+:5]),
		.rdata4(OUT_pcReadData[236+:59])
	);
	wire icacheStall;
	ICacheTable ict(
		.clk(clk),
		.rst(rst || IN_clearICache),
		.IN_lookupValid(en0),
		.IN_lookupPC(pc),
		.OUT_lookupAddress(OUT_instrAddr),
		.OUT_stall(icacheStall),
		.OUT_MC_if(OUT_MC_if),
		.IN_MC_cacheID(IN_MC_cacheID),
		.IN_MC_progress(IN_MC_progress),
		.IN_MC_busy(IN_MC_busy)
	);
	assign OUT_stall = (IN_ROB_curFetchID == fetchID) || icacheStall;
	always @(posedge clk)
		if (rst) begin
			pc <= 0;
			fetchID <= 0;
		end
		else if (IN_write) begin
			pc <= IN_pc[31:1];
			fetchID <= IN_fetchID + 1;
		end
		else begin
			if (en1) begin
				for (i = 0; i < NUM_BLOCKS; i = i + 1)
					begin
						OUT_instrs[(i * 54) + 37-:31] <= {pcLast[30:3], i[2:0]};
						OUT_instrs[i * 54] <= ((i[2:0] >= pcLast[2:0]) && (!infoLast[7] || (i[2:0] <= branchPosLast))) && (!multipleLast || (i[2:0] <= branchPosLast));
						OUT_instrs[(i * 54) + 6-:5] <= fetchID;
						OUT_instrs[(i * 54) + 1] <= infoLast[7] && (i[2:0] == branchPosLast);
					end
				fetchID <= fetchID + 1;
			end
			if (en0) begin
				histLast <= IN_BP_history;
				infoLast <= IN_BP_info;
				pcLast <= pc;
				branchPosLast <= IN_BP_branchSrc[3:1];
				multipleLast <= IN_BP_multipleBranches;
				if (IN_BP_branchFound) begin
					if (IN_BP_isJump || IN_BP_branchTaken)
						pc <= IN_BP_branchDst[31:1];
					else if (IN_BP_multipleBranches)
						pc <= IN_BP_branchSrc[31:1] + 1;
					else
						pc <= {pc[30:3] + 28'b0000000000000000000000000001, 3'b000};
				end
				else
					pc <= {pc[30:3] + 28'b0000000000000000000000000001, 3'b000};
			end
		end
endmodule
