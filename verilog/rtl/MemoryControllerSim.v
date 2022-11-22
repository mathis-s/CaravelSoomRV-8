module MemoryControllerSim (
	clk,
	rst,
	IN_ce,
	IN_we,
	IN_sramAddr,
	IN_extAddr,
	OUT_progress,
	OUT_busy,
	OUT_CACHE_used,
	OUT_CACHE_we,
	OUT_CACHE_ce,
	OUT_CACHE_wm,
	OUT_CACHE_addr,
	OUT_CACHE_data,
	IN_CACHE_data
);
	input wire clk;
	input wire rst;
	input wire IN_ce;
	input wire IN_we;
	input wire [9:0] IN_sramAddr;
	input wire [31:0] IN_extAddr;
	output reg [9:0] OUT_progress;
	output reg OUT_busy;
	output reg OUT_CACHE_used;
	output reg OUT_CACHE_we;
	output reg OUT_CACHE_ce;
	output wire [3:0] OUT_CACHE_wm;
	output reg [9:0] OUT_CACHE_addr;
	output reg [31:0] OUT_CACHE_data;
	input wire [31:0] IN_CACHE_data;
	localparam LEN = 16;
	reg [3:0] state;
	reg [31:0] extRAM [65535:0];
	reg [31:0] extAddr;
	reg [9:0] sramAddr;
	reg [9:0] cnt;
	assign OUT_CACHE_wm = 4'b1111;
	always @(posedge clk)
		if (rst) begin
			state <= 0;
			OUT_CACHE_used <= 0;
			OUT_CACHE_we <= 1;
			OUT_CACHE_ce <= 1;
			OUT_busy <= 0;
		end
		else
			case (state)
				0:
					if (IN_ce) begin
						if (IN_we)
							state <= 1;
						else
							state <= 2;
						extAddr <= IN_extAddr;
						sramAddr <= IN_sramAddr;
						OUT_busy <= 1;
						OUT_CACHE_used <= 1;
						cnt <= 0;
						OUT_progress <= 0;
					end
					else begin
						OUT_CACHE_used <= 0;
						OUT_CACHE_we <= 1;
						OUT_CACHE_ce <= 1;
						OUT_busy <= 0;
					end
				1: begin
					cnt <= cnt + 1;
					if (cnt == 19) begin
						OUT_CACHE_ce <= 1;
						state <= 0;
						OUT_busy <= 0;
						OUT_CACHE_used <= 0;
					end
					else begin
						if (cnt < LEN) begin
							OUT_CACHE_ce <= 0;
							OUT_CACHE_we <= 1;
							OUT_CACHE_addr <= sramAddr;
							sramAddr <= sramAddr + 1;
						end
						else
							OUT_CACHE_ce <= 1;
						if (cnt > 2) begin
							extRAM[extAddr] <= IN_CACHE_data;
							extAddr <= extAddr + 1;
							OUT_progress <= OUT_progress + 1;
						end
					end
				end
				2: begin
					cnt <= cnt + 1;
					if (cnt == LEN) begin
						OUT_CACHE_ce <= 1;
						state <= 0;
						OUT_busy <= 0;
						OUT_CACHE_used <= 0;
					end
					else begin
						OUT_CACHE_ce <= 0;
						OUT_CACHE_we <= 0;
						OUT_CACHE_addr <= sramAddr;
						OUT_CACHE_data <= extRAM[extAddr];
						sramAddr <= sramAddr + 1;
						extAddr <= extAddr + 1;
					end
				end
			endcase
endmodule
