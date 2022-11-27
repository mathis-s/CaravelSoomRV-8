module StoreAGU (
	clk,
	rst,
	en,
	stall,
	IN_mode,
	IN_wmask,
	IN_branch,
	OUT_zcFwd,
	IN_uop,
	OUT_uop,
	OUT_aguOp
);
	input wire clk;
	input wire rst;
	input wire en;
	input wire stall;
	input wire [7:0] IN_mode;
	input wire [63:0] IN_wmask;
	input wire [75:0] IN_branch;
	output wire [39:0] OUT_zcFwd;
	input wire [198:0] IN_uop;
	output reg [87:0] OUT_uop;
	output reg [162:0] OUT_aguOp;
	integer i;
	wire [31:0] addrSum = IN_uop[198-:32] + {{20 {IN_uop[82]}}, IN_uop[82:71]};
	wire [31:0] addr = (IN_uop[70-:6] >= 6'd7 ? IN_uop[198-:32] : addrSum);
	reg except;
	always @(*) begin
		case (IN_uop[70-:6])
			6'd7, 6'd0: except = addr == 0;
			6'd8, 6'd1: except = (addr == 0) || addr[0];
			6'd6, 6'd9, 6'd2: except = (addr == 0) || (addr[0] || addr[1]);
			default: except = 0;
		endcase
		if ((addr[31:24] == 8'hff) && IN_mode[3'd4])
			except = 1;
		if (!IN_wmask[addr[31:26]] && IN_mode[3'd1])
			except = 1;
	end
	always @(posedge clk) begin
		OUT_uop[0] <= 0;
		if (rst)
			OUT_aguOp[0] <= 0;
		else if (((!stall && en) && IN_uop[0]) && (!IN_branch[0] || ($signed(IN_uop[52-:7] - IN_branch[43-:7]) <= 0))) begin
			OUT_aguOp[162-:32] <= addr;
			OUT_aguOp[88-:32] <= IN_uop[134-:32];
			OUT_aguOp[56-:7] <= IN_uop[64-:7];
			OUT_aguOp[49-:5] <= IN_uop[57-:5];
			OUT_aguOp[44-:7] <= IN_uop[52-:7];
			OUT_aguOp[37-:7] <= IN_uop[15-:7];
			OUT_aguOp[30-:7] <= IN_uop[8-:7];
			OUT_aguOp[23-:5] <= IN_uop[45-:5];
			OUT_aguOp[1] <= IN_uop[1];
			OUT_aguOp[18-:16] <= IN_uop[31-:16];
			OUT_aguOp[2] <= except;
			OUT_aguOp[0] <= 1;
			OUT_uop[55-:7] <= IN_uop[64-:7];
			OUT_uop[48-:5] <= IN_uop[57-:5];
			OUT_uop[43-:7] <= IN_uop[52-:7];
			OUT_uop[36-:32] <= IN_uop[134-:32];
			OUT_uop[4-:3] <= (except ? 3'd5 : 3'd0);
			OUT_uop[1] <= IN_uop[1];
			OUT_uop[87-:32] <= addrSum;
			OUT_uop[0] <= 1;
			case (IN_uop[70-:6])
				6'd0, 6'd7: begin
					OUT_aguOp[89] <= 0;
					case (addr[1:0])
						0: begin
							OUT_aguOp[98-:4] <= 4'b0001;
							OUT_aguOp[130-:32] <= IN_uop[166-:32];
						end
						1: begin
							OUT_aguOp[98-:4] <= 4'b0010;
							OUT_aguOp[130-:32] <= IN_uop[166-:32] << 8;
						end
						2: begin
							OUT_aguOp[98-:4] <= 4'b0100;
							OUT_aguOp[130-:32] <= IN_uop[166-:32] << 16;
						end
						3: begin
							OUT_aguOp[98-:4] <= 4'b1000;
							OUT_aguOp[130-:32] <= IN_uop[166-:32] << 24;
						end
					endcase
				end
				6'd1, 6'd8: begin
					OUT_aguOp[89] <= 0;
					case (addr[1])
						0: begin
							OUT_aguOp[98-:4] <= 4'b0011;
							OUT_aguOp[130-:32] <= IN_uop[166-:32];
						end
						1: begin
							OUT_aguOp[98-:4] <= 4'b1100;
							OUT_aguOp[130-:32] <= IN_uop[166-:32] << 16;
						end
					endcase
				end
				6'd2, 6'd9: begin
					OUT_aguOp[89] <= 0;
					OUT_aguOp[98-:4] <= 4'b1111;
					OUT_aguOp[130-:32] <= IN_uop[166-:32];
				end
				6'd3: begin
					OUT_aguOp[89] <= 0;
					OUT_aguOp[98-:4] <= 0;
					OUT_aguOp[100:99] <= 0;
				end
				6'd4: begin
					OUT_aguOp[89] <= 0;
					OUT_aguOp[98-:4] <= 0;
					OUT_aguOp[100:99] <= 1;
					OUT_uop[4-:3] <= 3'd7;
				end
				6'd5: begin
					OUT_aguOp[89] <= 0;
					OUT_aguOp[98-:4] <= 0;
					OUT_aguOp[100:99] <= 2;
					OUT_uop[4-:3] <= 3'd7;
				end
				default:
					;
			endcase
		end
		else if (!stall || ((OUT_aguOp[0] && IN_branch[0]) && ($signed(OUT_aguOp[44-:7] - IN_branch[43-:7]) > 0)))
			OUT_aguOp[0] <= 0;
	end
endmodule
