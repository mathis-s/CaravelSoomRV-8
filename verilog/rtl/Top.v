module Top (
	clk,
	rst,
	en,
	OUT_halt
);
	input wire clk;
	input wire rst;
	input wire en;
	output wire OUT_halt;
	wire [1:0] MC_DC_used;
	wire [67:0] MC_DC_if [1:0];
	wire MC_ce;
	wire MC_we;
	wire [0:0] MC_cacheID;
	wire [9:0] MC_sramAddr;
	wire [29:0] MC_extAddr;
	wire [9:0] MC_progress;
	wire MC_busy;
	wire [31:0] DC_dataOut;
	wire [31:0] EXTMEM_busOut;
	wire EXTMEM_oen;
	wire [31:0] EXTMEM_bus = (EXTMEM_oen ? EXTMEM_busOut : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz);
	wire EXTMEM_en;
	MemoryController memc(
		.clk(clk),
		.rst(rst),
		.IN_ce(MC_ce),
		.IN_we(MC_we),
		.IN_cacheID(MC_cacheID),
		.IN_sramAddr(MC_sramAddr),
		.IN_extAddr(MC_extAddr),
		.OUT_progress(MC_progress),
		.OUT_busy(MC_busy),
		.OUT_CACHE_used(MC_DC_used),
		.OUT_CACHE_we({MC_DC_if[1][66], MC_DC_if[0][66]}),
		.OUT_CACHE_ce({MC_DC_if[1][67], MC_DC_if[0][67]}),
		.OUT_CACHE_wm({MC_DC_if[1][65-:4], MC_DC_if[0][65-:4]}),
		.OUT_CACHE_addr({MC_DC_if[1][41:32], MC_DC_if[0][41:32]}),
		.OUT_CACHE_data({MC_DC_if[1][31-:32], MC_DC_if[0][31-:32]}),
		.IN_CACHE_data({32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx, DC_dataOut}),
		.OUT_EXT_oen(EXTMEM_oen),
		.OUT_EXT_en(EXTMEM_en),
		.OUT_EXT_bus(EXTMEM_busOut),
		.IN_EXT_bus(EXTMEM_bus)
	);
	assign MC_DC_if[0][61:42] = 0;
	ExternalMemorySim extMem(
		.clk(clk),
		.en(EXTMEM_en && !rst),
		.bus(EXTMEM_bus)
	);
	reg [67:0] CORE_DC_if;
	wire [29:0] CORE_writeAddr;
	wire [31:0] CORE_writeData;
	wire CORE_writeEnable;
	wire [3:0] CORE_writeMask;
	always @(*) begin
		CORE_DC_if[67] = CORE_writeEnable;
		CORE_DC_if[66] = CORE_writeEnable;
		CORE_DC_if[65-:4] = CORE_writeMask;
		CORE_DC_if[61-:30] = CORE_writeAddr;
		CORE_DC_if[31-:32] = CORE_writeData;
	end
	wire CORE_readEnable;
	wire [29:0] CORE_readAddr;
	wire [31:0] CORE_readData;
	wire CORE_instrReadEnable;
	wire [27:0] CORE_instrReadAddress;
	wire [127:0] CORE_instrReadData;
	wire SPI_mosi;
	wire SPI_clk;
	Core core(
		.clk(clk),
		.rst(rst),
		.en(en),
		.IN_instrRaw(CORE_instrReadData),
		.OUT_MEM_writeAddr(CORE_writeAddr),
		.OUT_MEM_writeData(CORE_writeData),
		.OUT_MEM_writeEnable(CORE_writeEnable),
		.OUT_MEM_writeMask(CORE_writeMask),
		.OUT_MEM_readEnable(CORE_readEnable),
		.OUT_MEM_readAddr(CORE_readAddr),
		.IN_MEM_readData(CORE_readData),
		.OUT_instrAddr(CORE_instrReadAddress),
		.OUT_instrReadEnable(CORE_instrReadEnable),
		.OUT_halt(OUT_halt),
		.OUT_SPI_clk(SPI_clk),
		.OUT_SPI_mosi(SPI_mosi),
		.IN_SPI_miso(1'b0),
		.OUT_MC_ce(MC_ce),
		.OUT_MC_we(MC_we),
		.OUT_MC_cacheID(MC_cacheID),
		.OUT_MC_sramAddr(MC_sramAddr),
		.OUT_MC_extAddr(MC_extAddr),
		.IN_MC_progress(MC_progress),
		.IN_MC_busy(MC_busy)
	);
	integer spiCnt = 0;
	reg [7:0] spiByte = 0;
	always @(posedge SPI_clk) begin
		spiByte = {spiByte[6:0], SPI_mosi};
		spiCnt = spiCnt + 1;
		if (spiCnt == 8) begin
			$write("%c", spiByte);
			spiCnt = 0;
		end
	end
	wire [67:0] DC_if;
	assign DC_if = (MC_DC_used[0] ? MC_DC_if[0] : CORE_DC_if);
	MemRTL dcache(
		.clk(clk),
		.IN_nce(!(!DC_if[67] && (DC_if[61-:30] < 1024))),
		.IN_nwe(DC_if[66]),
		.IN_addr(DC_if[41:32]),
		.IN_data(DC_if[31-:32]),
		.IN_wm(DC_if[65-:4]),
		.OUT_data(DC_dataOut),
		.IN_nce1(!(!CORE_readEnable && (CORE_readAddr < 1024))),
		.IN_addr1(CORE_readAddr[9:0]),
		.OUT_data1(CORE_readData)
	);
	MemRTL #(
		.WORD_SIZE(64),
		.NUM_WORDS(512)
	) icache(
		.clk(clk),
		.IN_nce((MC_DC_used[1] ? MC_DC_if[1][67] : CORE_instrReadEnable)),
		.IN_nwe((MC_DC_used[1] ? MC_DC_if[1][66] : 1'b1)),
		.IN_addr((MC_DC_used[1] ? MC_DC_if[1][41:33] : {CORE_instrReadAddress[7:0], 1'b1})),
		.IN_data({MC_DC_if[1][31-:32], MC_DC_if[1][31-:32]}),
		.IN_wm({{4 {MC_DC_if[1][32]}}, {4 {~MC_DC_if[1][32]}}}),
		.OUT_data(CORE_instrReadData[127:64]),
		.IN_nce1(CORE_instrReadEnable),
		.IN_addr1({CORE_instrReadAddress[7:0], 1'b0}),
		.OUT_data1(CORE_instrReadData[63:0])
	);
endmodule
