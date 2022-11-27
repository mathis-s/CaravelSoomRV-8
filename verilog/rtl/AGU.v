module AGU (
	clk,
	rst,
	en,
	stall,
	IN_mode,
	IN_rmask,
	IN_branch,
	IN_uop,
	OUT_uop
);
	input wire clk;
	input wire rst;
	input wire en;
	input wire stall;
	input wire [7:0] IN_mode;
	input wire [63:0] IN_rmask;
	input wire [75:0] IN_branch;
	input wire [198:0] IN_uop;
	output reg [162:0] OUT_uop;
	integer i;
	wire [31:0] addr = IN_uop[198-:32] + (IN_uop[70-:6] >= 6'd5 ? IN_uop[166-:32] : {{20 {IN_uop[82]}}, IN_uop[82:71]});
	always @(posedge clk)
		if (rst)
			OUT_uop[0] <= 0;
		else if (((!stall && en) && IN_uop[0]) && (!IN_branch[0] || ($signed(IN_uop[52-:7] - IN_branch[43-:7]) <= 0))) begin
			OUT_uop[162-:32] <= addr;
			OUT_uop[88-:32] <= IN_uop[134-:32];
			OUT_uop[56-:7] <= IN_uop[64-:7];
			OUT_uop[49-:5] <= IN_uop[57-:5];
			OUT_uop[44-:7] <= IN_uop[52-:7];
			OUT_uop[37-:7] <= IN_uop[15-:7];
			OUT_uop[30-:7] <= IN_uop[8-:7];
			OUT_uop[23-:5] <= IN_uop[45-:5];
			OUT_uop[1] <= IN_uop[1];
			OUT_uop[18-:16] <= IN_uop[31-:16];
			OUT_uop[0] <= 1;
			case (IN_uop[70-:6])
				6'd5, 6'd8, 6'd0, 6'd3: OUT_uop[2] <= addr == 0;
				6'd6, 6'd9, 6'd1, 6'd4: OUT_uop[2] <= (addr == 0) || addr[0];
				6'd7, 6'd2: OUT_uop[2] <= (addr == 0) || (addr[0] || addr[1]);
				default:
					;
			endcase
			if ((addr[31:24] == 8'hff) && IN_mode[3'd3])
				OUT_uop[2] <= 1;
			if (!IN_rmask[addr[31:26]] && IN_mode[3'd2])
				OUT_uop[2] <= 1;
			case (IN_uop[70-:6])
				6'd5, 6'd0: begin
					OUT_uop[89] <= 1;
					OUT_uop[93-:2] <= addr[1:0];
					OUT_uop[91-:2] <= 0;
					OUT_uop[94] <= 1;
				end
				6'd6, 6'd1: begin
					OUT_uop[89] <= 1;
					OUT_uop[93-:2] <= {addr[1], 1'b0};
					OUT_uop[91-:2] <= 1;
					OUT_uop[94] <= 1;
				end
				6'd7, 6'd2: begin
					OUT_uop[89] <= 1;
					OUT_uop[93-:2] <= 2'b00;
					OUT_uop[91-:2] <= 2;
					OUT_uop[94] <= 0;
				end
				6'd8, 6'd3: begin
					OUT_uop[89] <= 1;
					OUT_uop[93-:2] <= addr[1:0];
					OUT_uop[91-:2] <= 0;
					OUT_uop[94] <= 0;
				end
				6'd9, 6'd4: begin
					OUT_uop[89] <= 1;
					OUT_uop[93-:2] <= {addr[1], 1'b0};
					OUT_uop[91-:2] <= 1;
					OUT_uop[94] <= 0;
				end
				default:
					;
			endcase
		end
		else if (!stall || ((OUT_uop[0] && IN_branch[0]) && ($signed(OUT_uop[44-:7] - IN_branch[43-:7]) > 0)))
			OUT_uop[0] <= 0;
endmodule
