module MemoryController (
	clk,
	rst,
	IN_ce,
	IN_we,
	IN_cacheID,
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
	IN_CACHE_data,
	OUT_EXT_oen,
	OUT_EXT_en,
	OUT_EXT_bus,
	IN_EXT_bus
);
	parameter NUM_CACHES = 2;
	input wire clk;
	input wire rst;
	input wire IN_ce;
	input wire IN_we;
	input wire [$clog2(NUM_CACHES) - 1:0] IN_cacheID;
	input wire [9:0] IN_sramAddr;
	input wire [29:0] IN_extAddr;
	output reg [9:0] OUT_progress;
	output reg OUT_busy;
	output reg [NUM_CACHES - 1:0] OUT_CACHE_used;
	output reg [NUM_CACHES - 1:0] OUT_CACHE_we;
	output reg [NUM_CACHES - 1:0] OUT_CACHE_ce;
	output reg [(NUM_CACHES * 4) - 1:0] OUT_CACHE_wm;
	output reg [(NUM_CACHES * 10) - 1:0] OUT_CACHE_addr;
	output reg [(NUM_CACHES * 32) - 1:0] OUT_CACHE_data;
	input wire [(NUM_CACHES * 32) - 1:0] IN_CACHE_data;
	output reg OUT_EXT_oen;
	output reg OUT_EXT_en;
	output reg [31:0] OUT_EXT_bus;
	input wire [31:0] IN_EXT_bus;
	integer i;
	reg [2:0] state;
	reg isExtWrite;
	reg [9:0] sramAddr;
	reg [9:0] cnt;
	reg [9:0] len;
	reg [$clog2(NUM_CACHES) - 1:0] cacheID;
	reg [2:0] waitCycles;
	wire [4:1] sv2v_tmp_FA915;
	assign sv2v_tmp_FA915 = 4'b1111;
	always @(*) OUT_CACHE_wm[0+:4] = sv2v_tmp_FA915;
	wire [4:1] sv2v_tmp_92B49;
	assign sv2v_tmp_92B49 = 4'b1111;
	always @(*) OUT_CACHE_wm[4+:4] = sv2v_tmp_92B49;
	always @(posedge clk)
		if (rst) begin
			state <= 0;
			for (i = 0; i < NUM_CACHES; i = i + 1)
				begin
					OUT_CACHE_used[i] <= 0;
					OUT_CACHE_we[i] <= 1;
					OUT_CACHE_ce[i] <= 1;
				end
			OUT_busy <= 0;
			OUT_EXT_oen <= 1;
			OUT_progress <= 0;
			len <= 0;
			OUT_EXT_bus <= 0;
			OUT_EXT_en <= 0;
		end
		else
			case (state)
				0: begin
					if (IN_ce) begin
						if (IN_we) begin
							isExtWrite <= 1;
							waitCycles <= 0;
						end
						else begin
							isExtWrite <= 0;
							waitCycles <= 5;
						end
						state <= 1;
						cacheID <= IN_cacheID;
						sramAddr <= IN_sramAddr;
						cnt <= 0;
						if (IN_cacheID == 0)
							len <= 64;
						else
							len <= 128;
						OUT_EXT_en <= 1;
						OUT_EXT_bus <= {IN_we, IN_cacheID[0], IN_extAddr[29:0]};
						OUT_EXT_oen <= 1;
						OUT_busy <= 1;
						OUT_progress <= 0;
					end
					else begin
						for (i = 0; i < NUM_CACHES; i = i + 1)
							begin
								OUT_CACHE_we[i] <= 1;
								OUT_CACHE_ce[i] <= 1;
							end
						OUT_busy <= 0;
						OUT_EXT_en <= 0;
						OUT_progress <= 0;
						OUT_EXT_bus <= 0;
					end
					OUT_EXT_oen <= 1;
					for (i = 0; i < NUM_CACHES; i = i + 1)
						OUT_CACHE_used[i] <= 0;
				end
				1: begin
					if (waitCycles == 0) begin
						if (isExtWrite)
							state <= 2;
						else begin
							state <= 3;
							OUT_EXT_oen <= 0;
						end
						OUT_CACHE_used[cacheID] <= 1;
					end
					waitCycles <= waitCycles - 1;
				end
				2: begin
					OUT_CACHE_ce[cacheID] <= !(cnt < len);
					OUT_CACHE_we[cacheID] <= 1;
					OUT_CACHE_addr[cacheID * 10+:10] <= sramAddr;
					if (cnt < len)
						sramAddr <= sramAddr + 1;
					else
						OUT_CACHE_used[cacheID] <= 0;
					cnt <= cnt + 1;
					if (cnt == (len + 3)) begin
						OUT_EXT_en <= 0;
						state <= 0;
						OUT_busy <= 0;
					end
					else if (cnt > 2)
						OUT_EXT_bus <= IN_CACHE_data[cacheID * 32+:32];
				end
				3: begin
					cnt <= cnt + 1;
					if (cnt < len) begin
						OUT_CACHE_ce[cacheID] <= 0;
						OUT_CACHE_we[cacheID] <= 0;
						OUT_CACHE_addr[cacheID * 10+:10] <= sramAddr;
						sramAddr <= sramAddr + 1;
						OUT_CACHE_data[cacheID * 32+:32] <= IN_EXT_bus;
						OUT_progress <= OUT_progress + 1;
					end
					else begin
						OUT_CACHE_ce[cacheID] <= 1;
						OUT_CACHE_we[cacheID] <= 1;
						OUT_CACHE_used[cacheID] <= 0;
						OUT_busy <= 0;
						OUT_progress <= 0;
						state <= 0;
						OUT_EXT_en <= 0;
					end
				end
			endcase
endmodule
