// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/
wire CORE_SPI_cs;
wire CORE_SPI_mosi;
wire CORE_SPI_miso;
wire CORE_SPI_clk;

wire EXT_oen;
wire EXT_en;
wire[31:0] EXT_busOut;
wire[31:0] EXT_busIn;

// 32x bus, clk, 4x dc, en
assign io_oeb = ~{{32{EXT_oen}}, 6'b111011};
assign io_out[0] = user_clock2;
assign io_out[1] = CORE_SPI_mosi;
assign io_out[2] = 1'b0;//CORE_SPI_miso;
assign io_out[3] = CORE_SPI_cs;
assign io_out[4] = CORE_SPI_clk;
assign io_out[5] = EXT_en;
assign io_out[37:6] = EXT_busOut;
assign EXT_busIn = io_in[37:6];

assign CORE_SPI_miso = io_in[2];

wire[127:0] CORE_instrReadData;
wire[27:0] CORE_instrReadAddr;
wire CORE_instrReadEnable;

wire[29:0] CORE_readAddr;
wire[31:0] CORE_readData;
wire CORE_readEnable;

wire CORE_writeEnable;
wire[29:0] CORE_writeAddr;
wire[31:0] CORE_writeData;
wire[3:0] CORE_writeMask;


wire CORE_halt;

reg[15:0] enWait;
reg en;
reg coreRst;
always@(posedge user_clock2) begin
    if (wb_rst_i) begin
        en <= 1;
        enWait <= 16'hFFFF;
        coreRst <= 1;
    end
    else if (enWait != 0) begin
        enWait <= enWait - 1;
        coreRst <= 1;
        en <= 1;
    end
    else begin
        coreRst <= 0;
        if (!coreRst && CORE_halt)
            en <= 0;
    end
end
Core core
(
    .clk(user_clock2),
    .rst(coreRst),
    .en(en),

    .IN_instrRaw(CORE_instrReadData),

	.OUT_MEM_writeAddr(CORE_writeAddr),
	.OUT_MEM_writeData(CORE_writeData),
	.OUT_MEM_writeEnable(CORE_writeEnable),
	.OUT_MEM_writeMask(CORE_writeMask),
	.OUT_MEM_readEnable(CORE_readEnable),
	.OUT_MEM_readAddr(CORE_readAddr),
	.IN_MEM_readData(CORE_readData),

	.OUT_instrAddr(CORE_instrReadAddr),
	.OUT_instrReadEnable(CORE_instrReadEnable),

	.OUT_halt(CORE_halt),
    
    .OUT_SPI_cs(CORE_SPI_cs),
	.OUT_SPI_clk(CORE_SPI_clk),
	.OUT_SPI_mosi(CORE_SPI_mosi),
	.IN_SPI_miso(CORE_SPI_miso),

	.OUT_MC_ce(MC_ce),
	.OUT_MC_we(MC_we),
	.OUT_MC_cacheID(MC_cacheID),
	.OUT_MC_sramAddr(MC_sramAddr),
	.OUT_MC_extAddr(MC_extAddr),
	.IN_MC_progress(MC_progress),
	.IN_MC_busy(MC_busy)
);

wire MC_ce;
wire MC_we;
wire[0:0] MC_cacheID;
wire[9:0] MC_sramAddr;
wire[29:0] MC_extAddr;
wire[9:0] MC_progress;
wire MC_busy;

wire[1:0] MC_CACHE_used;
wire[1:0] MC_CACHE_we;
wire[1:0] MC_CACHE_ce;
wire[2*4-1:0] MC_CACHE_wm;
wire[2*10-1:0] MC_CACHE_addr;
wire[2*32-1:0] MC_CACHE_wdata;
wire[2*32-1:0] MC_CACHE_rdata;

//always@(posedge user_clock2) begin
//    if (!CORE_writeEnable && CORE_writeMask == 4'b0001 && CORE_writeAddr == 30'h3F800000)
//        $write("%c", CORE_writeData[7:0]);
//end

MemoryController memc
(
    .clk(user_clock2),
    .rst(wb_rst_i),

    .IN_ce(MC_ce),
    .IN_we(MC_we),
    .IN_cacheID(MC_cacheID),
    .IN_sramAddr(MC_sramAddr),
    .IN_extAddr(MC_extAddr),
    .OUT_progress(MC_progress),
    .OUT_busy(MC_busy),

    .OUT_CACHE_used(MC_CACHE_used),
    .OUT_CACHE_we(MC_CACHE_we),
    .OUT_CACHE_ce(MC_CACHE_ce),
    .OUT_CACHE_wm(MC_CACHE_wm),
    .OUT_CACHE_addr(MC_CACHE_addr),
    .OUT_CACHE_data(MC_CACHE_wdata),
    .IN_CACHE_data(MC_CACHE_rdata),

    .OUT_EXT_oen(EXT_oen),
    .OUT_EXT_en(EXT_en),
    .OUT_EXT_bus(EXT_busOut),
    .IN_EXT_bus(EXT_busIn)  
);

SRAMWrapperDC#(1024, 32) dcache
(
    .clk(user_clock2),

    .nce0(MC_CACHE_used[0] ? MC_CACHE_ce[0] : CORE_writeEnable),
    .nwe0(MC_CACHE_used[0] ? MC_CACHE_we[0] : CORE_writeEnable),
    .addr0(MC_CACHE_used[0] ? MC_CACHE_addr[0+:10] : CORE_writeAddr[9:0]),
    .wdata0(MC_CACHE_used[0] ? MC_CACHE_wdata[0+:32] : CORE_writeData),
    .wmask0(MC_CACHE_used[0] ? MC_CACHE_wm[0+:4] : CORE_writeMask),
    .rdata0(MC_CACHE_rdata[0+:32]),

    .nce1(CORE_readEnable),
    .addr1(CORE_readAddr[9:0]),
    .rdata1(CORE_readData)
);

SRAMWrapperIC#(512, 64) icache
(
    .clk(user_clock2),

    .nce0(MC_CACHE_used[1] ? MC_CACHE_ce[1] : CORE_instrReadEnable),
    .nwe0(MC_CACHE_used[1] ? MC_CACHE_we[1] : 1'b1),
    .addr0(MC_CACHE_used[1] ? MC_CACHE_addr[11+:9] : {CORE_instrReadAddr[7:0], 1'b1}),
    .wdata0({MC_CACHE_wdata[32+:32], MC_CACHE_wdata[32+:32]}),
    .wmask0({{4{MC_CACHE_addr[10]}}, {4{~MC_CACHE_addr[10]}}}),
    .rdata0(CORE_instrReadData[127:64]),

    .nce1(CORE_instrReadEnable),
    .addr1({CORE_instrReadAddr[7:0], 1'b0}),
    .rdata1(CORE_instrReadData[63:0])
);

endmodule	// user_project_wrapper

`default_nettype wire
