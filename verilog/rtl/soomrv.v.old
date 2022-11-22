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

module soomrv #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
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
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    //input  [127:0] la_data_in,
    output [127:0] la_data_out,
    //input  [127:0] la_oenb,
    
    // IOs
    input wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,
    inout [`MPRJ_IO_PADS-10:0] analog_io,
    
    input wire user_clock2,
    
    output wire[8:0] mem_addr,
    output wire[31:0] mem_dataOut,
    input wire[31:0] mem_dataIn,
    output wire[3:0] mem_wm,
    output wire mem_we,
    output wire mem_ce,

    output wire[8:0] instr_addr,
    input wire[63:0] instr_dataIn,
    output wire instr_ce,

    output wire[8:0] instrMgmt_addr,
    input wire[63:0] instrMgmt_dataIn,
    output wire[63:0] instrMgmt_dataOut,
    output wire instrMgmt_ce,
    output wire instrMgmt_we,
    output wire[7:0] instrMgmt_wm,

    output wire zero,

    // IRQ
    output wire [2:0] irq
);
    wire[31:0] CORE_robPCsample;
    assign la_data_out[31:0] = CORE_robPCsample;
    assign la_data_out[63:32] = {CORE_pramAddr, 3'b0};
    assign la_data_out[127:64] = 64'b0;

    assign zero = 1'b0;

    // IRQ
    assign irq = 3'b000;	// Unused

    wire[15:0] CORE_GPIO_oe;
	wire[15:0] CORE_GPIO_in = io_in[15:0];
	wire[15:0] CORE_GPIO_out;

    wire CORE_spi_clk;
    wire CORE_spi_mosi;
    wire CORE_spi_miso = io_in[26];


    assign io_oeb = {12'b100,                              CORE_GPIO_oe,  8'hff};
    assign io_out = {10'b0,   CORE_spi_mosi, CORE_spi_clk, CORE_GPIO_out, 8'h00};

    // Control Register entries
    reg coreEn;    
    reg coreRst;
    reg usingDataRAM;
    reg coreInstrMappingHalfSize;
    wire coreHlt;
    wire coreInstrMappingMiss;
    reg[31:0] coreInstrMapping;

    // Multiplexing for Data SRAM
    wire[29:0] CORE_sramAddr;
    wire[31:0] CORE_sramData;
    wire[3:0] CORE_sramWM;
    wire CORE_sramWE;
    wire CORE_sramCE;

    reg[29:0] MGMT_sramAddr;
    reg[31:0] MGMT_sramData;
    reg[3:0] MGMT_sramWM;
    reg MGMT_sramWE;
    reg MGMT_sramCE;

    assign mem_addr = !usingDataRAM ? CORE_sramAddr[8:0] : MGMT_sramAddr[8:0];
    assign mem_dataOut = !usingDataRAM ? CORE_sramData : MGMT_sramData;
    assign mem_wm = !usingDataRAM ? CORE_sramWM : MGMT_sramWM;
    assign mem_we = !usingDataRAM ? CORE_sramWE : MGMT_sramWE;
    assign mem_ce = !usingDataRAM ? CORE_sramCE : MGMT_sramCE;

    // Multiplexing for Program SRAM
    wire[28:0] CORE_pramAddr;
    wire CORE_pramCE;

    reg[28:0] MGMT_pramAddr;
    reg[63:0] MGMT_pramData;
    reg[7:0] MGMT_pramWM;
    reg MGMT_pramWE;
    reg MGMT_pramCE;

    assign instr_addr = CORE_pramAddr[8:0];
    assign instr_ce = CORE_pramCE;

    assign instrMgmt_addr = MGMT_pramAddr[8:0];
    assign instrMgmt_dataOut = MGMT_pramData;
    assign instrMgmt_wm = MGMT_pramWM;
    assign instrMgmt_ce = MGMT_pramCE;
    assign instrMgmt_we = MGMT_pramWE;

    // Wishbone State
    reg sramRead;
    reg pramRead;
    reg pramReadUpper;
    reg readCnt;

    // SRAM macros output on falling,
    // sample on rising for clean signal
    reg[63:0] instr_dataInSample;
    reg[63:0] instrMgmt_dataInSample;
    reg[31:0] mem_dataInSample;
    reg instr_ceSample;
    reg instrMgmt_ceSample;
    reg mem_ceSample;
    reg instrMgmt_weSample;
    reg mem_weSample;
    
    always@(posedge wb_clk_i) begin

        if (!instr_ceSample)
            instr_dataInSample <= instr_dataIn;

        if (!instrMgmt_ceSample && instrMgmt_weSample)
            instrMgmt_dataInSample <= instrMgmt_dataIn;

        if (!mem_ceSample && mem_weSample)
            mem_dataInSample <= mem_dataIn;

        instr_ceSample <= instr_ce;
        instrMgmt_ceSample <= instrMgmt_ce;
        mem_ceSample <= mem_ce;
        instrMgmt_weSample <= instrMgmt_we;
        mem_weSample <= mem_we;
    end



    always@(posedge wb_clk_i) begin

        // defaults
        wbs_ack_o <= 0;
        MGMT_sramCE <= 1;
        MGMT_pramCE <= 1;

        wbs_dat_o <= 0;

        if (coreHlt) begin
            coreEn <= 0;
        end

        if (wb_rst_i) begin
            coreEn <= 0;
            coreRst <= 1;
            sramRead <= 0;
            pramRead <= 0;
            coreInstrMappingHalfSize <= 0;
            coreInstrMapping <= 0;
        end
        else if (sramRead) begin
            if (readCnt)
                readCnt <= 0;
            else begin
                wbs_dat_o <= mem_dataInSample;
                wbs_ack_o <= 1;
                sramRead <= 0;
            end
        end
        else if (pramRead) begin
            if (readCnt)
                readCnt <= 0;
            else begin
                wbs_dat_o <= pramReadUpper ? instrMgmt_dataInSample[63:32] : instrMgmt_dataInSample[31:0];
                wbs_ack_o <= 1;
                pramRead <= 0;
            end
        end
        // User Area Base is 0x 30 00 00 0
        else if (wbs_cyc_i && wbs_stb_i && !wbs_ack_o) begin
            
            // Wisbone always needs ack as there's no error line
            wbs_ack_o <= 1;

            // Control Register
            if (wbs_adr_i[19:16] == 4'h0) begin
                if (wbs_adr_i[0] == 1'b0) begin
                    if (wbs_we_i && wbs_sel_i[0]) begin
                        coreEn <= wbs_dat_i[0];
                        coreRst <= wbs_dat_i[1];
                        usingDataRAM <= wbs_dat_i[2];
                        coreInstrMappingHalfSize <= wbs_dat_i[3];
                    end
                    else if (wbs_sel_i[0]) begin
                        wbs_dat_o[0] <= coreEn;
                        wbs_dat_o[1] <= coreRst;
                        wbs_dat_o[2] <= usingDataRAM;
                        wbs_dat_o[3] <= coreInstrMappingHalfSize;
                        wbs_dat_o[4] <= coreInstrMappingMiss;
                        wbs_dat_o[5] <= coreHlt;
                        wbs_dat_o[31:4] <= 0;
                    end
                end
                else begin
                    if (wbs_we_i) begin
                        if (wbs_sel_i[0]) coreInstrMapping[7:0] <= wbs_dat_i[7:0];
                        if (wbs_sel_i[1]) coreInstrMapping[15:8] <= wbs_dat_i[15:8];
                        if (wbs_sel_i[2]) coreInstrMapping[23:16] <= wbs_dat_i[23:16];
                        if (wbs_sel_i[3]) coreInstrMapping[31:24] <= wbs_dat_i[31:24];
                    end
                    else begin
                        wbs_dat_o <= coreInstrMapping;
                    end
                end
            end
            
            // Data SRAM access
            else if (usingDataRAM && wbs_adr_i[19:16] == 4'h1) begin
                if (wbs_we_i) begin
                    MGMT_sramAddr <= {8'b0, wbs_adr_i[23:2]};
                    MGMT_sramCE <= 0;
                    MGMT_sramWE <= 0;
                    MGMT_sramWM <= wbs_sel_i;
                    MGMT_sramData <= wbs_dat_i;
                end

                else begin
                    MGMT_sramAddr <= {8'b0, wbs_adr_i[23:2]};
                    MGMT_sramCE <= 0;
                    MGMT_sramWE <= 1;
                    sramRead <= 1;
                    readCnt <= 1;
                    // We need a few cycles for lookup, don't ack yet
                    wbs_ack_o <= 0;
                end
            end

            // Program SRAM access
            else if (wbs_adr_i[19:16] == 4'h2) begin
                if (wbs_we_i) begin
                    MGMT_pramAddr <= {9'b0, wbs_adr_i[23:3]};
                    MGMT_pramCE <= 0;
                    MGMT_pramWE <= 0;

                    if (wbs_adr_i[2])
                        MGMT_pramWM <= {wbs_sel_i, 4'b0};
                    else
                        MGMT_pramWM <= {4'b0, wbs_sel_i};

                    MGMT_pramData[31:0] <= wbs_dat_i;
                    MGMT_pramData[63:32] <= wbs_dat_i;
                end

                else begin
                    MGMT_pramAddr <= {9'b0, wbs_adr_i[23:3]};
                    MGMT_pramCE <= 0;
                    MGMT_pramWE <= 1;
                    pramRead <= 1;
                    pramReadUpper <= wbs_adr_i[3];
                    readCnt <= 1;
                    // We need a few cycles for lookup, don't ack yet
                    wbs_ack_o <= 0;
                end
            end
        end
    end

    Core core
    (
        .clk(wb_clk_i),
        .en(coreEn),
        .rst(coreRst),

        .IN_instrRaw(instr_dataInSample),
        .IN_MEM_readData(mem_dataInSample),
        .OUT_MEM_addr(CORE_sramAddr),
        .OUT_MEM_writeData(CORE_sramData),
        .OUT_MEM_writeEnable(CORE_sramWE),
        .OUT_MEM_readEnable(CORE_sramCE),
        .OUT_MEM_writeMask(CORE_sramWM),
        .OUT_instrAddr(CORE_pramAddr),
        .OUT_instrReadEnable(CORE_pramCE),
        .OUT_halt(coreHlt),

        .OUT_GPIO_oe(CORE_GPIO_oe),
        .OUT_GPIO(CORE_GPIO_out),
        .IN_GPIO(CORE_GPIO_in),

        .OUT_SPI_clk(CORE_spi_clk),
        .OUT_SPI_mosi(CORE_spi_mosi),
        .IN_SPI_miso(CORE_spi_miso),

        .OUT_instrMappingMiss(coreInstrMappingMiss),
        .IN_instrMappingBase(coreInstrMapping),
        .IN_instrMappingHalfSize(coreInstrMappingHalfSize),
        .OUT_LA_robPCsample(CORE_robPCsample)

    );

endmodule
`default_nettype wire
