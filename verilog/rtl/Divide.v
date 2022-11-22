module Divide (
	clk,
	rst,
	en,
	OUT_busy,
	IN_branch,
	IN_uop,
	OUT_uop
);
	input wire clk;
	input wire rst;
	input wire en;
	output wire OUT_busy;
	input wire [75:0] IN_branch;
	input wire [198:0] IN_uop;
	output reg [87:0] OUT_uop;
	reg [198:0] uop;
	reg [5:0] cnt;
	reg [63:0] r;
	reg [31:0] q;
	reg [31:0] d;
	reg invert;
	reg running;
	assign OUT_busy = running && ((cnt != 0) && (cnt != 63));
	always @(posedge clk)
		if (rst) begin
			OUT_uop[0] <= 0;
			running <= 0;
		end
		else if ((en && IN_uop[0]) && (!IN_branch[0] || ($signed(IN_uop[52-:7] - IN_branch[43-:7]) <= 0))) begin
			running <= 1;
			uop <= IN_uop;
			cnt <= 31;
			if (IN_uop[70-:6] == 6'd0) begin
				invert <= IN_uop[198] ^ IN_uop[166];
				r <= {32'b00000000000000000000000000000000, (IN_uop[198] ? -IN_uop[198-:32] : IN_uop[198-:32])};
				d <= (IN_uop[166] ? -IN_uop[166-:32] : IN_uop[166-:32]);
			end
			else if (IN_uop[70-:6] == 6'd2) begin
				invert <= IN_uop[198];
				r <= {32'b00000000000000000000000000000000, (IN_uop[198] ? -IN_uop[198-:32] : IN_uop[198-:32])};
				d <= (IN_uop[166] ? -IN_uop[166-:32] : IN_uop[166-:32]);
			end
			else begin
				invert <= 0;
				r <= {32'b00000000000000000000000000000000, IN_uop[198-:32]};
				d <= IN_uop[166-:32];
			end
			OUT_uop[0] <= 0;
		end
		else if (running) begin
			if (IN_branch[0] && ($signed(IN_branch[43-:7] - uop[52-:7]) < 0)) begin
				running <= 0;
				uop[0] <= 0;
				OUT_uop[0] <= 0;
			end
			else if (cnt != 63) begin
				if (!r[63]) begin
					q[cnt[4:0]] <= 1;
					r <= (2 * r) - {d, 32'b00000000000000000000000000000000};
				end
				else begin
					q[cnt[4:0]] <= 0;
					r <= (2 * r) + {d, 32'b00000000000000000000000000000000};
				end
				cnt <= cnt - 1;
				OUT_uop[0] <= 0;
			end
			else begin : sv2v_autoblock_1
				reg [31:0] qRestored;
				reg [31:0] remainder;
				qRestored = (q - ~q) - (r[63] ? 1 : 0);
				remainder = (r[63] ? r[63:32] + d : r[63:32]);
				running <= 0;
				OUT_uop[43-:7] <= uop[52-:7];
				OUT_uop[55-:7] <= uop[64-:7];
				OUT_uop[48-:5] <= uop[57-:5];
				OUT_uop[36-:32] <= uop[134-:32];
				OUT_uop[1] <= 0;
				OUT_uop[4-:3] <= 3'd0;
				OUT_uop[0] <= 1;
				if ((uop[70-:6] == 6'd2) || (uop[70-:6] == 6'd3))
					OUT_uop[87-:32] <= (invert ? -remainder : remainder);
				else
					OUT_uop[87-:32] <= (invert ? -qRestored : qRestored);
			end
		end
		else begin
			OUT_uop[0] <= 0;
			running <= 0;
		end
endmodule
