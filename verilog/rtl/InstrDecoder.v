module InstrDecoder (
	clk,
	rst,
	en,
	IN_invalidate,
	IN_instrs,
	IN_indirBranchTarget,
	IN_enCustom,
	OUT_decBranch,
	OUT_decBranchDst,
	OUT_decBranchFetchID,
	OUT_uop
);
	parameter NUM_UOPS = 4;
	parameter DO_FUSE = 0;
	parameter FUSE_LUI = 0;
	parameter FUSE_STORE_DATA = 0;
	input wire clk;
	input wire rst;
	input wire en;
	input wire IN_invalidate;
	input wire [(NUM_UOPS * 70) - 1:0] IN_instrs;
	input wire [30:0] IN_indirBranchTarget;
	input wire IN_enCustom;
	output reg OUT_decBranch;
	output reg [30:0] OUT_decBranchDst;
	output reg [4:0] OUT_decBranchFetchID;
	output reg [(NUM_UOPS * 68) - 1:0] OUT_uop;
	reg RS_inValid;
	reg [30:0] RS_inData;
	reg RS_outValid;
	reg RS_inPop;
	reg [30:0] RS_outData;
	wire [1:1] sv2v_tmp_returnStack_OUT_valid;
	always @(*) RS_outValid = sv2v_tmp_returnStack_OUT_valid;
	wire [31:1] sv2v_tmp_returnStack_OUT_data;
	always @(*) RS_outData = sv2v_tmp_returnStack_OUT_data;
	ReturnStack returnStack(
		.clk(clk),
		.rst(rst),
		.IN_valid(RS_inValid),
		.IN_data(RS_inData),
		.OUT_valid(sv2v_tmp_returnStack_OUT_valid),
		.IN_pop(RS_inPop),
		.OUT_data(sv2v_tmp_returnStack_OUT_data)
	);
	integer i;
	reg [67:0] uop;
	reg invalidEnc;
	reg [31:0] instr;
	reg [15:0] i16;
	reg [31:0] i32;
	reg [67:0] uopsComb [NUM_UOPS - 1:0];
	reg [3:0] validMask;
	always @(*) begin
		RS_inValid = 0;
		RS_inData = 31'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		RS_inPop = 0;
		OUT_decBranch = 0;
		OUT_decBranchDst = 31'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		validMask = 4'b1111;
		OUT_decBranchFetchID = 0;
		for (i = 0; i < NUM_UOPS; i = i + 1)
			begin
				instr = IN_instrs[(i * 70) + 69-:32];
				i32 = IN_instrs[(i * 70) + 69-:32];
				i16 = IN_instrs[(i * 70) + 53-:16];
				uop = 0;
				invalidEnc = 1;
				uop[0] = (IN_instrs[i * 70] && en) && !OUT_decBranch;
				uop[9-:5] = IN_instrs[(i * 70) + 6-:5];
				uop[4-:3] = IN_instrs[(i * 70) + 9-:3] + (instr[1:0] == 2'b11 ? 1 : 0);
				case (instr[6-:7])
					7'b0110111, 7'b0010111: uop[67-:32] = {instr[31:12], 12'b000000000000};
					7'b1101111: uop[67-:32] = $signed({{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0});
					7'b1110011, 7'b1100111, 7'b0000011, 7'b0010011: uop[67-:32] = $signed({{20 {instr[31]}}, instr[31:20]});
					7'b1100011: uop[67-:32] = $signed({{20 {instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0});
					7'b0100011: uop[67-:32] = $signed({{20 {instr[31]}}, instr[31:25], instr[11:7]});
					default: uop[67-:32] = 0;
				endcase
				if ((IN_instrs[i * 70] && en) && !OUT_decBranch)
					if (instr[1:0] == 2'b11)
						case (instr[6-:7])
							7'b1110011:
								if ((uop[67-:32] == 0) || (uop[67-:32] == 1)) begin
									case (uop[67-:32])
										0: uop[38:36] = 3'd5;
										1: uop[38:36] = 3'd4;
									endcase
									uop[13-:4] = 4'd0;
									uop[35-:5] = 0;
									uop[30-:5] = 0;
									uop[24-:5] = 0;
									uop[19-:6] = 6'd20;
									uop[25] = 1;
									invalidEnc = 0;
								end
							7'b0110111: begin
								uop[13-:4] = 4'd0;
								uop[35-:5] = 0;
								uop[30-:5] = 0;
								uop[25] = 1;
								uop[24-:5] = instr[11-:5];
								uop[19-:6] = 6'd16;
								invalidEnc = 0;
							end
							7'b0010111: begin
								uop[13-:4] = 4'd0;
								uop[35-:5] = 0;
								uop[30-:5] = 0;
								uop[24-:5] = instr[11-:5];
								uop[19-:6] = 6'd17;
								invalidEnc = 0;
							end
							7'b1101111: begin
								uop[13-:4] = 4'd0;
								uop[35-:5] = 0;
								uop[30-:5] = 0;
								uop[25] = 1;
								uop[24-:5] = instr[11-:5];
								uop[19-:6] = 6'd18;
								invalidEnc = 0;
								if (uop[24-:5] == 1) begin
									RS_inValid = 1;
									RS_inData = IN_instrs[(i * 70) + 37-:31] + 2;
								end
								if (!IN_instrs[(i * 70) + 1]) begin
									OUT_decBranchDst = IN_instrs[(i * 70) + 37-:31] + uop[67:37];
									OUT_decBranch = 1;
									OUT_decBranchFetchID = IN_instrs[(i * 70) + 6-:5];
								end
								else if ((uop[24-:5] == 0) && IN_instrs[(i * 70) + 1])
									uop[0] = 0;
							end
							7'b1100111: begin
								uop[13-:4] = 4'd0;
								uop[35-:5] = instr[19-:5];
								uop[25] = 1;
								uop[24-:5] = instr[11-:5];
								uop[19-:6] = 6'd19;
								invalidEnc = 0;
							end
							7'b0000011: begin
								uop[35-:5] = instr[19-:5];
								uop[30-:5] = 0;
								uop[25] = 1;
								uop[24-:5] = instr[11-:5];
								uop[13-:4] = 4'd1;
								case (instr[14-:3])
									0: uop[19-:6] = 6'd0;
									1: uop[19-:6] = 6'd1;
									2: uop[19-:6] = 6'd2;
									4: uop[19-:6] = 6'd3;
									5: uop[19-:6] = 6'd4;
								endcase
								invalidEnc = ((((instr[14-:3] != 0) && (instr[14-:3] != 1)) && (instr[14-:3] != 2)) && (instr[14-:3] != 4)) && (instr[14-:3] != 5);
							end
							7'b0100011: begin
								uop[35-:5] = instr[19-:5];
								uop[30-:5] = instr[24-:5];
								uop[25] = 0;
								uop[24-:5] = 0;
								uop[13-:4] = 4'd2;
								if (IN_enCustom && 0) begin
									invalidEnc = 0;
									case (instr[14-:3])
										0: uop[19-:6] = 6'd0;
										1: uop[19-:6] = 6'd1;
										2: uop[19-:6] = 6'd2;
										3: invalidEnc = 1;
										4: uop[19-:6] = 6'd7;
										5: uop[19-:6] = 6'd8;
										6: uop[19-:6] = 6'd9;
										7: invalidEnc = 1;
									endcase
									if (instr[14])
										uop[24-:5] = uop[35-:5];
								end
								else begin
									case (instr[14-:3])
										0: uop[19-:6] = 6'd0;
										1: uop[19-:6] = 6'd1;
										2: uop[19-:6] = 6'd2;
									endcase
									invalidEnc = ((instr[14-:3] != 0) && (instr[14-:3] != 1)) && (instr[14-:3] != 2);
								end
							end
							7'b1100011: begin
								uop[35-:5] = instr[19-:5];
								uop[30-:5] = instr[24-:5];
								uop[25] = 0;
								uop[24-:5] = 0;
								uop[13-:4] = 4'd0;
								invalidEnc = (uop[19-:6] == 2) || (uop[19-:6] == 3);
								if (((((((((!invalidEnc && DO_FUSE) && (i != 0)) && uopsComb[i - 1][0]) && (uopsComb[i - 1][13-:4] == 4'd0)) && (uopsComb[i - 1][19-:6] == 6'd0)) && uopsComb[i - 1][25]) && (uopsComb[i - 1][35-:5] == uop[35-:5])) && (uop[35-:5] != 0)) && (uopsComb[i - 1][67-:32] != 0)) begin
									uop[24-:5] = uopsComb[i - 1][24-:5];
									uop[67:56] = uopsComb[i - 1][47:36];
									validMask[i - 1] = 0;
									$display("fused at %x", IN_instrs[(i * 70) + 37-:31]);
									case (instr[14-:3])
										0: uop[19-:6] = 6'd46;
										1: uop[19-:6] = 6'd47;
										4: uop[19-:6] = 6'd48;
										5: uop[19-:6] = 6'd49;
										6: uop[19-:6] = 6'd50;
										7: uop[19-:6] = 6'd51;
									endcase
								end
								else
									case (instr[14-:3])
										0: uop[19-:6] = 6'd10;
										1: uop[19-:6] = 6'd11;
										4: uop[19-:6] = 6'd12;
										5: uop[19-:6] = 6'd13;
										6: uop[19-:6] = 6'd14;
										7: uop[19-:6] = 6'd15;
									endcase
							end
							7'b0001111:
								if (instr[14-:3] == 0) begin
									uop[13-:4] = 4'd0;
									uop[19-:6] = 6'd20;
									uop[67-:32] = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxx110;
									invalidEnc = 0;
								end
								else if (instr[14-:3] == 1) begin
									uop[13-:4] = 4'd0;
									uop[19-:6] = 6'd20;
									uop[67-:32] = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxx110;
									invalidEnc = 0;
								end
								else if (((instr[14-:3] == 3'b010) && (instr[11-:5] == 0)) && (instr[31:20] == 0)) begin
									invalidEnc = 0;
									uop[19-:6] = 6'd4;
									uop[13-:4] = 4'd2;
									uop[35-:5] = instr[19-:5];
								end
								else if (((instr[14-:3] == 3'b010) && (instr[11-:5] == 0)) && (instr[31:20] == 1)) begin
									invalidEnc = 0;
									uop[19-:6] = 6'd3;
									uop[13-:4] = 4'd2;
									uop[35-:5] = instr[19-:5];
								end
								else if (((instr[14-:3] == 3'b010) && (instr[11-:5] == 0)) && (instr[31:20] == 2)) begin
									invalidEnc = 0;
									uop[19-:6] = 6'd5;
									uop[13-:4] = 4'd2;
									uop[35-:5] = instr[19-:5];
								end
							7'b0010011: begin
								uop[35-:5] = instr[19-:5];
								uop[30-:5] = 0;
								uop[25] = 1;
								uop[24-:5] = instr[11-:5];
								uop[13-:4] = 4'd0;
								if (!(((instr[14-:3] == 1) && (instr[31-:7] != 0)) || ((instr[14-:3] == 5) && ((instr[31-:7] != 7'h20) && (instr[31-:7] != 0))))) begin
									case (instr[14-:3])
										0: uop[19-:6] = 6'd0;
										1: uop[19-:6] = 6'd4;
										2: uop[19-:6] = 6'd6;
										3: uop[19-:6] = 6'd7;
										4: uop[19-:6] = 6'd1;
										5: uop[19-:6] = (instr[31-:7] == 7'h20 ? 6'd9 : 6'd5);
										6: uop[19-:6] = 6'd2;
										7: uop[19-:6] = 6'd3;
									endcase
									if (((((((FUSE_LUI && (i != 0)) && (uop[19-:6] == 6'd0)) && uopsComb[i - 1][0]) && (uopsComb[i - 1][13-:4] == 4'd0)) && (uopsComb[i - 1][19-:6] == 6'd16)) && (uopsComb[i - 1][24-:5] == uop[24-:5])) && (uop[24-:5] == uop[35-:5])) begin
										uopsComb[i - 1][47:36] = uop[47:36];
										if (uop[47])
											uopsComb[i - 1][67:48] = uopsComb[i - 1][67:48] - 1;
										uop[0] = 0;
									end
									invalidEnc = 0;
								end
								else if (instr[31-:7] == 7'b0110000) begin
									if (instr[14-:3] == 3'b001) begin
										if (instr[24-:5] == 5'b00000) begin
											invalidEnc = 0;
											uop[19-:6] = 6'd28;
										end
										else if (instr[24-:5] == 5'b00001) begin
											invalidEnc = 0;
											uop[19-:6] = 6'd29;
										end
										else if (instr[24-:5] == 5'b00010) begin
											invalidEnc = 0;
											uop[19-:6] = 6'd30;
										end
										else if (instr[24-:5] == 5'b00100) begin
											invalidEnc = 0;
											uop[19-:6] = 6'd35;
										end
										else if (instr[24-:5] == 5'b00101) begin
											invalidEnc = 0;
											uop[19-:6] = 6'd36;
										end
										else if (instr[24-:5] == 5'b00101) begin
											invalidEnc = 0;
											uop[19-:6] = 6'd37;
										end
									end
									else if (instr[14-:3] == 3'b101) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd39;
										uop[67-:32] = {27'b000000000000000000000000000, instr[24-:5]};
									end
								end
								else if ((instr[31:20] == 12'b001010000111) && (instr[14-:3] == 3'b101)) begin
									invalidEnc = 0;
									uop[19-:6] = 6'd40;
								end
								else if ((instr[31:20] == 12'b011010011000) && (instr[14-:3] == 3'b101)) begin
									invalidEnc = 0;
									uop[19-:6] = 6'd41;
								end
								if (instr[31-:7] == 7'b0100100) begin
									if (instr[14-:3] == 3'b001) begin
										uop[19-:6] = 6'd42;
										uop[67-:32] = {27'b000000000000000000000000000, instr[24-:5]};
									end
									else if (instr[14-:3] == 3'b101) begin
										uop[19-:6] = 6'd43;
										uop[67-:32] = {27'b000000000000000000000000000, instr[24-:5]};
									end
								end
								else if (instr[31-:7] == 7'b0110100) begin
									if (instr[14-:3] == 3'b001) begin
										uop[19-:6] = 6'd44;
										uop[67-:32] = {27'b000000000000000000000000000, instr[24-:5]};
									end
								end
								else if (instr[31-:7] == 7'b0010100)
									if (instr[14-:3] == 3'b001) begin
										uop[19-:6] = 6'd45;
										uop[67-:32] = {27'b000000000000000000000000000, instr[24-:5]};
									end
								if (((((((((uop[13-:4] == 4'd0) && (uop[19-:6] == 6'd0)) && (uop[35-:5] == 0)) && (uop[47] == uop[46])) && (uop[47] == uop[45])) && (uop[47] == uop[44])) && (uop[47] == uop[43])) && (uop[47] == uop[42])) && (uop[47] == uop[41]))
									if (uop[24-:5] == 0)
										uop[0] = 0;
									else
										uop[13-:4] = 4'd8;
							end
							7'b0110011: begin
								uop[35-:5] = instr[19-:5];
								uop[30-:5] = instr[24-:5];
								uop[25] = 0;
								uop[24-:5] = instr[11-:5];
								uop[13-:4] = 4'd0;
								if (instr[31-:7] == 0) begin
									invalidEnc = 0;
									case (instr[14-:3])
										0: uop[19-:6] = 6'd0;
										1: uop[19-:6] = 6'd4;
										2: uop[19-:6] = 6'd6;
										3: uop[19-:6] = 6'd7;
										4: uop[19-:6] = 6'd1;
										5: uop[19-:6] = 6'd5;
										6: uop[19-:6] = 6'd2;
										7: uop[19-:6] = 6'd3;
									endcase
								end
								else if (instr[31-:7] == 7'h01) begin
									invalidEnc = 0;
									if (instr[14-:3] < 4)
										uop[13-:4] = 4'd3;
									else
										uop[13-:4] = 4'd4;
									case (instr[14-:3])
										0: uop[19-:6] = 6'd0;
										1: uop[19-:6] = 6'd1;
										2: uop[19-:6] = 6'd2;
										3: uop[19-:6] = 6'd3;
										4: uop[19-:6] = 6'd0;
										5: uop[19-:6] = 6'd1;
										6: uop[19-:6] = 6'd2;
										7: uop[19-:6] = 6'd3;
									endcase
								end
								else if (instr[31-:7] == 7'h20) begin
									invalidEnc = (instr[14-:3] != 0) && (instr[14-:3] != 5);
									uop[13-:4] = 4'd0;
									case (instr[14-:3])
										0: uop[19-:6] = 6'd8;
										5: uop[19-:6] = 6'd9;
									endcase
								end
								if (instr[31-:7] == 7'b0010000) begin
									if (instr[14-:3] == 3'b010) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd22;
										uop[13-:4] = 4'd0;
									end
									else if (instr[14-:3] == 3'b100) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd23;
										uop[13-:4] = 4'd0;
									end
									else if (instr[14-:3] == 3'b110) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd24;
										uop[13-:4] = 4'd0;
									end
								end
								else if (instr[31-:7] == 7'b0100000) begin
									if (instr[14-:3] == 3'b111) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd26;
										uop[13-:4] = 4'd0;
									end
									else if (instr[14-:3] == 3'b110) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd27;
										uop[13-:4] = 4'd0;
									end
									else if (instr[14-:3] == 3'b100) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd25;
										uop[13-:4] = 4'd0;
									end
								end
								else if (instr[31-:7] == 7'b0000101) begin
									if (instr[14-:3] == 3'b110) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd31;
										uop[13-:4] = 4'd0;
									end
									else if (instr[14-:3] == 3'b111) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd32;
										uop[13-:4] = 4'd0;
									end
									else if (instr[14-:3] == 3'b100) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd33;
										uop[13-:4] = 4'd0;
									end
									else if (instr[14-:3] == 3'b101) begin
										invalidEnc = 0;
										uop[19-:6] = 6'd34;
										uop[13-:4] = 4'd0;
									end
								end
								else if (((instr[31-:7] == 7'b0000100) && (instr[24-:5] == 0)) && (instr[14-:3] == 3'b100)) begin
									invalidEnc = 0;
									uop[30-:5] = 0;
									uop[19-:6] = 6'd37;
								end
								else if (instr[31-:7] == 7'b0110000) begin
									if (instr[14-:3] == 3'b001) begin
										uop[19-:6] = 6'd38;
										uop[13-:4] = 4'd0;
									end
									else if (instr[14-:3] == 3'b101) begin
										uop[19-:6] = 6'd39;
										uop[13-:4] = 4'd0;
									end
								end
								else if (instr[31-:7] == 7'b0100100) begin
									if (instr[14-:3] == 3'b001) begin
										uop[19-:6] = 6'd42;
										uop[13-:4] = 4'd0;
									end
									else if (instr[14-:3] == 3'b101) begin
										uop[19-:6] = 6'd43;
										uop[13-:4] = 4'd0;
									end
								end
								else if (instr[31-:7] == 7'b0110100) begin
									if (instr[14-:3] == 3'b001) begin
										uop[19-:6] = 6'd44;
										uop[13-:4] = 4'd0;
									end
								end
								else if (instr[31-:7] == 7'b0010100) begin
									if (instr[14-:3] == 3'b001) begin
										uop[19-:6] = 6'd45;
										uop[13-:4] = 4'd0;
									end
								end
								else if (IN_enCustom && (instr[31-:7] == 7'b1000000)) begin
									invalidEnc = 0;
									uop[13-:4] = 4'd1;
									case (instr[14-:3])
										0: uop[19-:6] = 6'd5;
										1: uop[19-:6] = 6'd6;
										2: uop[19-:6] = 6'd7;
										4: uop[19-:6] = 6'd8;
										5: uop[19-:6] = 6'd9;
										6: invalidEnc = 1;
										7: invalidEnc = 1;
									endcase
								end
							end
							7'b1010011:
								if (i32[26-:2] == 2'b00) begin
									uop[13-:4] = 4'd5;
									uop[35-:5] = i32[19-:5];
									uop[30-:5] = i32[24-:5];
									uop[24-:5] = i32[11-:5];
									invalidEnc = 0;
									case (i32[31-:5])
										5'b00000: uop[19-:6] = 6'd4;
										5'b00001: uop[19-:6] = 6'd5;
										5'b00010: begin
											uop[19-:6] = 6'd6;
											uop[13-:4] = 4'd7;
										end
										5'b00011: begin
											uop[19-:6] = 6'd0;
											uop[13-:4] = 4'd6;
										end
										5'b01011: begin
											uop[19-:6] = 6'd1;
											uop[30-:5] = 0;
											uop[13-:4] = 4'd6;
											if (i32[24-:5] != 0)
												invalidEnc = 1;
										end
										5'b00100:
											if (i32[14-:3] == 3'b000)
												uop[19-:6] = 6'd7;
											else if (i32[14-:3] == 3'b001)
												uop[19-:6] = 6'd8;
											else if (i32[14-:3] == 3'b010)
												uop[19-:6] = 6'd9;
											else
												invalidEnc = 1;
										5'b00101:
											if (i32[14-:3] == 3'b000)
												uop[19-:6] = 6'd10;
											else if (i32[14-:3] == 3'b001)
												uop[19-:6] = 6'd11;
											else
												invalidEnc = 1;
										5'b11000: begin
											uop[30-:5] = 0;
											if (i32[24-:5] == 5'b00000)
												uop[19-:6] = 6'd12;
											else if (i32[24-:5] == 5'b00001)
												uop[19-:6] = 6'd13;
											else
												invalidEnc = 1;
										end
										5'b11100:
											if ((i32[24-:5] == 5'b00000) && (i32[14-:3] == 3'b000))
												uop[19-:6] = 6'd14;
											else if ((i32[24-:5] == 5'b00000) && (i32[14-:3] == 3'b001))
												uop[19-:6] = 6'd18;
											else
												invalidEnc = 1;
										5'b10100:
											if (i32[14-:3] == 3'b010)
												uop[19-:6] = 6'd15;
											else if (i32[14-:3] == 3'b001)
												uop[19-:6] = 6'd17;
											else if (i32[14-:3] == 3'b000)
												uop[19-:6] = 6'd16;
											else
												invalidEnc = 1;
										5'b11010:
											if (i32[24-:5] == 5'b00000)
												uop[19-:6] = 6'd19;
											else if (i32[24-:5] == 5'b00001)
												uop[19-:6] = 6'd20;
											else
												invalidEnc = 1;
										5'b11110:
											if ((i32[24-:5] == 0) && (i32[14-:3] == 0))
												uop[19-:6] = 6'd21;
											else
												invalidEnc = 1;
										default: invalidEnc = 1;
									endcase
								end
							default: invalidEnc = 1;
						endcase
					else begin
						uop[1] = 1;
						if (i16[1:0] == 2'b00) begin
							if (i16[15-:3] == 3'b010) begin
								uop[19-:6] = 6'd2;
								uop[13-:4] = 4'd1;
								uop[67-:32] = {25'b0000000000000000000000000, i16[5], i16[12-:3], i16[6], 2'b00};
								uop[35-:5] = {2'b01, i16[9-:3]};
								uop[24-:5] = {2'b01, i16[4-:3]};
								invalidEnc = 0;
							end
							else if (i16[15-:3] == 3'b110) begin
								uop[19-:6] = 6'd2;
								uop[13-:4] = 4'd2;
								uop[67-:32] = {25'b0000000000000000000000000, i16[5], i16[12-:3], i16[6], 2'b00};
								uop[35-:5] = {2'b01, i16[9-:3]};
								uop[30-:5] = {2'b01, i16[4-:3]};
								invalidEnc = 0;
							end
							else if ((i16[15-:3] == 3'b000) && (i16[12-:8] != 0)) begin
								uop[19-:6] = 6'd0;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {22'b0000000000000000000000, i16[10:7], i16[12:11], i16[5], i16[6], 2'b00};
								uop[35-:5] = 2;
								uop[25] = 1;
								uop[24-:5] = {2'b01, i16[4-:3]};
								invalidEnc = 0;
							end
						end
						else if (i16[1:0] == 2'b01) begin
							if (i16[15-:3] == 3'b101) begin
								uop[19-:6] = 6'd18;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {{20 {i16[12]}}, i16[12], i16[8], i16[10:9], i16[6], i16[7], i16[2], i16[11], i16[5:3], 1'b0};
								if (!IN_instrs[(i * 70) + 1]) begin
									OUT_decBranchDst = IN_instrs[(i * 70) + 37-:31] + uop[67:37];
									OUT_decBranch = 1;
									OUT_decBranchFetchID = IN_instrs[(i * 70) + 6-:5];
								end
								else
									uop[0] = 0;
								uop[25] = 1;
								invalidEnc = 0;
							end
							else if (i16[15-:3] == 3'b001) begin
								uop[19-:6] = 6'd18;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {{20 {i16[12]}}, i16[12], i16[8], i16[10:9], i16[6], i16[7], i16[2], i16[11], i16[5:3], 1'b0};
								uop[25] = 1;
								uop[24-:5] = 1;
								RS_inValid = 1;
								RS_inData = IN_instrs[(i * 70) + 37-:31] + 1;
								if (!IN_instrs[(i * 70) + 1]) begin
									OUT_decBranchDst = IN_instrs[(i * 70) + 37-:31] + uop[67:37];
									OUT_decBranch = 1;
									OUT_decBranchFetchID = IN_instrs[(i * 70) + 6-:5];
								end
								invalidEnc = 0;
							end
							else if (i16[15-:3] == 3'b110) begin
								uop[19-:6] = 6'd10;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {{23 {i16[12]}}, i16[12], i16[6:5], i16[2], i16[11:10], i16[4:3], 1'b0};
								uop[35-:5] = {2'b01, i16[9-:3]};
								if (((((((DO_FUSE && (i != 0)) && uopsComb[i - 1][0]) && (uopsComb[i - 1][13-:4] == 4'd0)) && (uopsComb[i - 1][19-:6] == 6'd0)) && uopsComb[i - 1][25]) && (uopsComb[i - 1][35-:5] == uop[35-:5])) && (uop[35-:5] != 0)) begin
									uop[24-:5] = uopsComb[i - 1][24-:5];
									uop[67:56] = uopsComb[i - 1][47:36];
									validMask[i - 1] = 0;
									uop[19-:6] = 6'd46;
								end
								invalidEnc = 0;
							end
							else if (i16[15-:3] == 3'b111) begin
								uop[19-:6] = 6'd11;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {{23 {i16[12]}}, i16[12], i16[6:5], i16[2], i16[11:10], i16[4:3], 1'b0};
								uop[35-:5] = {2'b01, i16[9-:3]};
								if (((((((DO_FUSE && (i != 0)) && uopsComb[i - 1][0]) && (uopsComb[i - 1][13-:4] == 4'd0)) && (uopsComb[i - 1][19-:6] == 6'd0)) && uopsComb[i - 1][25]) && (uopsComb[i - 1][35-:5] == uop[35-:5])) && (uop[35-:5] != 0)) begin
									uop[24-:5] = uopsComb[i - 1][24-:5];
									uop[67:56] = uopsComb[i - 1][47:36];
									validMask[i - 1] = 0;
									uop[19-:6] = 6'd47;
								end
								invalidEnc = 0;
							end
							else if ((i16[15-:3] == 3'b010) && (i16[11-:5] != 0)) begin
								uop[13-:4] = 4'd8;
								uop[67-:32] = {{26 {i16[12]}}, i16[12], i16[6-:5]};
								uop[25] = 1;
								uop[24-:5] = i16[11-:5];
								invalidEnc = 0;
							end
							else if (((i16[15-:3] == 3'b011) && (i16[11-:5] != 0)) && ({i16[12], i16[6-:5]} != 0)) begin
								uop[13-:4] = 4'd0;
								if (i16[11-:5] == 2) begin
									uop[19-:6] = 6'd0;
									uop[35-:5] = 2;
									uop[67-:32] = {{22 {i16[12]}}, i16[12], i16[4:3], i16[5], i16[2], i16[6], 4'b0000};
								end
								else begin
									uop[19-:6] = 6'd16;
									uop[67-:32] = {{14 {i16[12]}}, i16[12], i16[6-:5], 12'b000000000000};
								end
								uop[25] = 1;
								uop[24-:5] = i16[11-:5];
								invalidEnc = 0;
							end
							else if ((i16[15-:3] == 3'b000) && (i16[11-:5] != 0)) begin
								uop[19-:6] = 6'd0;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {{26 {i16[12]}}, i16[12], i16[6-:5]};
								uop[25] = 1;
								uop[35-:5] = i16[11-:5];
								uop[24-:5] = i16[11-:5];
								if (((((((FUSE_LUI && (i != 0)) && (uop[19-:6] == 6'd0)) && uopsComb[i - 1][0]) && (uopsComb[i - 1][13-:4] == 4'd0)) && (uopsComb[i - 1][19-:6] == 6'd16)) && (uopsComb[i - 1][24-:5] == uop[24-:5])) && (uop[24-:5] == uop[35-:5])) begin
									uopsComb[i - 1][47:36] = uop[47:36];
									if (uop[47])
										uopsComb[i - 1][67:48] = uopsComb[i - 1][67:48] - 1;
									uop[0] = 0;
								end
								invalidEnc = 0;
							end
							else if ((((i16[15-:3] == 3'b100) && (i16[11-:2] == 2'b00)) && !i16[12]) && (i16[6:2] != 0)) begin
								uop[19-:6] = 6'd5;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {27'b000000000000000000000000000, i16[6:2]};
								uop[25] = 1;
								uop[35-:5] = {2'b01, i16[9-:3]};
								uop[24-:5] = {2'b01, i16[9-:3]};
								invalidEnc = 0;
							end
							else if ((((i16[15-:3] == 3'b100) && (i16[11-:2] == 2'b01)) && !i16[12]) && (i16[6:2] != 0)) begin
								uop[19-:6] = 6'd9;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {27'b000000000000000000000000000, i16[6:2]};
								uop[25] = 1;
								uop[35-:5] = {2'b01, i16[9-:3]};
								uop[24-:5] = {2'b01, i16[9-:3]};
								invalidEnc = 0;
							end
							else if ((i16[15-:3] == 3'b100) && (i16[11-:2] == 2'b10)) begin
								uop[19-:6] = 6'd3;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {{26 {i16[12]}}, i16[12], i16[6:2]};
								uop[25] = 1;
								uop[35-:5] = {2'b01, i16[9-:3]};
								uop[24-:5] = {2'b01, i16[9-:3]};
								invalidEnc = 0;
							end
							else if (i16[15-:6] == 6'b100011) begin
								case (i16[6-:2])
									2'b11: uop[19-:6] = 6'd3;
									2'b10: uop[19-:6] = 6'd2;
									2'b01: uop[19-:6] = 6'd1;
									2'b00: uop[19-:6] = 6'd8;
								endcase
								uop[13-:4] = 4'd0;
								uop[35-:5] = {2'b01, i16[9-:3]};
								uop[30-:5] = {2'b01, i16[4-:3]};
								uop[24-:5] = {2'b01, i16[9-:3]};
								invalidEnc = 0;
							end
							else if ((((i16[15-:3] == 3'b000) && (i16[12] == 1'b0)) && (i16[11-:5] == 5'b00000)) && (i16[6-:5] == 5'b00000)) begin
								uop[0] = 0;
								uop[19-:6] = 6'd0;
								uop[13-:4] = 4'd0;
								invalidEnc = 0;
							end
						end
						else if (i16[1:0] == 2'b10)
							if ((i16[15-:3] == 3'b010) && (i16[11-:5] != 0)) begin
								uop[19-:6] = 6'd2;
								uop[13-:4] = 4'd1;
								uop[67-:32] = {24'b000000000000000000000000, i16[3:2], i16[12], i16[6:4], 2'b00};
								uop[35-:5] = 2;
								uop[24-:5] = i16[11-:5];
								invalidEnc = 0;
							end
							else if (i16[15-:3] == 3'b110) begin
								uop[19-:6] = 6'd2;
								uop[13-:4] = 4'd2;
								uop[67-:32] = {24'b000000000000000000000000, i16[8:7], i16[12:9], 2'b00};
								uop[35-:5] = 2;
								uop[30-:5] = i16[6-:5];
								invalidEnc = 0;
							end
							else if ((i16[15-:4] == 4'b1000) && !((i16[11-:5] == 0) || (i16[6-:5] != 0))) begin
								uop[13-:4] = 4'd0;
								uop[35-:5] = i16[11-:5];
								if ((i16[11-:5] == 1) && RS_outValid) begin
									RS_inPop = 1;
									uop[19-:6] = 6'd52;
									uop[67-:32] = {RS_outData, 1'b0};
									uop[25] = 1;
									OUT_decBranch = 1;
									OUT_decBranchDst = RS_outData;
									OUT_decBranchFetchID = uop[9-:5];
								end
								else begin
									uop[19-:6] = 6'd53;
									uop[67-:32] = {IN_indirBranchTarget, 1'b0};
									uop[25] = 1;
									OUT_decBranch = 1;
									OUT_decBranchDst = IN_indirBranchTarget;
									OUT_decBranchFetchID = uop[9-:5];
								end
								invalidEnc = 0;
							end
							else if ((i16[15-:4] == 4'b1001) && !((i16[11-:5] == 0) || (i16[6-:5] != 0))) begin
								uop[19-:6] = 6'd19;
								uop[13-:4] = 4'd0;
								uop[35-:5] = i16[11-:5];
								uop[24-:5] = 1;
								invalidEnc = 0;
							end
							else if ((((i16[15-:3] == 3'b000) && (i16[11-:5] != 0)) && !i16[12]) && (i16[6:2] != 0)) begin
								uop[19-:6] = 6'd4;
								uop[13-:4] = 4'd0;
								uop[67-:32] = {27'b000000000000000000000000000, i16[6:2]};
								uop[25] = 1;
								uop[35-:5] = i16[11-:5];
								uop[24-:5] = i16[11-:5];
								invalidEnc = 0;
							end
							else if (((i16[15-:4] == 4'b1000) && (i16[11-:5] != 0)) && (i16[6-:5] != 0)) begin
								uop[19-:6] = 6'd0;
								uop[13-:4] = 4'd0;
								uop[30-:5] = i16[6-:5];
								uop[24-:5] = i16[11-:5];
								invalidEnc = 0;
							end
							else if (((i16[15-:4] == 4'b1001) && (i16[11-:5] != 0)) && (i16[6-:5] != 0)) begin
								uop[19-:6] = 6'd0;
								uop[13-:4] = 4'd0;
								uop[35-:5] = i16[11-:5];
								uop[30-:5] = i16[6-:5];
								uop[24-:5] = i16[11-:5];
								invalidEnc = 0;
							end
							else if (((i16[15-:4] == 4'b1001) && (i16[11-:5] == 0)) && (i16[6-:5] == 0)) begin
								uop[19-:6] = 6'd20;
								uop[13-:4] = 4'd0;
								uop[25] = 1;
								uop[38:36] = 3'd4;
								invalidEnc = 0;
							end
					end
				if (invalidEnc) begin
					uop[19-:6] = 6'd21;
					uop[13-:4] = 4'd0;
				end
				uopsComb[i] = uop;
			end
	end
	always @(posedge clk)
		if (rst || IN_invalidate) begin
			for (i = 0; i < NUM_UOPS; i = i + 1)
				OUT_uop[i * 68] <= 0;
		end
		else if (en)
			for (i = 0; i < NUM_UOPS; i = i + 1)
				begin
					OUT_uop[i * 68+:68] <= uopsComb[i];
					if (!validMask[i])
						OUT_uop[i * 68] <= 0;
				end
endmodule
