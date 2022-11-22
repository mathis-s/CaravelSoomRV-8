module MemRTL (
	clk,
	IN_nce,
	IN_nwe,
	IN_addr,
	IN_data,
	IN_wm,
	OUT_data,
	IN_nce1,
	IN_addr1,
	OUT_data1
);
	parameter WORD_SIZE = 32;
	parameter NUM_WORDS = 1024;
	input wire clk;
	input wire IN_nce;
	input wire IN_nwe;
	input wire [$clog2(NUM_WORDS) - 1:0] IN_addr;
	input wire [WORD_SIZE - 1:0] IN_data;
	input wire [(WORD_SIZE / 8) - 1:0] IN_wm;
	output reg [WORD_SIZE - 1:0] OUT_data;
	input wire IN_nce1;
	input wire [$clog2(NUM_WORDS) - 1:0] IN_addr1;
	output reg [WORD_SIZE - 1:0] OUT_data1;
	integer i;
	reg [WORD_SIZE - 1:0] mem [NUM_WORDS - 1:0];
	reg ce_reg;
	reg ce1_reg;
	reg we_reg;
	reg [$clog2(NUM_WORDS) - 1:0] addr_reg;
	reg [$clog2(NUM_WORDS) - 1:0] addr1_reg;
	reg [WORD_SIZE - 1:0] data_reg;
	reg [(WORD_SIZE / 8) - 1:0] wm_reg;
	always @(posedge clk) begin
		ce_reg <= IN_nce;
		ce1_reg <= IN_nce1;
		we_reg <= IN_nwe;
		addr_reg <= IN_addr;
		addr1_reg <= IN_addr1;
		data_reg <= IN_data;
		wm_reg <= IN_wm;
		if (!ce_reg)
			if (!we_reg) begin
				for (i = 0; i < (WORD_SIZE / 8); i = i + 1)
					if (wm_reg[i])
						mem[addr_reg][8 * i+:8] = data_reg[8 * i+:8];
			end
			else
				OUT_data <= mem[addr_reg];
		if (!ce1_reg)
			OUT_data1 <= mem[addr1_reg];
	end
endmodule
