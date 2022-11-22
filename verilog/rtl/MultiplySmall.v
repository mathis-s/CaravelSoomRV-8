module MultiplySmall (
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
	reg [181:0] pl;
	reg [3:0] stage;
	assign OUT_busy = pl[0] && (stage < (NUM_STAGES - 1));
	always @(posedge clk) begin
		OUT_uop[0] <= 0;
		if (rst)
			pl[0] <= 0;
		else if ((en && IN_uop[0]) && (!IN_branch[0] || ($signed(IN_uop[52-:7] - IN_branch[43-:7]) <= 0))) begin
			pl[0] <= 1;
			pl[51-:7] <= IN_uop[64-:7];
			pl[44-:5] <= IN_uop[57-:5];
			pl[39-:7] <= IN_uop[52-:7];
			pl[32-:32] <= IN_uop[134-:32];
			pl[117-:64] <= 0;
			stage <= 0;
			case (IN_uop[70-:6])
				6'd1: begin
					pl[53] <= IN_uop[198] ^ IN_uop[166];
					pl[181-:32] <= (IN_uop[198] ? -IN_uop[198-:32] : IN_uop[198-:32]);
					pl[149-:32] <= (IN_uop[166] ? -IN_uop[166-:32] : IN_uop[166-:32]);
				end
				6'd2: begin
					pl[53] <= IN_uop[198];
					pl[181-:32] <= (IN_uop[198] ? -IN_uop[198-:32] : IN_uop[198-:32]);
					pl[149-:32] <= IN_uop[166-:32];
				end
				6'd0, 6'd3: begin
					pl[53] <= 0;
					pl[181-:32] <= IN_uop[198-:32];
					pl[149-:32] <= IN_uop[166-:32];
				end
				default:
					;
			endcase
			pl[52] <= IN_uop[70-:6] != 6'd0;
		end
		else if (!IN_branch[0] || ($signed(pl[39-:7] - IN_branch[43-:7]) <= 0)) begin
			if (pl[0])
				if (stage != NUM_STAGES) begin
					pl[117-:64] <= pl[117-:64] + ((pl[181-:32] * pl[118 + (BITS * stage)+:BITS]) << (BITS * stage));
					stage <= stage + 1;
				end
				else begin
					pl[0] <= 0;
					OUT_uop[0] <= 1;
					OUT_uop[55-:7] <= pl[51-:7];
					OUT_uop[48-:5] <= pl[44-:5];
					OUT_uop[43-:7] <= pl[39-:7];
					OUT_uop[36-:32] <= pl[32-:32];
					OUT_uop[4-:3] <= 3'd0;
					OUT_uop[1] <= 0;
					if (pl[52])
						OUT_uop[87-:32] <= (pl[53] ? ~pl[117:86] + (pl[85:54] == 0 ? 1 : 0) : pl[117:86]);
					else
						OUT_uop[87-:32] <= pl[85:54];
				end
		end
		else
			pl[0] <= 0;
	end
endmodule
