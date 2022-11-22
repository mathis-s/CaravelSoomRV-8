module IntALU (
	clk,
	en,
	rst,
	IN_wbStall,
	IN_uop,
	IN_invalidate,
	IN_invalidateSqN,
	OUT_wbReq,
	OUT_branch,
	OUT_btUpdate,
	OUT_ibInfo,
	OUT_zcFwdResult,
	OUT_zcFwdTag,
	OUT_zcFwdValid,
	OUT_uop
);
	input wire clk;
	input wire en;
	input wire rst;
	input wire IN_wbStall;
	input wire [198:0] IN_uop;
	input IN_invalidate;
	input wire [6:0] IN_invalidateSqN;
	output wire OUT_wbReq;
	output reg [75:0] OUT_branch;
	output reg [66:0] OUT_btUpdate;
	output reg [62:0] OUT_ibInfo;
	output wire [31:0] OUT_zcFwdResult;
	output wire [6:0] OUT_zcFwdTag;
	output wire OUT_zcFwdValid;
	output reg [87:0] OUT_uop;
	integer i = 0;
	wire [31:0] srcA = IN_uop[198-:32];
	wire [31:0] srcB = IN_uop[166-:32];
	wire [31:0] imm = IN_uop[102-:32];
	assign OUT_wbReq = IN_uop[0] && en;
	reg [31:0] resC;
	reg [2:0] flags;
	assign OUT_zcFwdResult = resC;
	assign OUT_zcFwdTag = IN_uop[64-:7];
	assign OUT_zcFwdValid = (IN_uop[0] && en) && (IN_uop[57-:5] != 0);
	wire [5:0] resLzTz;
	reg [31:0] srcAbitRev;
	always @(*)
		for (i = 0; i < 32; i = i + 1)
			srcAbitRev[i] = srcA[31 - i];
	LZCnt lzc(
		.in((IN_uop[70-:6] == 6'd28 ? srcA : srcAbitRev)),
		.out(resLzTz)
	);
	wire [5:0] resPopCnt;
	PopCnt popc(
		.a(IN_uop[198-:32]),
		.res(resPopCnt)
	);
	wire lessThan = $signed(srcA) < $signed(srcB);
	wire lessThanU = srcA < srcB;
	wire [31:0] pcPlus2 = IN_uop[134-:32] + 2;
	wire [31:0] pcPlus4 = IN_uop[134-:32] + 4;
	always @(*) begin
		case (IN_uop[70-:6])
			6'd17: resC = IN_uop[134-:32] + imm;
			6'd0: resC = srcA + srcB;
			6'd1: resC = srcA ^ srcB;
			6'd2: resC = srcA | srcB;
			6'd3: resC = srcA & srcB;
			6'd4: resC = srcA << srcB[4:0];
			6'd5: resC = srcA >> srcB[4:0];
			6'd6: resC = {31'b0000000000000000000000000000000, lessThan};
			6'd7: resC = {31'b0000000000000000000000000000000, lessThanU};
			6'd8: resC = srcA - srcB;
			6'd9: resC = srcA >>> srcB[4:0];
			6'd16: resC = srcB;
			6'd19, 6'd18: resC = (IN_uop[1] ? pcPlus2 : pcPlus4);
			6'd20: resC = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
			6'd22: resC = srcB + (srcA << 1);
			6'd23: resC = srcB + (srcA << 2);
			6'd24: resC = srcB + (srcA << 3);
			6'd26: resC = srcA & ~srcB;
			6'd27: resC = srcA | ~srcB;
			6'd25: resC = srcA ^ ~srcB;
			6'd35: resC = {{24 {srcA[7]}}, srcA[7:0]};
			6'd36: resC = {{16 {srcA[15]}}, srcA[15:0]};
			6'd37: resC = {16'b0000000000000000, srcA[15:0]};
			6'd28, 6'd29: resC = {26'b00000000000000000000000000, resLzTz};
			6'd30: resC = {26'b00000000000000000000000000, resPopCnt};
			6'd40: resC = {{4'd8 {|srcA[31:24]}}, {4'd8 {|srcA[23:16]}}, {4'd8 {|srcA[15:8]}}, {4'd8 {|srcA[7:0]}}};
			6'd31: resC = (lessThan ? srcB : srcA);
			6'd32: resC = (lessThanU ? srcB : srcA);
			6'd33: resC = (lessThan ? srcA : srcB);
			6'd34: resC = (lessThanU ? srcA : srcB);
			6'd41: resC = {srcA[7:0], srcA[15:8], srcA[23:16], srcA[31:24]};
			6'd46, 6'd47, 6'd48, 6'd49, 6'd50, 6'd51: resC = srcA + {{20 {imm[31]}}, imm[31:20]};
			default: resC = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		endcase
		case (IN_uop[70-:6])
			6'd21: flags = 3'd5;
			6'd20: flags = imm[2:0];
			default: flags = 3'd0;
		endcase
	end
	reg isBranch;
	reg branchTaken;
	always @(*) begin
		case (IN_uop[70-:6])
			6'd18, 6'd19: branchTaken = 1;
			6'd10: branchTaken = srcA == srcB;
			6'd11: branchTaken = srcA != srcB;
			6'd12: branchTaken = lessThan;
			6'd13: branchTaken = !lessThan;
			6'd14: branchTaken = lessThanU;
			6'd15: branchTaken = !lessThanU;
			6'd46: branchTaken = resC == srcB;
			6'd47: branchTaken = resC != srcB;
			6'd48: branchTaken = $signed(resC < srcB);
			6'd49: branchTaken = !$signed(resC < srcB);
			6'd50: branchTaken = resC < srcB;
			6'd51: branchTaken = !(resC < srcB);
			default: branchTaken = 0;
		endcase
		isBranch = ((((((((((((IN_uop[70-:6] == 6'd18) || (IN_uop[70-:6] == 6'd10)) || (IN_uop[70-:6] == 6'd11)) || (IN_uop[70-:6] == 6'd12)) || (IN_uop[70-:6] == 6'd13)) || (IN_uop[70-:6] == 6'd14)) || (IN_uop[70-:6] == 6'd15)) || (IN_uop[70-:6] == 6'd46)) || (IN_uop[70-:6] == 6'd47)) || (IN_uop[70-:6] == 6'd48)) || (IN_uop[70-:6] == 6'd49)) || (IN_uop[70-:6] == 6'd50)) || (IN_uop[70-:6] == 6'd51);
	end
	always @(posedge clk)
		if (rst) begin
			OUT_uop[0] <= 0;
			OUT_branch[0] <= 0;
			OUT_btUpdate[0] <= 0;
			OUT_ibInfo[0] <= 0;
		end
		else if (((IN_uop[0] && en) && !IN_wbStall) && (!IN_invalidate || ($signed(IN_uop[52-:7] - IN_invalidateSqN) <= 0))) begin
			OUT_branch[43-:7] <= IN_uop[52-:7];
			OUT_branch[29-:7] <= IN_uop[8-:7];
			OUT_branch[36-:7] <= IN_uop[15-:7];
			OUT_btUpdate[0] <= 0;
			OUT_branch[0] <= 0;
			OUT_branch[22] <= 0;
			OUT_ibInfo[0] <= 0;
			if (IN_uop[70-:6] == 6'd18)
				OUT_branch[16-:16] <= IN_uop[31-:16];
			else
				OUT_branch[16-:16] <= {IN_uop[30:16], branchTaken};
			OUT_branch[21-:5] <= IN_uop[45-:5];
			if (isBranch) begin
				if (branchTaken && !IN_uop[40]) begin
					OUT_btUpdate[66-:32] <= (IN_uop[1] ? IN_uop[134-:32] : pcPlus2);
					OUT_btUpdate[2] <= IN_uop[70-:6] == 6'd18;
					OUT_btUpdate[1] <= IN_uop[1];
					OUT_btUpdate[0] <= 1;
				end
				if (branchTaken) begin
					if (IN_uop[70-:6] == 6'd18) begin
						OUT_branch[75-:32] <= IN_uop[134-:32] + imm;
						OUT_btUpdate[34-:32] <= IN_uop[134-:32] + imm;
					end
					else begin
						OUT_branch[75-:32] <= IN_uop[134-:32] + {{19 {imm[12]}}, imm[12:0]};
						OUT_btUpdate[34-:32] <= IN_uop[134-:32] + {{19 {imm[12]}}, imm[12:0]};
					end
				end
				else if (IN_uop[1]) begin
					OUT_branch[75-:32] <= pcPlus2;
					OUT_btUpdate[34-:32] <= pcPlus2;
				end
				else begin
					OUT_branch[75-:32] <= pcPlus4;
					OUT_btUpdate[34-:32] <= pcPlus4;
				end
				if ((branchTaken != IN_uop[39]) && (IN_uop[70-:6] != 6'd18))
					OUT_branch[0] <= 1;
			end
			else if (IN_uop[70-:6] == 6'd19) begin
				OUT_branch[75-:32] <= srcA + srcB;
				OUT_btUpdate[34-:32] <= srcA + srcB;
				OUT_branch[0] <= 1;
			end
			else if ((IN_uop[70-:6] == 6'd52) || (IN_uop[70-:6] == 6'd53)) begin
				if (srcA != srcB) begin
					OUT_branch[75-:32] <= srcA;
					OUT_branch[0] <= 1;
				end
				if (IN_uop[70-:6] == 6'd53) begin
					OUT_ibInfo[62-:31] <= IN_uop[134:104];
					OUT_ibInfo[31-:31] <= srcA[31:1];
					OUT_ibInfo[0] <= 1;
				end
			end
			OUT_uop[1] <= IN_uop[1];
			OUT_uop[55-:7] <= IN_uop[64-:7];
			OUT_uop[48-:5] <= IN_uop[57-:5];
			OUT_uop[87-:32] <= resC;
			OUT_uop[43-:7] <= IN_uop[52-:7];
			if (IN_uop[40])
				OUT_uop[4-:3] <= (branchTaken ? 3'd2 : 3'd3);
			else if (isBranch && (IN_uop[70-:6] != 6'd18))
				OUT_uop[4-:3] <= 3'd1;
			else
				OUT_uop[4-:3] <= flags;
			OUT_uop[0] <= 1;
			OUT_uop[36-:32] <= IN_uop[134-:32];
		end
		else begin
			OUT_uop[0] <= 0;
			OUT_branch[0] <= 0;
			OUT_btUpdate[0] <= 0;
		end
endmodule
