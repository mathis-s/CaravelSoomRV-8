module Load (
	clk,
	rst,
	IN_uopValid,
	IN_uop,
	IN_wbHasResult,
	IN_wbUOp,
	IN_invalidate,
	IN_invalidateSqN,
	IN_stall,
	IN_zcFwdResult,
	IN_zcFwdTag,
	IN_zcFwdValid,
	OUT_pcReadAddr,
	IN_pcReadData,
	OUT_rfReadAddr,
	IN_rfReadData,
	OUT_enableXU,
	OUT_funcUnit,
	OUT_uop
);
	parameter NUM_UOPS = 4;
	parameter NUM_WBS = 4;
	parameter NUM_XUS = 8;
	parameter NUM_ZC_FWDS = 2;
	input wire clk;
	input wire rst;
	input wire [NUM_UOPS - 1:0] IN_uopValid;
	input wire [(NUM_UOPS * 101) - 1:0] IN_uop;
	input wire [NUM_WBS - 1:0] IN_wbHasResult;
	input wire [(NUM_WBS * 88) - 1:0] IN_wbUOp;
	input wire IN_invalidate;
	input wire [6:0] IN_invalidateSqN;
	input wire [NUM_UOPS - 1:0] IN_stall;
	input wire [(NUM_ZC_FWDS * 32) - 1:0] IN_zcFwdResult;
	input wire [(NUM_ZC_FWDS * 7) - 1:0] IN_zcFwdTag;
	input wire [NUM_ZC_FWDS - 1:0] IN_zcFwdValid;
	output reg [(NUM_UOPS * 5) - 1:0] OUT_pcReadAddr;
	input wire [(NUM_UOPS * 59) - 1:0] IN_pcReadData;
	output reg [((2 * NUM_UOPS) * 6) - 1:0] OUT_rfReadAddr;
	input wire [((2 * NUM_UOPS) * 32) - 1:0] IN_rfReadData;
	output reg [(NUM_UOPS * NUM_XUS) - 1:0] OUT_enableXU;
	output reg [(NUM_UOPS * 4) - 1:0] OUT_funcUnit;
	output reg [(NUM_UOPS * 199) - 1:0] OUT_uop;
	integer i;
	integer j;
	always @(*)
		for (i = 0; i < NUM_UOPS; i = i + 1)
			begin
				OUT_rfReadAddr[i * 6+:6] = IN_uop[(i * 101) + 66-:6];
				OUT_rfReadAddr[(i + NUM_UOPS) * 6+:6] = IN_uop[(i * 101) + 58-:6];
				OUT_pcReadAddr[i * 5+:5] = IN_uop[(i * 101) + 26-:5];
			end
	reg [3:0] outFU [NUM_UOPS - 1:0];
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < NUM_UOPS; i = i + 1)
				begin
					OUT_uop[i * 199] <= 0;
					OUT_funcUnit[i * 4+:4] <= 0;
					OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 0;
				end
		end
		else
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if ((!IN_stall[i] && IN_uopValid[i]) && (!IN_invalidate || ($signed(IN_uop[(i * 101) + 51-:7] - IN_invalidateSqN) <= 0))) begin
					OUT_uop[(i * 199) + 102-:32] <= IN_uop[(i * 101) + 100-:32];
					OUT_uop[(i * 199) + 52-:7] <= IN_uop[(i * 101) + 51-:7];
					OUT_uop[(i * 199) + 64-:7] <= IN_uop[(i * 101) + 44-:7];
					OUT_uop[(i * 199) + 57-:5] <= IN_uop[(i * 101) + 37-:5];
					OUT_uop[(i * 199) + 70-:6] <= IN_uop[(i * 101) + 32-:6];
					OUT_uop[(i * 199) + 134-:32] <= {IN_pcReadData[(i * 59) + 58-:28], IN_uop[(i * 101) + 21-:3], 1'b0} - (IN_uop[i * 101] ? 0 : 2);
					OUT_uop[(i * 199) + 45-:5] <= IN_uop[(i * 101) + 26-:5];
					if ((IN_pcReadData[(i * 59) + 16] || !IN_pcReadData[(i * 59) + 24]) || (IN_uop[(i * 101) + 21-:3] <= IN_pcReadData[(i * 59) + 27-:3]))
						OUT_uop[(i * 199) + 31-:16] <= IN_pcReadData[(i * 59) + 15-:16];
					else
						OUT_uop[(i * 199) + 31-:16] <= {IN_pcReadData[(i * 59) + 14-:15], IN_pcReadData[(i * 59) + 23]};
					if (IN_uop[(i * 101) + 21-:3] == IN_pcReadData[(i * 59) + 27-:3])
						OUT_uop[(i * 199) + 40-:9] <= IN_pcReadData[(i * 59) + 24-:9];
					else
						OUT_uop[(i * 199) + 40-:9] <= 0;
					OUT_uop[(i * 199) + 8-:7] <= IN_uop[(i * 101) + 11-:7];
					OUT_uop[(i * 199) + 15-:7] <= IN_uop[(i * 101) + 18-:7];
					OUT_uop[(i * 199) + 1] <= IN_uop[i * 101];
					OUT_funcUnit[i * 4+:4] <= IN_uop[(i * 101) + 4-:4];
					OUT_uop[i * 199] <= 1;
					if (IN_uop[(i * 101) + 67])
						OUT_uop[(i * 199) + 198-:32] <= {{26 {IN_uop[(i * 101) + 66]}}, IN_uop[(i * 101) + 66-:6]};
					else begin : sv2v_autoblock_1
						reg found;
						found = 0;
						for (j = 0; j < NUM_WBS; j = j + 1)
							if (IN_wbHasResult[j] && (IN_uop[(i * 101) + 67-:7] == IN_wbUOp[(j * 88) + 55-:7])) begin
								OUT_uop[(i * 199) + 198-:32] <= IN_wbUOp[(j * 88) + 87-:32];
								found = 1;
							end
						for (j = 0; j < NUM_ZC_FWDS; j = j + 1)
							if (IN_zcFwdValid[j] && (IN_zcFwdTag[j * 7+:7] == IN_uop[(i * 101) + 67-:7])) begin
								OUT_uop[(i * 199) + 198-:32] <= IN_zcFwdResult[j * 32+:32];
								found = 1;
							end
						if (!found)
							OUT_uop[(i * 199) + 198-:32] <= IN_rfReadData[i * 32+:32];
					end
					if (IN_uop[(i * 101) + 52])
						OUT_uop[(i * 199) + 166-:32] <= IN_uop[(i * 101) + 100-:32];
					else if (IN_uop[(i * 101) + 59])
						OUT_uop[(i * 199) + 166-:32] <= {{26 {IN_uop[(i * 101) + 58]}}, IN_uop[(i * 101) + 58-:6]};
					else begin : sv2v_autoblock_2
						reg found;
						found = 0;
						for (j = 0; j < NUM_WBS; j = j + 1)
							if (IN_wbHasResult[j] && (IN_uop[(i * 101) + 59-:7] == IN_wbUOp[(j * 88) + 55-:7])) begin
								OUT_uop[(i * 199) + 166-:32] <= IN_wbUOp[(j * 88) + 87-:32];
								found = 1;
							end
						for (j = 0; j < NUM_ZC_FWDS; j = j + 1)
							if (IN_zcFwdValid[j] && (IN_zcFwdTag[j * 7+:7] == IN_uop[(i * 101) + 59-:7])) begin
								OUT_uop[(i * 199) + 166-:32] <= IN_zcFwdResult[j * 32+:32];
								found = 1;
							end
						if (!found)
							OUT_uop[(i * 199) + 166-:32] <= IN_rfReadData[(i + NUM_UOPS) * 32+:32];
					end
					case (IN_uop[(i * 101) + 4-:4])
						4'd0: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 8'b00000001;
						4'd1: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 8'b00000010;
						4'd2: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 8'b00000100;
						4'd3: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 8'b00001000;
						4'd4: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 8'b00010000;
						4'd5: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 8'b00100000;
						4'd6: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 8'b01000000;
						4'd7: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 8'b10000000;
						default:
							;
					endcase
					outFU[i] <= IN_uop[(i * 101) + 4-:4];
				end
				else if (!IN_stall[i] || ((OUT_uop[i * 199] && IN_invalidate) && ($signed(OUT_uop[(i * 199) + 52-:7] - IN_invalidateSqN) > 0))) begin
					OUT_uop[i * 199] <= 0;
					OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 0;
				end
endmodule
