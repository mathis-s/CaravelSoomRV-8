module Fuse (
	clk,
	outEn,
	rst,
	mispredict,
	OUT_full,
	IN_uop,
	OUT_uop
);
	parameter NUM_UOPS_IN = 4;
	parameter NUM_UOPS_OUT = 4;
	parameter BUF_SIZE = 8;
	input wire clk;
	input wire outEn;
	input wire rst;
	input wire mispredict;
	output reg OUT_full;
	input wire [(NUM_UOPS_IN * 74) - 1:0] IN_uop;
	output reg [(NUM_UOPS_OUT * 74) - 1:0] OUT_uop;
	integer i;
	reg [(NUM_UOPS_IN * 74) - 1:0] uop;
	reg [(NUM_UOPS_IN * 74) - 1:0] fusedUOps;
	reg [(NUM_UOPS_IN * 74) - 1:0] next_uop;
	reg [73:0] fusionWindow [NUM_UOPS_IN:0];
	reg [(NUM_UOPS_IN * 74) - 1:0] bufInsertUOps;
	reg [$clog2(BUF_SIZE) - 1:0] obufIndexIn;
	reg [$clog2(BUF_SIZE) - 1:0] obufIndexOut;
	reg [$clog2(BUF_SIZE):0] freeEntries;
	reg [73:0] outBuffer [BUF_SIZE - 1:0];
	always @(*) begin : sv2v_autoblock_1
		reg lastFused;
		lastFused = 0;
		for (i = 0; i < NUM_UOPS_IN; i = i + 1)
			fusionWindow[i] = uop[i * 74+:74];
		fusionWindow[NUM_UOPS_IN] = IN_uop[0+:74];
		for (i = 0; i < NUM_UOPS_IN; i = i + 1)
			begin
				fusedUOps[i * 74+:74] = uop[i * 74+:74];
				next_uop[i * 74+:74] = IN_uop[i * 74+:74];
			end
		for (i = 0; i < NUM_UOPS_IN; i = i + 1)
			if (((((((((!lastFused && fusionWindow[i + 0][0]) && fusionWindow[i + 1][0]) && (fusionWindow[i + 0][11-:3] == 3'd0)) && ((fusionWindow[i + 0][17-:6] == 6'd16) || (fusionWindow[i + 0][17-:6] == 6'd17))) && (fusionWindow[i + 1][11-:3] == 3'd0)) && (fusionWindow[i + 1][17-:6] == 6'd0)) && fusionWindow[i + 1][24]) && (fusionWindow[i + 1][41-:5] == fusionWindow[i + 1][23-:5])) && (fusionWindow[i + 0][23-:5] == fusionWindow[i + 1][23-:5])) begin
				fusedUOps[(i + 0) * 74+:74] = fusionWindow[i + 0];
				fusedUOps[((i + 0) * 74) + 17-:6] = 6'd0;
				fusedUOps[((i + 0) * 74) + 73-:32] = {fusionWindow[i + 0][73:54], 12'b000000000000} + {{20 {fusionWindow[i + 1][53]}}, fusionWindow[i + 1][53:42]};
				if ((i + 1) < NUM_UOPS_IN)
					fusedUOps[(i + 1) * 74] = 0;
				else
					next_uop[0] = 0;
				lastFused = 1;
			end
			else if (((((((((!lastFused && fusionWindow[i + 0][0]) && fusionWindow[i + 1][0]) && (fusionWindow[i + 0][11-:3] == 3'd0)) && (fusionWindow[i + 0][17-:6] == 6'd0)) && fusionWindow[i + 0][24]) && (fusionWindow[i + 1][11-:3] == 3'd0)) && ((((((fusionWindow[i + 1][17-:6] == 6'd10) || (fusionWindow[i + 1][17-:6] == 6'd11)) || (fusionWindow[i + 1][17-:6] == 6'd12)) || (fusionWindow[i + 1][17-:6] == 6'd13)) || (fusionWindow[i + 1][17-:6] == 6'd14)) || (fusionWindow[i + 1][17-:6] == 6'd15))) && (fusionWindow[i + 0][41-:5] == fusionWindow[i + 0][23-:5])) && (fusionWindow[i + 1][41-:5] == fusionWindow[i + 0][23-:5])) begin
				fusedUOps[(i + 0) * 74+:74] = fusionWindow[i + 0];
				case (fusionWindow[i + 1][17-:6])
					default: fusedUOps[((i + 0) * 74) + 17-:6] = 6'd46;
					6'd11: fusedUOps[((i + 0) * 74) + 17-:6] = 6'd47;
					6'd12: fusedUOps[((i + 0) * 74) + 17-:6] = 6'd48;
					6'd13: fusedUOps[((i + 0) * 74) + 17-:6] = 6'd49;
					6'd14: fusedUOps[((i + 0) * 74) + 17-:6] = 6'd50;
					6'd15: fusedUOps[((i + 0) * 74) + 17-:6] = 6'd51;
				endcase
				fusedUOps[((i + 0) * 74) + 73-:32] = {fusionWindow[i + 0][53:42], 7'bxxxxxxx, fusionWindow[i + 1][54:42]};
				fusedUOps[((i + 0) * 74) + 41-:5] = fusionWindow[i + 1][41-:5];
				fusedUOps[((i + 0) * 74) + 35-:5] = fusionWindow[i + 1][35-:5];
				fusedUOps[((i + 0) * 74) + 23-:5] = fusionWindow[i + 0][23-:5];
				fusedUOps[((i + 0) * 74) + 24] = 0;
				fusedUOps[((i + 0) * 74) + 8-:5] = fusionWindow[i + 1][8-:5];
				fusedUOps[((i + 0) * 74) + 3-:2] = fusionWindow[i + 1][3-:2];
				fusedUOps[((i + 0) * 74) + 1] = fusionWindow[i + 1][1];
				if ((i + 1) < NUM_UOPS_IN)
					fusedUOps[(i + 1) * 74] = 0;
				else
					next_uop[0] = 0;
				lastFused = 1;
			end
			else
				lastFused = 0;
	end
	always @(posedge clk) begin
		if (rst) begin
			for (i = 0; i < NUM_UOPS_OUT; i = i + 1)
				OUT_uop[i * 74] <= 0;
			for (i = 0; i < NUM_UOPS_IN; i = i + 1)
				begin
					uop[i * 74] <= 0;
					bufInsertUOps[i * 74] <= 0;
				end
			obufIndexIn = 0;
			obufIndexOut = 0;
			freeEntries = BUF_SIZE;
		end
		else if (!mispredict) begin
			if (outEn)
				for (i = 0; i < NUM_UOPS_OUT; i = i + 1)
					if (obufIndexOut != obufIndexIn) begin
						OUT_uop[i * 74+:74] <= outBuffer[obufIndexOut];
						OUT_uop[i * 74] <= 1'b1;
						obufIndexOut = obufIndexOut + 1;
						freeEntries = freeEntries + 1;
					end
					else
						OUT_uop[i * 74] <= 0;
			if (!OUT_full) begin
				bufInsertUOps <= fusedUOps;
				uop <= next_uop;
				for (i = 0; i < NUM_UOPS_IN; i = i + 1)
					if (bufInsertUOps[i * 74]) begin
						outBuffer[obufIndexIn] <= bufInsertUOps[i * 74+:74];
						obufIndexIn = obufIndexIn + 1;
						freeEntries = freeEntries - 1;
					end
			end
		end
		else if (mispredict) begin
			for (i = 0; i < NUM_UOPS_OUT; i = i + 1)
				OUT_uop[i * 74] <= 0;
			for (i = 0; i < NUM_UOPS_IN; i = i + 1)
				begin
					uop[i * 74] <= 0;
					bufInsertUOps[i * 74] <= 0;
				end
			obufIndexIn = 0;
			obufIndexOut = 0;
			freeEntries = BUF_SIZE;
		end
		OUT_full <= freeEntries < 5;
	end
endmodule
