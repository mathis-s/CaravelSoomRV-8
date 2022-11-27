module Multiply (
	clk,
	rst,
	en,
	OUT_busy,
	IN_branch,
	IN_uop,
	OUT_uop
);
	parameter NUM_STAGES = 4;
	parameter BITS = 32 / NUM_STAGES;
	input wire clk;
	input wire rst;
	input wire en;
	output wire OUT_busy;
	input wire [75:0] IN_branch;
	input wire [198:0] IN_uop;
	output reg [87:0] OUT_uop;
	integer i;
	reg [181:0] pl [NUM_STAGES:0];
	assign OUT_busy = 0;
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < (NUM_STAGES + 1); i = i + 1)
				pl[i][0] <= 0;
			OUT_uop[0] <= 0;
		end
		else begin
			if ((en && IN_uop[0]) && (!IN_branch[0] || ($signed(IN_uop[52-:7] - IN_branch[43-:7]) <= 0))) begin
				pl[0][0] <= 1;
				pl[0][51-:7] <= IN_uop[64-:7];
				pl[0][44-:5] <= IN_uop[57-:5];
				pl[0][39-:7] <= IN_uop[52-:7];
				pl[0][32-:32] <= IN_uop[134-:32];
				pl[0][117-:64] <= 0;
				case (IN_uop[70-:6])
					6'd1: begin
						pl[0][53] <= IN_uop[198] ^ IN_uop[166];
						pl[0][181-:32] <= (IN_uop[198] ? -IN_uop[198-:32] : IN_uop[198-:32]);
						pl[0][149-:32] <= (IN_uop[166] ? -IN_uop[166-:32] : IN_uop[166-:32]);
					end
					6'd2: begin
						pl[0][53] <= IN_uop[198];
						pl[0][181-:32] <= (IN_uop[198] ? -IN_uop[198-:32] : IN_uop[198-:32]);
						pl[0][149-:32] <= IN_uop[166-:32];
					end
					6'd0, 6'd3: begin
						pl[0][53] <= 0;
						pl[0][181-:32] <= IN_uop[198-:32];
						pl[0][149-:32] <= IN_uop[166-:32];
					end
					default:
						;
				endcase
				pl[0][52] <= IN_uop[70-:6] != 6'd0;
			end
			else
				pl[0][0] <= 0;
			for (i = 0; i < NUM_STAGES; i = i + 1)
				if (pl[i][0] && (!IN_branch[0] || ($signed(pl[i][39-:7] - IN_branch[43-:7]) <= 0))) begin
					pl[i + 1] <= pl[i];
					pl[i + 1][117-:64] <= pl[i][117-:64] + ((pl[i][181-:32] * pl[i][118 + (BITS * i)+:BITS]) << (BITS * i));
				end
				else
					pl[i + 1][0] <= 0;
			if (pl[NUM_STAGES][0] && (!IN_branch[0] || ($signed(pl[NUM_STAGES][39-:7] - IN_branch[43-:7]) <= 0))) begin
				OUT_uop[0] <= 1;
				OUT_uop[55-:7] <= pl[NUM_STAGES][51-:7];
				OUT_uop[48-:5] <= pl[NUM_STAGES][44-:5];
				OUT_uop[43-:7] <= pl[NUM_STAGES][39-:7];
				OUT_uop[36-:32] <= pl[NUM_STAGES][32-:32];
				OUT_uop[4-:3] <= 3'd0;
				OUT_uop[1] <= 0;
				if (pl[NUM_STAGES][52])
					OUT_uop[87-:32] <= (pl[NUM_STAGES][53] ? ~pl[NUM_STAGES][117:86] + (pl[NUM_STAGES][85:54] == 0 ? 1 : 0) : pl[NUM_STAGES][117:86]);
				else
					OUT_uop[87-:32] <= pl[NUM_STAGES][85:54];
			end
			else
				OUT_uop[0] <= 0;
		end
endmodule
